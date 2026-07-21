---
description: "Full UE + Perforce pipeline — P4 sync, build gate, Editor build, binary reconcile, editor verification, tech review, submit. User-invoked: run it when you are ready to sync and submit updated binaries after a Perforce sync."
disable-model-invocation: true
---

# Sync, Build, and Submit Binaries

Execute the full workflow to sync from Perforce, build the Editor, and submit updated binaries.

> **User-invoked only.** This command starts an Editor build and Perforce operations, so the
> agent never runs it on its own — you invoke it explicitly when you want to sync + submit.

## Setup — fill these placeholders for your project

This command is generic across UE source-tree + Perforce projects. Replace the tokens below
with your project's values (your install/setup can pre-fill them):

| Token | Meaning | Example |
|---|---|---|
| `<DEPOT_ROOT>` | Perforce depot path root | `//YourDepot/main` |
| `<PROJECT_ROOT>` | local workspace root (absolute) | `c:/path/to/project` |
| `<GAME_DIR>` | subdir holding the `.uproject` + `Binaries/` | `MyGame` |
| `<UPROJECT>` | `.uproject` path relative to root | `MyGame/MyGame.uproject` |
| `<EDITOR_TARGET>` | UE editor build target | `MyGameEditor` |

## Workflow Steps

Follow these steps in order. Stop and report to the user if any step fails.

### 1. Sync Latest from Perforce

```
p4 sync <DEPOT_ROOT>/...
```

Report how many files were updated/added/deleted.

### 1b. Build Gate — Skip Build if No Source Changed

After the sync, decide whether a build is needed by classifying changed files.

**Skip build** only when ALL of the following are true:
- Sync output is `file(s) up-to-date` (nothing changed), OR every synced file's extension is in the **known content allowlist** below
- No new `.uplugin` file or new directory under `<GAME_DIR>/Plugins/` or `Engine/Plugins/` appears in the sync output

**Known content allowlist** (safe to skip build):
`.uasset`, `.umap`, `.png`, `.jpg`, `.jpeg`, `.wav`, `.mp3`, `.udn`, `.md`, `.txt`, `.json`

> `.ini` is NOT on this list. Config files can affect plugin and module enablement; never assume they are content-only.

**Build required** if any synced file matches:
- C++ source: `.cpp`, `.h`, `.inl`
- Build scripts: `.cs` (includes `.Build.cs`, `.Target.cs`)
- Plugin descriptors: `.uplugin`
- Scripting plugins (e.g. AngelScript): `.as`
- Project descriptor: `.uproject`
- Config: `.ini`
- Shader source: `.usf`, `.ush`
- **Any extension NOT in the content allowlist** — unknown types default to building (fail-safe)
- **Any newly added `.uplugin` or new directory under `<GAME_DIR>/Plugins/` or `Engine/Plugins/`** — forces build so that Step 2b (plugin dependency check) still runs

If skip criteria are met, print:

> "Sync brought only content changes (no source/script/plugin files). Skipping build — going straight to reconcile."

Then jump directly to Step 3. Otherwise proceed to Step 2.

### 2. Build the Editor

```
Engine/Build/BatchFiles/Build.bat <EDITOR_TARGET> Win64 Development -Project="<PROJECT_ROOT>/<UPROJECT>" -WaitMutex
```

**IMPORTANT**: The `-Project` path MUST be an absolute path or UBT will fail.

Run this in the background. Wait for completion. If the build fails, show the last 50 lines of output and stop.

### 2b. Plugin Dependency Check

After a successful build, check if any **new plugins** were added during sync. For each new plugin:

1. Read its `.uplugin` file and `.Build.cs` to identify dependencies
2. Verify all dependency modules/plugins are available in the engine or project
3. Check if the plugin is listed in `<UPROJECT>` — if not, warn the user per the plugin checklist (even if `"Installed": true` provides auto-discovery)
4. Report the dependency summary to the user before proceeding

**How to detect new plugins**: Look at the P4 sync output for newly added `.uplugin` files or new directories under `<GAME_DIR>/Plugins/`.

### 2c. Revert BuildId-Only Manifest Churn (post-build, before reconcile)

**Run after every successful build, before Step 3.** Skip only if Step 1b skipped the build. This reverts cosmetic engine-wide BuildId churn so the reconcile in Steps 3/3b shows only genuinely-changed binaries.

**Why (root cause):** when a build relinks any **engine** module — which can happen even when the module's source is byte-identical to the depot, because a dependency's **mtime** was touched (UBT keys staleness on mtime; e.g. a touched-but-unchanged versioned engine-plugin source file) — UBT's `WriteMetadataMode.CanRecycleBuildId` returns false (it checks only manifests under the Engine directory, and an engine DLL is now newer than its manifest). UBT then mints a fresh BuildId GUID and stamps it into **all** `.modules` files plus `.target` and `.version` (often ~200+). Those files now differ from depot **only** by the `"BuildId"` value. The depot holds one stable BuildId; submitting the churn would change it for the whole team and bloat the CL ~100×. Game-module-only builds never trigger this (CanRecycleBuildId ignores non-engine manifests) — which is why most build CLs are a single DLL.

**Detect and revert** (safe — only touches files whose *sole* diff from depot is the BuildId value):

```bash
cd <PROJECT_ROOT>
p4 reconcile -n \
  "<DEPOT_ROOT>/<GAME_DIR>/Binaries/Win64/*.modules" \
  "<DEPOT_ROOT>/<GAME_DIR>/Binaries/Win64/*.target" \
  "<DEPOT_ROOT>/<GAME_DIR>/Binaries/Win64/*.version" \
  "<DEPOT_ROOT>/<GAME_DIR>/Plugins/.../Binaries/Win64/*.modules" \
  "<DEPOT_ROOT>/Engine/Binaries/Win64/*.modules" \
  "<DEPOT_ROOT>/Engine/Binaries/Win64/*.target" \
  "<DEPOT_ROOT>/Engine/Binaries/Win64/*.version" \
  "<DEPOT_ROOT>/Engine/Plugins/.../Binaries/Win64/*.modules" 2>/dev/null \
  | grep -oE '<DEPOT_ROOT>/[^#]+' > /tmp/manifest_candidates.txt

norm() { tr -d '\r' | sed -E 's/"BuildId": *"[^"]*"/"BuildId":"_"/'; }
> /tmp/churn.txt; > /tmp/real_manifests.txt
while read -r dep; do
  [ -z "$dep" ] && continue
  loc="${dep/<DEPOT_ROOT>\//<PROJECT_ROOT>/}"
  [ -f "$loc" ] || continue
  if diff -q <(p4 print -q "$dep" 2>/dev/null | norm) <(norm < "$loc") >/dev/null 2>&1; then
    echo "$dep" >> /tmp/churn.txt          # differs ONLY by BuildId -> churn
  else
    echo "$dep" >> /tmp/real_manifests.txt  # Modules map changed -> real, keep
  fi
done < /tmp/manifest_candidates.txt

echo "BuildId-only churn to revert: $(wc -l < /tmp/churn.txt)"
echo "Manifests with REAL changes (review, do NOT auto-revert): $(wc -l < /tmp/real_manifests.txt)"; cat /tmp/real_manifests.txt
[ -s /tmp/churn.txt ] && xargs -a /tmp/churn.txt p4 sync -f
```

Reverting the churn (a) keeps the depot's stable BuildId and (b) makes Step 5's editor launch verify the *true* delivered state (depot manifests + only the real new DLLs).

- **`real_manifests.txt`** — a manifest whose `Modules` map genuinely changed (a module added / removed / renamed). **Do not auto-revert.** Leave it for Step 3/3b to handle. A common case: an engine manifest still lists modules for a now-disabled plugin — that intersects the Step 3b disabled-plugin / delete HARD-STOP rule; resolve it there, do not blindly submit the removal.

**Split-BuildId check (run after the revert — and standalone any time the editor won't launch):** the revert must land on *every* manifest or none. A **partial** revert is worse than no revert: the editor compares each `.modules` BuildId against its own, ignores any manifest that disagrees, and then reports every module that manifest declares as missing —

> Plugin 'DerivedDataBuildController' failed to load because module 'DerivedDataBuildController' could not be found.

The named plugin is a red herring: it is simply the first `LoadingPhase: EarliestPossible` plugin in the drifted set, so it aborts startup before the rest of the drifted set can complain. The DLL is on disk and fine. This also fires when someone builds **outside** this command and hand-swaps only the engine/game manifests — Step 2c never ran, so nothing reconciled the plugin ones.

```bash
cd <PROJECT_ROOT>
find Engine <GAME_DIR> -path "*Binaries*" -name "*.modules" -print0 2>/dev/null \
  | xargs -0 grep -ho '"BuildId": *"[^"]*"' | sort | uniq -c | sort -rn
```

Expect **one** dominant BuildId across all `UnrealEditor.modules`. `UnrealPak.modules` (~8, incl. the per-platform copies under `Engine/Binaries/Win64/<Platform>/`) and `ShaderCompileWorker.modules` carry their own BuildIds — separate targets, not drift. If a minority id shows up on `UnrealEditor.modules` files, they are the drifted set: `p4 sync -f` them back (they should be byte-identical to depot afterwards, so **no `p4 edit`, nothing to submit** — this is local-state repair, not a change). If depot is not the authority (e.g. a manifest is a truncated subset of depot's `Modules` map because the local build omitted Editor/UncookedOnly modules whose DLLs *are* on disk), `p4 sync -f` is still correct — the depot map matches the DLLs present.

**Incidental engine-DLL check (after the manifest revert):** if Step 3b still flags an **engine** `.dll`:
- `p4 diff -se <DEPOT_ROOT>/Engine/Plugins/<Plugin>/Source/...` — if versioned plugin source changed, the DLL is **real**: submit it.
- If the plugin's source is content-identical to depot (verify with `cmp`/`p4 diff` against depot, not just `p4 diff -se` — a mere mtime touch on an unchanged file can force the relink), the relink is incidental: `p4 sync -f` the DLL back. **Caveat:** a core-engine-header change can legitimately force a plugin rebuild with no local plugin-source delta — if unsure, keep the DLL and let the Step 7 reviewer adjudicate rather than auto-reverting.

### 3. Reconcile Binaries

**This step always runs — even if the build was skipped in Step 1b.** A prior build may have produced binaries that were never submitted.

Watch for `also opened by` warnings in the reconcile output — report them to the user before proceeding.

Run `p4 reconcile` (with `-n` preview first) on these locations to find changed files:
- `<GAME_DIR>/Binaries/Win64/*.dll`
- `<GAME_DIR>/Binaries/Win64/*.modules`
- `<GAME_DIR>/Plugins/*/Binaries/Win64/*.dll`
- `<GAME_DIR>/Plugins/*/Binaries/Win64/*.modules`

**Skip .pdb files** — they are large debug symbols not needed by the team.

Only reconcile files that actually changed (the `-n` preview will show this).

### 3b. Engine Binary Dependency Check

After reconciling project binaries, check for engine-level binaries that may have changed as a result of the build (e.g. new plugins pulling in engine plugin or core DLLs).

Run `p4 reconcile -n` (preview only) on:
- `Engine/Binaries/Win64/*.dll`
- `Engine/Binaries/Win64/*.modules`
- `Engine/Plugins/.../Binaries/Win64/*.dll`
- `Engine/Plugins/.../Binaries/Win64/*.modules`

**Skip .pdb files.**

**Before parsing the preview, exclude disabled plugins:**

1. Read `<UPROJECT>` and find all plugins with `"Enabled": false`.
2. For each disabled plugin, remove any matching entries from the reconcile preview output. These binaries are compiled by UBT despite the plugin being disabled, and must NOT be re-added to the depot (they were intentionally deleted in a previous CL).
3. After filtering, delete the local compiled binaries for disabled plugins from disk (`rm -rf Engine/Plugins/.../PluginName/Binaries/`) to prevent future reconcile from picking them up.

> **Why**: UBT compiles engine plugins that exist in source even when `Enabled: false` in .uproject. P4IGNORE does not block reconcile for previously-deleted depot files. The only reliable prevention is to delete the local binaries before reconcile runs.

Parse the filtered preview output into two categories before taking any action:

**Adds/edits** (reconcile add or edit):
- Include in the CL
- Note count and plugin groups in the CL description (e.g. "12 engine binaries added: MassGameplay, LiveLink, USD")
- If nothing found, continue silently

**Deletes** (reconcile delete) — HARD STOP rule:

For each engine plugin binary the reconcile wants to delete, check `<UPROJECT>`:

- **Plugin has `"Enabled": false` in .uproject** → delete is intentional (build correctly skipped it). Include in CL, note in description as "removed binaries for explicitly disabled plugin: [name]".
- **Plugin is NOT listed with `"Enabled": false`** → **BLOCKING. Do not proceed.** Report to the user:

  > "Reconcile wants to delete engine plugin binaries that are not explicitly disabled in .uproject: [list of DLLs]. Submitting these deletes will break team members who depend on them. Possible causes: the build skipped this plugin, or it was never rebuilt after a config change. Either add `\"Enabled\": false` to .uproject if the plugin is intentionally unused, or investigate why the build didn't produce these DLLs."

  Do not add these files to the CL. Wait for user decision before continuing.

> **Why this rule exists**: a reconcile run on a machine that hadn't built a given plugin can delete that plugin's binaries from the depot. If the plugin is not disabled in `.uproject`, the engine tries to load it on sync and fails for the whole team. An explicit `Enabled: false` entry in `.uproject` is the source of truth for "this plugin is intentionally absent."

### 4. Create Named Changelist

**IMPORTANT**: Create the CL via Bash heredoc — do NOT use a PowerShell pipe to `p4 change -i`. PowerShell prepends a UTF-8 BOM that corrupts the input and fails with a line-1 syntax error.

```bash
p4 change -i << 'EOF'
Change: new
Description:
	[build] Update project binaries after P4 sync

Files:

EOF
```

If engine dependency binaries were found in Step 3b, use this description instead:
```
[build] Update project binaries after P4 sync — includes engine plugin dependencies: <list plugin groups>
```

Move all reconciled binary files (project + engine dependencies) into this CL with `p4 reopen -c <CL>`.

Run `p4 describe -s <CL>` to confirm contents and present to the user.

### 5. Verify — Launch Editor

Launch the Unreal Editor:
```
Engine/Binaries/Win64/UnrealEditor.exe "<PROJECT_ROOT>/<UPROJECT>" -log
```

Run in background. Wait ~60 seconds for startup, then check:
- The UE log under `<GAME_DIR>/Saved/Logs/` for real errors
- Ignore standard noise: PIX plugin, missing iOS/Mac/TVOS/Android platforms, USB errors
- Look for: compilation errors, module load failures for project/plugin modules, map check errors

Report findings to the user. If there are real errors, **stop and do not submit**.

### 5b. Fix-and-Rebuild Cycle

If Step 5 reveals errors that require a code fix (e.g. binding conflicts, compilation errors):

1. Close the editor (Step 6)
2. Apply the fix — checkout affected files, make changes, create a separate CL for the fix
3. **Rebuild** (repeat Step 2)
4. **Revert and re-reconcile ALL binaries** — repeat Steps 2c, 3 and 3b from scratch against the new build output. The previous reconcile is stale and must be discarded. (Step 2c must re-run because the rebuild mints a fresh BuildId and re-churns every manifest.)
5. **Re-verify** — repeat Step 5 with a fresh editor launch
6. Only proceed to submission once verification passes cleanly

**CRITICAL**: Do not skip the re-reconcile of engine binary dependencies (Step 3b) after a rebuild. A code fix may change which engine modules are linked or loaded, producing engine-level binary changes that were not present after the first build.

### 6. Close the Editor

Once the editor log check passes with no real errors, close the Unreal Editor immediately:
```
taskkill //IM UnrealEditor.exe //F
```

**IMPORTANT**: Use `//` for flags (not `/`) because the shell is bash, not cmd.exe. Do NOT wrap this in `cmd.exe /c` — it swallows errors silently.

After running taskkill, **verify** the editor is actually closed:
```
tasklist 2>/dev/null | grep -i "UnrealEditor" || echo "Editor closed successfully"
```

If the process is still running, retry with `taskkill //PID <pid> //F`. Do NOT proceed until the editor is confirmed closed.

### 7. Tech Review

Launch the `architecture-reviewer` agent to review the changelist. Provide:
- The CL number and description
- The list of files being submitted (from `p4 describe -s <CL>`)
- Any relevant context from the sync (what changed, which plugins rebuilt)

**Submission ownership rule (HARD)**: the reviewer agent **must not** run `p4 submit`. Its job is to return a verdict — nothing more. The main session is the only actor permitted to submit. State this constraint explicitly in the agent prompt. (The `architecture-reviewer` agent itself also enforces this; see its "Submission Authority" rule.)

**Required reviewer output format**: the agent's response must contain a top-level `Verdict:` line with one of:
- `Verdict: GREEN` — no issues, or INFO-only notes
- `Verdict: WARNING` — non-blocking concerns the user should see
- `Verdict: BLOCKING` — must not submit

If the reviewer returns prose without a `Verdict:` line, treat it as ambiguous and present the findings to the user before deciding.

**Always print the full reviewer summary to the user before Step 8**, even on GREEN. The user must see what was reviewed.

### 8. Submit

**Default (supervised): always present the review verdict and ASK the user before submitting — including on GREEN.** Do NOT auto-submit. The flow is:

- `GREEN`: present the summary, then ask "Submit CL `<CL>`? [y/N]". Submit only on explicit approval.
- `WARNING`: present findings, ask whether to submit. Do not submit until the user confirms.
- `BLOCKING`: stop. Present findings. Wait for the user.

> [!NOTE]
> This command always asks before submitting — there is no autonomous auto-submit path.

Once approved, run from the main session:

```
p4 submit -c <CL>
```

Verify submission with `p4 changes -m 1 -s submitted` and report the final CL number and head revision of each affected file.

## Notes

- If binaries haven't changed (nothing to reconcile), report that and skip CL creation.
- This workflow follows the project's changelist-verification rules (see the perforce overlay's `ChangelistVerification.md` / `ReviewAndSubmit.md`).
