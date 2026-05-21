# overlays/ (skeleton — not yet populated)

Optional content layered on top of reusable core. **Population is the next gated
phase (Extract Reusable Core), not part of the skeleton.**

- `ue-perforce/` — Perforce changelist workflow, review/submit protocol,
  CL-by-CL verification, build/submit commands, UE editor verification, `.p4ignore`
  fragment. Installs only when the `ue-perforce` overlay is selected.
- `myst-project/` — Myst-only content (project paths, FrogEvent usage, AngelScript
  conventions, project-specific reviewers). Stays project-local unless generalized.

A core-only install must never emit Perforce/UE-specific files.
