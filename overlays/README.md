# overlays/

Optional content layered on top of the reusable core. Each overlay is opt-in
via `-Overlays <names>` at install time.

- `perforce/` — generic Perforce workflow: CL-by-CL verification, review-and-submit
  protocol, version-control conventions. Applies to any Perforce project regardless
  of engine/toolchain.
- `ue/` — Unreal-Engine specific: build/sync/submit commands, UE `.p4ignore`
  patterns (`Binaries/`, `Intermediate/`, `Saved/`). Pair with `perforce` for
  UE+P4 projects.
- `myst-project/` — Myst-only content (project paths, FrogEvent usage, AngelScript
  conventions, project-specific reviewers). Stays project-local unless generalized.

**Legacy alias**: `ue-perforce` (v1.0.0 – v1.1.0) is accepted by `init-consumer.ps1`
and expands to `perforce,ue`. New consumers should pick `perforce` and/or `ue`
explicitly.

A core-only install (no overlays) must never emit Perforce/UE/Myst-specific files.
**Layout (post marketplace-restructure):** each overlay holds ONE shared content
tree (`skills/`, `workflows/`, `agents/`, `commands/`, `rules/`, `scripts/`) with
no per-tool `.claude/`/`.Codex/` split. The manifest maps the same source file to
both tool targets; OpenCode was retired.

