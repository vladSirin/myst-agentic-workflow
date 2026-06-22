# Sync, Build, and Submit Binaries

Execute the full workflow to sync from Perforce, build the Editor, and submit updated binaries.

## Workflow Steps

Follow these steps in order. Stop and report to the user if any step fails.

### 1. Sync Latest from Perforce

```
p4 sync //UEPrototype/main/...
```

Report how many files were updated/added/deleted.

### 2. Build the Editor

```
Engine/Build/BatchFiles/Build.bat UE_Blank_ProtoEditor Win64 Development -Project="c:/_LocalDev/UE_Blank_Proto/Myst_Proto/UE_Blank_Proto.uproject" -WaitMutex
```

**IMPORTANT**: The `-Project` path MUST be an absolute path or UBT will fail.

Run this in the background. Wait for completion. If the build fails, show the last 50 lines of output and stop.

### 2b. Plugin Dependency Check

After a successful build, check if any **new plugins** were added during sync. For each new plugin:

1. Read its `.uplugin` file and `.Build.cs` to identify dependencies
2. Verify all dependency modules/plugins are available in the engine or project
3. Check if the plugin is listed in `Myst_Proto/UE_Blank_Proto.uproject` — if not, warn the user per the plugin checklist (even if `"Installed": true` provides auto-discovery)
4. Report the dependency summary to the user before proceeding

**How to detect new plugins**: Look at the P4 sync output for newly added `.uplugin` files or new directories under `Myst_Proto/Plugins/`.

### 3. Reconcile Binaries

Run `p4 reconcile` (with `-n` preview first) on these locations to find changed files:
- `Myst_Proto/Binaries/Win64/*.dll`
- `Myst_Proto/Binaries/Win64/*.modules`
- `Myst_Proto/Plugins/*/Binaries/Win64/*.dll`
- `Myst_Proto/Plugins/*/Binaries/Win64/*.modules`

**Skip .pdb files** — they are large debug symbols not needed by the team.

Only reconcile files that actually changed (the `-n` preview will show this).

### 3b. Engine Binary Dependency Check

After reconciling project binaries, check for engine-level binaries that may have changed as a result of the build (e.g. new plugins pulling in engine plugin or core DLLs).

Run `p4 reconcile -n` (preview only) on:
- `Engine/Binaries/Win64/*.dll`
- `Engine/Binaries/Win64/*.modules`
- `Engine/Plugins/Runtime/.../Binaries/Win64/*.dll`
- `Engine/Plugins/Runtime/.../Binaries/Win64/*.modules`
- `Engine/Plugins/Animation/.../Binaries/Win64/*.dll`
- `Engine/Plugins/Animation/.../Binaries/Win64/*.modules`
- `Engine/Plugins/Developer/.../Binaries/Win64/*.dll`
- `Engine/Plugins/Developer/.../Binaries/Win64/*.modules`
- `Engine/Plugins/Experimental/.../Binaries/Win64/*.dll`
- `Engine/Plugins/Experimental/.../Binaries/Win64/*.modules`
- `Engine/Plugins/Interchange/.../Binaries/Win64/*.dll`
- `Engine/Plugins/Interchange/.../Binaries/Win64/*.modules`

**Skip .pdb files.**

Parse the preview output into two categories before taking any action:

**Adds/edits** (reconcile add or edit):

- Include in the CL
- Note count and plugin groups in the CL description (e.g. "12 engine binaries added: MassGameplay, LiveLink, USD")
- If nothing found, continue silently

**Deletes** (reconcile delete) — HARD STOP rule:

For each engine plugin binary the reconcile wants to delete, check `Myst_Proto/UE_Blank_Proto.uproject`:

- **Plugin has `"Enabled": false` in .uproject** → delete is intentional (build correctly skipped it). Include in CL, note in description as "removed binaries for explicitly disabled plugin: [name]".
- **Plugin is NOT listed with `"Enabled": false`** → **BLOCKING. Do not proceed.** Report to the user:

  > "Reconcile wants to delete engine plugin binaries that are not explicitly disabled in .uproject: [list of DLLs]. Submitting these deletes will break team members who depend on them. Possible causes: the build skipped this plugin, or it was never rebuilt after a config change. Either add `\"Enabled\": false` to .uproject if the plugin is intentionally unused, or investigate why the build didn't produce these DLLs."

  Do not add these files to the CL. Wait for user decision before continuing.

> **Why this rule exists**: In May 2026, ChaosVehiclesPlugin binaries were deleted from the depot by a reconcile run on a machine that hadn't built the plugin. The plugin was not disabled in .uproject, so the engine tried to load it on sync and failed for all designers. An explicit `Enabled: false` entry in .uproject is the source of truth for "this plugin is intentionally absent."

### 4. Create Named Changelist

Create a new Perforce changelist with description:
```
[build][sxc] Update project binaries after P4 sync
```

If engine dependency binaries were found in Step 3b, append to the description:
```
[build][sxc] Update project binaries after P4 sync — includes engine plugin dependencies: <list plugin groups>
```

Move all reconciled binary files (project + engine dependencies) into this CL.

Run `p4 describe -s <CL>` to confirm contents and present to the user.

### 5. Verify — Launch Editor

Launch the Unreal Editor:
```
Engine/Binaries/Win64/UnrealEditor.exe "c:\_LocalDev\UE_Blank_Proto\Myst_Proto\UE_Blank_Proto.uproject" -log
```

Run in background. Wait ~60 seconds for startup, then check:
- The UE log at `Myst_Proto/Saved/Logs/UE_Blank_Proto.log` for real errors
- Ignore standard noise: PIX plugin, missing iOS/Mac/TVOS/Android platforms, USB errors
- Look for: compilation errors, module load failures for project/plugin modules, map check errors

Report findings to the user. If there are real errors, **stop and do not submit**.

### 5b. Fix-and-Rebuild Cycle

If Step 5 reveals errors that require a code fix (e.g. AngelScript binding conflicts, compilation errors):

1. Close the editor (Step 6)
2. Apply the fix — checkout affected files, make changes, create a separate CL for the fix
3. **Rebuild** (repeat Step 2)
4. **Revert and re-reconcile ALL binaries** — repeat Steps 3 and 3b from scratch against the new build output. The previous reconcile is stale and must be discarded.
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

**Decision based on review result:**
- If review returns **all green** (no BLOCKING issues, no unresolved WARNINGs): **auto-submit without asking the user.**
- If review returns **any BLOCKING issue or WARNING you are uncertain about**: stop, present the review findings to the user, and ask for approval before submitting.
- If review returns only **INFO-level notes**: treat as green and auto-submit.

### 8. Submit

```
p4 submit -c <CL>
```

Report the final submitted CL number.

## Notes

- If binaries haven't changed (nothing to reconcile), report that and skip CL creation
- Watch for "also opened by" warnings during reconcile — inform the user
- This workflow follows the perforce overlay's ReviewAndSubmit / ChangelistVerification requirements (when that overlay is installed).
