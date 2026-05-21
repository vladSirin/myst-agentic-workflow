# Sync, Build, and Submit Binaries

Execute the full workflow to sync from Perforce, build the editor, verify binaries, and submit updated binaries.

This command is part of the UE/Perforce overlay. It must not be installed for non-Perforce or non-Unreal projects unless explicitly requested.

## Workflow Steps

Stop and report to the user if any step fails.

## 1. Sync Latest from Perforce

```bash
p4 sync //UEPrototype/main/...
```

Report how many files were updated, added, or deleted.

## 2. Build the Editor

```bash
Engine/Build/BatchFiles/Build.bat UE_Blank_ProtoEditor Win64 Development -Project="c:/_LocalDev/UE_Blank_Proto/Myst_Proto/UE_Blank_Proto.uproject" -WaitMutex
```

The `-Project` path must be absolute.

If the build fails, show the last 50 lines of output and stop.

## 2b. Plugin Dependency Check

After a successful build, check whether newly synced plugins were added.

For each new plugin:

1. Read its `.uplugin` file and `.Build.cs` files.
2. Verify dependencies are available in the engine or project.
3. Check whether the plugin is listed in `Myst_Proto/UE_Blank_Proto.uproject`.
4. Report the dependency summary before proceeding.

Detect new plugins from P4 sync output for newly added `.uplugin` files or new directories under `Myst_Proto/Plugins/`.

## 3. Reconcile Project Binaries

Preview first with `p4 reconcile -n`, then reconcile changed files only:

- `Myst_Proto/Binaries/Win64/*.dll`
- `Myst_Proto/Binaries/Win64/*.modules`
- `Myst_Proto/Plugins/*/Binaries/Win64/*.dll`
- `Myst_Proto/Plugins/*/Binaries/Win64/*.modules`

Skip `.pdb` files.

## 3b. Engine Binary Dependency Check

Preview only with `p4 reconcile -n` on engine binary locations that may have changed because of plugin dependencies:

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

Skip `.pdb` files.

Parse preview output into adds/edits and deletes.

Deletes are blocking unless the corresponding plugin is explicitly disabled in `Myst_Proto/UE_Blank_Proto.uproject`.

## 4. Create Named Changelist

Create a named Perforce changelist:

```text
[build][sxc] Update project binaries after P4 sync
```

If engine dependency binaries were found, append the dependency groups to the description.

Move reconciled files into this CL and run `p4 describe -s <CL>` to confirm contents.

## 5. Verify Editor Startup

Launch:

```bash
Engine/Binaries/Win64/UnrealEditor.exe "c:\_LocalDev\UE_Blank_Proto\Myst_Proto\UE_Blank_Proto.uproject" -log
```

Wait about 60 seconds, then inspect `Myst_Proto/Saved/Logs/UE_Blank_Proto.log`.

Ignore known platform/plugin noise. Stop on real errors such as compilation errors, module load failures, or map check failures.

## 5b. Fix and Rebuild

If verification finds errors requiring a code fix:

1. Close the editor.
2. Apply the fix in a separate CL.
3. Rebuild.
4. Revert and re-reconcile all binaries from scratch.
5. Re-run editor verification.

## 6. Close the Editor

```bash
taskkill //IM UnrealEditor.exe //F
```

Verify the editor is closed before proceeding.

## 7. Tech Review

Use `architecture-reviewer` to review the changelist.

Auto-submit only when there are no blocking findings and no unresolved warnings.

## 8. Submit

```bash
p4 submit -c <CL>
```

Report the submitted CL number.
