# Upgrade guide — moving an existing consumer to v2.12.x

This is for projects that installed an **older** version of the scaffold and want the current
(upstream-HEAD-converged) skill set. A **fresh** install needs none of this — just run
`setup.ps1` (it auto-detects Perforce via `.p4ignore` and Unreal via `*.uproject`).

## Why a migration step is needed

The installer **adds and updates** files from the manifest but does **not delete** files that
were removed from the manifest. The convergence retired several skills:

| Retired / renamed | Action |
|---|---|
| `diagnose` | **renamed** → `diagnosing-bugs` (old `diagnose/` dir lingers) |
| `zoom-out` | removed |
| `caveman` | removed |
| `write-a-skill` | removed (replaced by `writing-great-skills`) |

If you only run `update.ps1`, those old skill directories survive as **orphans**. In Perforce
write-mode this also trips **preflight check 5** ("no unmanaged scaffold files"), which will
**block** the upgrade until the orphans are gone.

## Upgrade sequence (Perforce + Unreal consumer)

```powershell
$Pkg = "c:/path/to/myst-agentic-workflow"      # the package clone
$Target = "c:/path/to/your-ue-project"          # your consumer repo

# 1. Get the current package
git -C $Pkg pull

# 2. See what the old install left behind (read-only)
& "$Pkg/scripts/migrate-retired-skills.ps1" -TargetRoot $Target

# 3. Remove the retired skills. Perforce: emit the p4 commands and run them in a named CL:
& "$Pkg/scripts/migrate-retired-skills.ps1" -TargetRoot $Target -UsePerforce
#    ...copy/run the printed `p4 delete -c <CL> ...` lines, then `p4 submit` (or keep in the CL).
#    Filesystem (non-Perforce) consumers instead run:
# & "$Pkg/scripts/migrate-retired-skills.ps1" -TargetRoot $Target -Apply

# 4. Install the current scaffold (dry-runs first, then writes; wraps a P4 changelist):
& "$Pkg/update.ps1" -TargetRoot $Target -Yes        # add -UsePerforce -Changelist new if not auto-detected

# 5. Verify
& "$Pkg/scripts/compare-with-package.ps1" -TargetRoot $Target   # expect: clean
```

After step 4 the consumer has the full current set: `diagnosing-bugs` (with its `ue`-overlay
`UE-NOTES.md`), `resolving-merge-conflicts` (with its `perforce`-overlay `P4-NOTES.md`), and the
other new skills (`codebase-design`, `domain-modeling`, `grilling`, `teach`, `writing-great-skills`,
`implement`, `setup-matt-pocock-skills`, …). See the README "Skills" + "Divergence from upstream"
sections for the complete list.

## Notes

- **Skill format changed** to upstream-verbatim YAML frontmatter (ADR-0003). `update.ps1` overwrites
  the `SKILL.md`s (they're `copy`-strategy), so the format updates automatically — no manual step.
- **Overlays**: ensure your install includes `ue` and `perforce` (auto-added by `setup.ps1`; for an
  existing install confirm your installed manifest `Docs/agents/scaffold-manifest.json` lists them, or
  re-run setup with `-Overlays 'core,perforce,ue'`).
- **AGENTS.md / CLAUDE.md** workspace-setup blocks update via the generated-block mechanism on `update.ps1`.
- **Known limitation / future work**: auto-deletion of manifest-removed files isn't built into the
  installer yet — this helper covers the one-time retired-skill cleanup. A manifest-driven orphan-prune
  is tracked as a follow-up.
