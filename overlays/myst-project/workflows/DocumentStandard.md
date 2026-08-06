# Document Standard

**MANDATORY**: All AI agents and contributors MUST follow this standard when creating, renaming, or managing documents in `{{game_docs_root}}/`.

> For AngelScript file naming and folder structure rules, see [ScriptStandard.md](ScriptStandard.md).

---

## File Naming Convention

### Format

```
{type}_{descriptive_name}[_v{N}][_WIP].md
```

### Rules

| Element | Rule | Examples |
|---------|------|----------|
| **Type prefix** | Required. One of: `design_`, `guide_`, `plan_`, `ref_` | `design_dialogue_system.md` |
| **Descriptive name** | `snake_case`, concise, no filler words | `checkpoint_save`, `flow_subsystem_api` |
| **Version suffix** | `_v{N}` — only when a doc fully supersedes a prior version | `design_ld_triggers_v2.md` |
| **WIP suffix** | `_WIP` — document is in-progress / not yet approved | `design_audio_system_WIP.md` |
| **No other suffixes** | Never use `_Updated`, `_Deprecated`, `_Final`, `_New` | — |

### Type Prefixes

| Prefix | Purpose | Examples |
|--------|---------|---------|
| `design_` | Feature designs, system architecture, refactor proposals | `design_npc_dialogue.md` |
| `guide_` | How-to guides, setup instructions, workflows | `guide_level_blueprint_setup.md` |
| `plan_` | Implementation roadmaps, phase plans, iterative plans | `plan_iterative_roadmap.md` |
| `ref_` | API references, lookup tables, cheat sheets | `ref_frogevent_api.md` |

### Lifecycle

```
Creation:       design_feature_WIP.md        (WIP = in progress)
Approved:       design_feature.md            (remove _WIP suffix)
Superseded:     design_feature_v2_WIP.md     (new version, old stays as-is)
Deprecated:     ToBeDeleted_design_feature.md (prefix with ToBeDeleted_)
Deleted:        p4 delete                    (remove from depot)
```

### Key Rules

1. **In-place updates don't change the filename.** If you edit a finalized doc, just edit it. Don't add `_Updated`.
2. **Version bump only for full rewrites.** If the doc is substantially rewritten and the old version is superseded, create `_v2`. The old `_v1` (or unversioned original) gets renamed to `ToBeDeleted_`.
3. **`_WIP` is the only state suffix.** A doc is either WIP or finalized. No other states.
4. **`ToBeDeleted_` prefix marks deprecation.** These files are candidates for deletion. They stay until explicitly purged.
5. **Subdirectories are allowed.** Use `Plans/` for phase-specific plans if needed.

---

## Document Structure

All design and plan documents SHOULD include these sections (see the `design` skill's `PROCESS.md` in the myst-dev-kit plugin for the full template):

1. **Title** — `# {Document Title}`
2. **Metadata line** — `**Version**: v{N} | **Updated**: {YYYY-MM-DD} | **Status**: {WIP|APPROVED|COMPLETE}`
3. **Change Log** — Version history with dates
4. **Overview** — What and why
5. **Content sections** — Varies by document type
6. **Implementation Plan** — For designs: phased CLs with verification steps

---

## Examples

### Correct naming

```
design_flow_subsystem_api.md          ✅  Finalized design
design_ld_triggers_v2_WIP.md          ✅  v2 rewrite, in progress
guide_level_blueprint_setup.md        ✅  Finalized guide
plan_iterative_roadmap.md             ✅  Finalized plan
ToBeDeleted_design_old_triggers.md    ✅  Marked for deletion
```

### Incorrect naming

```
design_flow_subsystem_api_Updated.md  ❌  Don't use _Updated
design_ld_triggers_Final.md           ❌  Don't use _Final
design_ld_triggers_Deprecated.md      ❌  Use ToBeDeleted_ prefix instead
DESIGN_flow_subsystem.md              ❌  Prefix must be lowercase
flow_subsystem_api.md                 ❌  Missing type prefix
```
