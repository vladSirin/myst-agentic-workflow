# overlays/myst-project — reference overlay (don't install unless you ARE Myst_Proto)

This overlay is the original project-specific content from `Myst_Proto`, the
UE5/Perforce game project this package was extracted from. It is included as a
**worked example** of what a project-specific overlay looks like — not as
content other consumers should install.

## What's in here that's Myst-specific

| File | Why it's Myst-only |
|---|---|
| `.claude/rules/angelscriptrules.md` | Hardcodes paths `/Myst_Proto/Script/` and `/split_fiction_scripts/` |
| `.claude/agents/architecture-reviewer.md` | Description specialized for "Unreal Engine projects"; references FrogEvent plugin and Flow Subsystem |
| `docs/MustRead/MustRead_ai_tools_for_creatives.md` | Project-specific user manual for the Myst team |
| `.claude/skills/design.md` + workflow files | Tailored to Myst's review conventions and folder layout |

The `.Codex/` and `.opencode/` mirrors carry the same biases for the
corresponding tools.

## If you're adopting this package for your own project

**Don't install this overlay.** Run `setup.ps1` with the default overlay
selection (`core` + auto-detected `perforce`/`ue`):

```powershell
& ./setup.ps1 -TargetRoot c:/path/to/your-project
# Picks core[,perforce][,ue] — myst-project is never auto-added.
```

Then, if you want your own project-specific overlay, copy this directory's
structure as a starting point:

```
overlays/your-project/
├── .claude/
│   ├── agents/        # your-project-specialized reviewers
│   ├── rules/         # paths and references specific to your codebase
│   ├── workflows/     # your team's design / review / submit conventions
│   └── skills/        # project-specific skills
├── .Codex/            # same shape, for Codex
├── .opencode/         # same shape, for OpenCode
└── docs/MustRead/     # team-specific docs
```

Add `your-project` to `package-manifest.json`'s `manifestSchema.overlays` enum,
populate `manifest-template.json` with entries pointing at your overlay paths,
and `init-consumer.ps1 -Overlays 'core,your-project'` will pick it up.

## If you ARE Myst_Proto

This overlay is what your install consumes. Keep using it.

## Why we ship it in the public package

Two reasons:

1. **Provenance honesty** — the package was extracted from Myst; pretending
   otherwise by hiding the overlay would be marketing, not engineering.
2. **Reference implementation** — overlay structure is easier to learn from a
   working example than from abstract documentation. Open one of these files
   and the overlay pattern is concrete.

A future major version (v2.0) may extract this overlay to a separate repository
once a second project adopts the package and we have evidence about what's
genuinely portable vs what's project-specific. Until then it lives here, clearly
labelled.
