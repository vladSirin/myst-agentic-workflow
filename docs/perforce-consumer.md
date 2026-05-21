# myst-agentic-workflow — Perforce consumer guide

UE + Perforce projects use a slightly different install / promote flow than
filesystem-only consumers. This guide covers the additions. Read
[`install.md`](install.md) first — that's the canonical guide for the workflow
itself; this document only covers the Perforce overlay.

The example project is `Acme_Game` in a depot at
`//AcmeStudio/main/Acme_Game/`.

---

## 1. The Perforce contract

When you run `install.ps1 -Mode Write` against a target inside a Perforce
client workspace:

- Every file the installer is about to modify must be **opened for edit**
  first (Perforce protects synced files; `p4 sync` makes them read-only).
- New files the installer creates must be **opened for add**.
- Failures must **revert** all opened files so the workspace is left clean.

These are the responsibilities `-UsePerforce -Changelist` encodes.

---

## 2. `-UsePerforce -Changelist <id|new>` flow

```powershell
$PkgRoot    = 'c:/path/to/myst-agentic-workflow'
$TargetRoot = (p4 -F %clientRoot% info)   # the Perforce client root
& "$PkgRoot/scripts/install.ps1" `
    -TargetRoot $TargetRoot `
    -PackageRoot $PkgRoot `
    -Tools all `
    -Overlays 'core,ue-perforce' `
    -Mode Write `
    -UsePerforce `
    -Changelist new
```

What the script does:

1. **Runtime preflight gate** (`run-skeleton-preflight.ps1`). Refuses to
   proceed unless 10/10. The most common failure for shared depots is item
   10 (`p4 opened -c default` not clean) — see [§4](#4-preflight-item-10-in-shared-depots).
2. **Creates a named CL** (when `-Changelist new`) via `p4 change -i` with a
   What/Why/Notes description that follows the project's ReviewAndSubmit
   convention. The CL number is reported in the output.
3. For every target that already exists: `p4 edit -c <CL> <target>`. The file
   becomes writable; the CL records the open.
4. Stages each write to a sibling `<target>.agentic-stage` temp file.
5. Atomically renames every temp into place AND updates the manifest hashes
   — single commit point. If anything throws, all replaces roll back and
   `p4 revert` runs on opened files. No half-installed state.
6. For new files: `p4 add -c <CL> <target>` after the atomic rename.
7. Reports the CL number in the final output. **The CL stays pending** —
   it's your job to review and submit (or revert).

---

## 3. CL reviewer workflow

After a successful install, you have a pending CL. Always inspect before
submitting:

```powershell
p4 describe -s <CL>             # see the description + file list
p4 diff -c <CL> //...           # see per-file diffs
```

Things to check:

- **File count matches expectation.** If the dry-run reported 12 changes,
  the CL should hold 12 files. More is a bug; report it.
- **Description follows What/Why/Notes.** The auto-generated description is
  minimal — edit it before submit to add project-specific context:
  ```powershell
  p4 change -o <CL> | <edit Description> | p4 change -i
  ```
- **No unrelated files.** Use `p4 opened -c <CL>` to confirm only the
  expected entries are open. If `install.ps1` somehow grabbed extra files,
  reopen them to a different CL:
  ```powershell
  p4 reopen -c default //path/to/unrelated
  ```

When happy: `p4 submit -c <CL>`.

If something looks wrong: `p4 revert -c <CL> //...` reverts every file and
discards the CL. The workspace is back to pre-install state.

---

## 4. Preflight item 10 in shared depots

Plan v1.6 preflight check 10 requires `p4 opened -c default` to be empty.
That's a high bar in shared depots — colleagues' WIP often ends up in default
change without being moved to a named CL.

**This is expected and not a bug in the installer.** The preflight is
reflecting depot state, not asserting the installer's correctness. Fix it
the way you'd fix any messy default change:

- Identify the files: `p4 opened -c default`
- For each file, either:
  - move to its owner's pending CL: `p4 reopen -c <CL> <file>`
  - or revert if it's accidental: `p4 revert <file>`
  - or move to a fresh CL if it's yours: `p4 change` (interactive)

Once `p4 opened -c default` returns "File(s) not opened on this client" (or
only your own intentional entries), re-run preflight. Item 10 will pass.

In a single-developer depot this is rarely an issue. In a multi-developer
project depot (typical for UE game projects), you may run preflight multiple
times during a workday and item 10 will swing.

---

## 5. The `+w` (always-writable) file-type pitfall

Some files in Perforce are stored with file type `text+w` — meaning they're
writable on the client even without `p4 edit`. JSON config files like
`opencode.json` commonly have this attribute (it's set by `p4 typemap`).

**The pitfall**: a developer or tool can edit such a file silently. The edit
won't show up in `p4 opened` because no checkout happened. But the file on
disk no longer matches the depot.

**Detection**: `compare-with-package.ps1` will report the file as
`downstream-edit` (its hash differs from what the package would render).

**Resolution**:

- If the edit is intentional: `p4 edit <file>; p4 submit` (or
  `promote-from-project.ps1` if it should land in the upstream package).
- If accidental: `p4 sync -f <file>` to force-restore from depot.

This is not specific to this package; it's a general Perforce gotcha. The
package surfaces it via the drift comparator.

---

## 6. Refusal modes — when `install.ps1 -Mode Write` exits non-zero

There are four ways the script refuses to write. Each prints an explanatory
banner and exits non-zero.

| Refusal | Trigger | Fix |
|---|---|---|
| Preflight failure | `run-skeleton-preflight.ps1` returns non-zero | Run preflight directly; resolve the failing check. See [`install.md` §6.1](install.md#61-preflight-not-1010). |
| Read-only target without `-UsePerforce` | A target file is read-only AND `-UsePerforce` is not set | Re-run with `-UsePerforce -Changelist <id|new>`. |
| `-UsePerforce` without `-Changelist` | Mutually-required parameters not both supplied | Add `-Changelist new` or `-Changelist <existing-id>`. |
| (Historical) block-scoped without ManifestUpdateAction | Pre-issue-08; no longer applies | N/A — fixed in issue 08. Mentioned only for archival reasons. |

---

## 7. Worked example: first-time install into Acme_Game

```powershell
# 1. Confirm we're inside the client workspace.
PS> p4 info
... clientRoot: c:\AcmeStudio\Acme_Game
... clientStream: //AcmeStudio/main
...

# 2. Set roots.
PS> $TargetRoot = 'c:\AcmeStudio\Acme_Game'
PS> $PkgRoot    = 'c:\Tools\myst-agentic-workflow'

# 3. Bootstrap the manifest if needed (see install.md §2.1).

# 4. Dry-run first.
PS> & "$PkgRoot/scripts/install.ps1" -TargetRoot $TargetRoot -PackageRoot $PkgRoot `
       -Tools all -Overlays 'core,ue-perforce' -Mode DryRun
...
  WRITE PHASE  (DryRun)
  ==============================================================
    47 file(s) would change:
      .claude/agents/architecture-reviewer.md  (copy)  0 -> 2507 chars
      ...
    DryRun: no files modified. Re-run with -Mode Write to apply.

# 5. Check default change before write.
PS> p4 opened -c default
File(s) not opened on this client.

# 6. Write mode with -UsePerforce -Changelist new.
PS> & "$PkgRoot/scripts/install.ps1" -TargetRoot $TargetRoot -PackageRoot $PkgRoot `
       -Tools all -Overlays 'core,ue-perforce' -Mode Write -UsePerforce -Changelist new
Write mode requested -- running Skeleton preflight as gate...
Preflight green (10/10). Proceeding with write phase.
...
  Created CL 12345 for write phase.
  Applying via InstallJournal (atomic rename)...
  Write phase committed. P4 CL: 12345

# 7. Inspect the CL.
PS> p4 describe -s 12345
Change 12345 by ackerman@ackerman_Acme_Workstation on 2026-05-22
    [design][sxc] Agentic scaffolding - install -Mode Write phase
    ## What
      - install.ps1 v0.2.0-extract-core writing 47 file(s) per package manifest.
    ...
PS> p4 opened -c 12345 | wc -l
47

# 8. Edit the description if you want more context.
PS> p4 change <12345>     # opens editor; expand description; save.

# 9. Submit.
PS> p4 submit -c 12345
Submitting change 12345.
...
Change 12345 submitted.
```

---

## 8. Cross-references

- [`install.md`](install.md) — general install / update / promote workflow.
- The consuming project's `.claude/workflows/ReviewAndSubmit.md` and
  `ChangelistVerification.md` — the CL-by-CL HARD RULE and What/Why/Notes
  description standard that this package's CL semantics follow.
- ADR 0001 — design rationale for the package as a whole.

The CL-by-CL HARD RULE (in particular): **never batch multiple CLs into one
submit action without explicit user authorization.** This package's
`install.ps1` produces one CL per `-Mode Write` run; submission stays the
user's call.
