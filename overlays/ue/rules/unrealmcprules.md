---
trigger: model_decision
description: When working with Unreal Engine assets, Blueprints, levels, actors, materials, or the editor
---

## Unreal Engine MCP Tools — Reach for them first

**Rule:** When the task involves Unreal Engine assets, Blueprints, levels, actors, materials, the editor, or anything under `/Game/...`, **load and use the `mcp__unreal-engine__*` tools instead of `Read`/`Grep`/`Bash`**.

### Why
- `.uasset` and `.umap` files are **binary**. `Read` returns garbage, `Grep` matches noise.
- The MCP tools speak to a running editor: property reads, actor spawns, level loads, material edits run against live state, not stale text.
- Falling back to general tools wastes context and produces wrong answers.

### Trigger conditions (any one is enough)
- File extensions: `.uasset`, `.umap`
- Asset paths: `/Game/...`
- Asset prefixes: `BP_`, `WBP_`, `SM_`, `MI_`, `M_`, `T_`, `A_`, `NS_`, `DA_`
- Keywords in the task: "blueprint", "actor", "level", "material", "asset", "editor", "PIE", "viewport", "world partition", "data layer", "lighting", "CDO"

### Mechanism — load the schemas first
The Unreal Engine MCP tools are **deferred**. They appear by name in the session's deferred-tool list, but their schemas are not preloaded. Calling them directly fails with `InputValidationError`. Run `ToolSearch` first to load the schemas:

```
ToolSearch(query: "select:mcp__unreal-engine__inspect,mcp__unreal-engine__control_actor,mcp__unreal-engine__manage_asset,mcp__unreal-engine__manage_level,mcp__unreal-engine__control_editor,mcp__unreal-engine__system_control")
```

Load only the subset you need for the current task. After the `<functions>` block appears in the tool result, the listed tools are callable for the rest of the session.

### Tool selection
| Trigger | Tool | Action(s) |
|---|---|---|
| Read Blueprint default properties without spawning | `mcp__unreal-engine__inspect` | `inspect_cdo` (uses `blueprintPath`) |
| Inspect a live world actor | `mcp__unreal-engine__inspect` | `inspect_object`, `get_components`, `get_property` |
| Spawn / move / configure an actor | `mcp__unreal-engine__control_actor` | `spawn`, `set_transform`, `add_component`, `set_blueprint_variables` |
| Create / duplicate / move / delete an asset | `mcp__unreal-engine__manage_asset` | `create_material`, `duplicate_asset`, `move_asset`, `delete_asset` |
| Edit a Material graph | `mcp__unreal-engine__manage_asset` | `add_material_node`, `connect_material_pins`, `rebuild_material` |
| Load / save / stream a level, build lighting | `mcp__unreal-engine__manage_level` | `load`, `save`, `stream`, `build_lighting`, `create_light` |
| Start PIE, screenshot, run console command, open asset | `mcp__unreal-engine__control_editor` | `play`, `screenshot`, `console_command`, `open_asset` |
| Run UBT, set CVar, run profiler | `mcp__unreal-engine__system_control` | `run_ubt`, `set_cvar`, `profile`, `execute_python` |

### What NOT to do
- Don't `Read` a `.uasset` or `.umap` — binary; output is useless.
- Don't `Grep` asset files for property values — they're not text.
- Don't skip `ToolSearch` and call `mcp__unreal-engine__*` directly — the call will fail.
- Don't shell out to UE console via `Bash`; use `control_editor.console_command`.
- Don't spawn an actor just to read its default values — use `inspect.inspect_cdo` instead.

> [!TIP]
> For most "what's in this Blueprint?" questions, `inspect_cdo` is the fastest path — it reads the Blueprint's Class Default Object without spawning an actor, and supports `propertyNames` to scope the read.
