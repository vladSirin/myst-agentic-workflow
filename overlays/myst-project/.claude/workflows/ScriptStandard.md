# Script File Naming & Structure Standard

**MANDATORY**: All AI agents and contributors MUST follow this standard when creating, renaming, or organizing AngelScript files in `Myst_Proto/Script/`.

---

## File Naming Rules

```
{SystemPrefix}{DescriptiveName}{TypeSuffix}.as
```

**Apply rules in this order — exceptions first, then base rules:**

1. Check if the file is a listed exception below — apply that rule
2. Otherwise apply base rules:

| Rule | Detail |
|------|--------|
| **Casing** | PascalCase always. No underscores, no hyphens. |
| **Prefix** | `Myst` for project-specific gameplay classes. `AS` for engine base classes. System-scoped classes are **exempt from the `Myst` prefix** when the folder already provides namespacing (e.g. `FlowSubsystem.as`, `ObjectiveSubsystem.as`, `MissionControllerBase.as`). |
| **Type suffix** | Required for typed classes (see Type Suffixes table). |
| **One class per file** | One primary class per file. Filename matches the primary class name minus the `U`/`A` prefix. |
| **Plugin scripts** | Plugin-specific AngelScript files live inside the plugin's own `Script/` folder, not in the game project's `Script/`. |

### Exceptions (check these first)

| Exception | Rule | Reason | Examples |
|-----------|------|--------|---------|
| **Example files** | `Example_{Feature}.as` — underscore after `Example` prefix only | Makes example code distinguishable from gameplay code at a glance | `Example_Actor.as`, `Example_Array.as` |
| **Level script actors** | Filename must **match the map asset name exactly** | UE hardcodes the class name in the level blueprint's parent class binding. Renaming requires editor reparenting. | `GYM_Mission_LevelScriptActor.as`, `Myst01Proto_P_WP_LevelScriptActor.as` |

### Type Suffixes

| Suffix | Use | Example |
|--------|-----|---------|
| `Capability` | Capability-based ability | `MystPlayerJumpCapability.as` |
| `Component` | UActorComponent subclass | `MystPlayerJumpComponent.as` |
| `Subsystem` | UWorldSubsystem or UGameInstanceSubsystem | `FlowSubsystem.as` |
| `Types` | Structs, enums, shared type definitions | `FlowTypes.as` |
| `Tags` | GameplayTag constant definitions | `MystTags.as` |
| `LevelScriptActor` | Per-level script actor — filename mirrors map asset name | `GYM_Mission_LevelScriptActor.as` |
| `Base` | Abstract base class — append to any other suffix or stand alone | `MissionControllerBase.as`, `MystCapabilityBase.as` |
| *(none)* | Actors, triggers, characters — no suffix needed | `MystDoor.as`, `MystPlayerCharacter.as` |

---

## Folder Structure

```
Script/
├── CapabilitySystem/          → Capability framework base classes + reusable shared infrastructure
│   ├── ASCapability.as              → Engine base class (no Myst prefix — engine-scoped)
│   ├── ASCapabilitySet.as           → Engine base class
│   ├── MystTags.as                  → Project GameplayTag definitions
│   └── Components/                  → Reusable infrastructure components (generic, NOT player-specific)
│       ├── MystJumpComponent.as     → Generic jump physics calculator (used by examples + future reuse)
│       └── MystMovementComponent.as → Generic movement physics calculator
│
├── FlowSystem/                → Game flow, mission lifecycle, level script actor base
│
├── ObjectiveSystem/           → Objective tracking subsystem
│
├── Gameplay/
│   └── Player/
│       └── Movement/
│           ├── {MovementType}/                    → One subfolder per movement type
│           │   ├── MystPlayer{Type}Capability.as  → Player-specific capability
│           │   └── MystPlayer{Type}Component.as   → Player-specific component
│           └── MystPlayerMovementComponent.as     → Player-specific base movement
│
├── Triggers/                  → Interactable level actors (doors, destructibles, reach triggers)
│
├── Missions/
│   └── {MissionName}/         → One subfolder per mission/map
│       ├── {MapName}_LevelScriptActor.as   → Level script (name mirrors map asset exactly)
│       └── {MapName}_*.as                  → Other mission-specific scripts
│
├── Myst/                      → Core project character classes
│                                AMystPlayerCharacter is canonical.
│                                AMystCharacter is legacy — do not create new files here without reason.
│
├── Tests/                     → All test actors and test scripts
│
└── Examples/                  → All AngelScript examples (general + domain-specific)
    ├── Example_{Feature}.as       → General AngelScript tutorials (50+ files)
    ├── GAS/                       → Gameplay Ability System examples
    ├── EnhancedInput/             → Enhanced Input System examples
    └── Editor/                    → Editor tool examples
```

---

## Key Rules Summary

1. **PascalCase everywhere** except `Example_` prefix (underscore intentional) and LevelScriptActors (must match map name).
2. **`Myst` prefix** for gameplay classes. Omit when the folder provides namespacing.
3. **`CapabilitySystem/Components/`** holds generic, reusable infrastructure. Do NOT put player-specific components here.
4. **`Gameplay/Player/`** holds player-specific capabilities and components.
5. **Examples go in `Script/Examples/`** — general in root, domain-specific in subfolders (`GAS/`, `EnhancedInput/`, `Editor/`).
6. **Tests go in `Script/Tests/`** — no test files in system folders.
7. **One class per file.** Filename matches the primary class name (minus U/A prefix).
8. **Level script actor filenames are frozen** — renaming requires UE Editor reparenting of the level blueprint.

---

## Examples

### Correct

```
Script/Gameplay/Player/Movement/Jump/MystPlayerJumpCapability.as    ✅  Player capability, correct folder
Script/CapabilitySystem/Components/MystJumpComponent.as             ✅  Generic infrastructure, correct folder
Script/Examples/Example_MystJumpCapability.as                       ✅  Teaching example with prefix
Script/Missions/GYM_Mission/GYM_Mission_LevelScriptActor.as        ✅  Map name preserved exactly
Script/FlowSystem/FlowSubsystem.as                                  ✅  No Myst prefix — folder provides context
```

### Incorrect

```
Script/Gameplay/Player/Movement/Jump/MystJumpComponent.as           ❌  Generic infra in player-specific folder
Script/CapabilitySystem/Examples/MystJumpCapability.as              ❌  Example not in Examples/
Script/Examples/MystJumpCapability.as                               ❌  Missing Example_ prefix
Script/GASExamples/Example_GASAttributes.as                         ❌  Domain examples not in Examples/GAS/
Script/Gameplay/Player/Movement/Jump/jump_capability.as             ❌  Not PascalCase
```

---

## Cross-references

- [DocumentStandard.md](DocumentStandard.md) — naming and lifecycle rules for `.md` documents in `{{game_docs_root}}/`
- Submitting script changes to Perforce follows the perforce overlay's ReviewAndSubmit and ChangelistVerification workflows (when that overlay is installed).
