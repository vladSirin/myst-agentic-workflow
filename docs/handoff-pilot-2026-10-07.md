# Handoff source-boundary pilot

Date: 2026-10-07. Status: **verified by owner for continuation; Claude runtime tests deferred by owner**.
Scope: [Changeset 2](plan_upstream_boundary_refresh.md#changeset-2-pilot-handoff-without-changing-all-skills),
based on verified local commit 1a9cabf. No release or consumer update occurred.

## Change and observed failure

The public handoff entry delegates to a complete, unchanged Matt source bundle.
[UPSTREAM.json](../plugins/myst-dev-kit/skills/handoff/UPSTREAM.json) records
commit 6fd947921b935b7e1e69293a200400f0fdd5c15f and subtree
skills/productivity/handoff. Both original files are preserved: SKILL.md and
agents/openai.yaml. The upstream method now names the OS temporary directory,
including Windows TEMP, explicitly. The local entry, public host metadata,
source record, and provenance are Myst-owned. The public name stays handoff;
explicit user invocation stays required. Provenance includes the upstream MIT
notice so a standalone skill copy keeps its license.

The original visible upstream/ candidate failed: Codex 0.160.1 registered both
the root wrapper and raw SKILL.md in project-copy discovery and plugin source
discovery. Moving only the source root to .upstream/ removed that duplicate.
Original source filenames, structure, frontmatter, and bytes were unchanged.
The source archive has a -text Git attribute to preserve its container bytes.
This is an observed packaging fix, not a new upstream behavior rule.

The final repeated OpenCode scan then exposed a second failure. One scan
selected the root .agents wrapper, another selected its nested
.upstream/SKILL.md, and a third selected the .claude wrapper. Each listed one
handoff name. Thus a count of one masked competing entries; hidden packaging
does not reliably preserve the wrapper in this host. The loose-folder candidate was rejected. Inspection of the installed executable
then confirmed recursive skills/**/SKILL.md discovery with dot directories,
unbounded parallel parsing, and assignment by name after each parse. The last
completed parse overwrites that name, which explains the variable selected path.

## Resolution

Store the full original subtree inside upstream.zip. Its member names, paths,
frontmatter, companions, and bytes remain intact. The package contains only one
loose SKILL.md: the public wrapper. No discovery-order dependency remains.
The wrapper reads the archived SKILL.md locally, using Python or Windows
PowerShell. Both command examples were tested. No download or extraction into
a discovery directory occurs. A local ZIP reader is now required.

UPSTREAM.json points at upstream.zip. The repository verifier supports both
existing directory bundles and ZIP bundles, compares each member against
independently fetched source, and rejects missing, extra, edited, unsafe,
duplicate, linked, and corrupt members. Updating a member and its local hash
still fails the independent comparison. A ZIP is a storage boundary, not a
rewrite or rendered version of the upstream method.

## Checks completed

| Check | Evidence and result |
| --- | --- |
| Independent source comparison | tools/verify_upstream.py passed: 1 imported bundle, 24 pending imports, 4 local skills. Both ZIP members matched independently fetched Git blobs. |
| Source verifier tests | All 19 acceptance tests passed, including five new ZIP integrity cases. |
| Existing CI checks | All six local workflow checks passed, including PowerShell 5.1 parsing, ASCII/BOM, frontmatter, version agreement, install commands, and retired-reference scan. Manifests remain 5.4.0. |
| Codex 0.160.1 discovery | Fresh app-server skills/list returned one enabled root handoff from the project fixture. plugin/read returned one myst-dev-kit:handoff from the candidate plugin source. This is source inspection, not an installed-plugin run. |
| skills 1.7.1 discovery | Normal --list and --list --full-depth each returned one handoff. Full-depth traversal deduplicates by name; it is not proof that no nested file was scanned. |
| skills 1.7.1 copy install | Project-scope --copy for codex, claude-code, and opencode succeeded. Every copied file matched the tested ZIP source package in both .agents/skills/handoff and .claude/skills/handoff. Relative wrapper/provenance links resolved within each copy. |
| OpenCode 1.18.35 discovery | **ZIP revision PASS:** 10/10 fresh debug skill processes selected a public wrapper, with the ZIP-loading content. Only one loose SKILL.md remained in each copied skill directory. The earlier folder layouts failed as recorded above. XDG config/data/cache/state were isolated; no model call occurred. |
| Claude Code 2.1.292 validation | plugin validate passed for plugin and marketplace. Project-copy startup registered handoff; a normal project-scoped test-plugin install preserved every handoff file. Offline SDK initialization registered myst-handoff-pilot:handoff with its argument hint. The runtime request failed with account_on_hold before model execution. |
| YAML and invocation metadata | Parsed both entries and both openai.yaml files. Local disable-model-invocation and allow_implicit_invocation: false preserve the intended user-only contract. Discovery and syntax alone do not prove enforcement in every host. |
| Codex copy runtime, earlier folder layout only | One approved fresh ephemeral session read the public wrapper, then .upstream/SKILL.md, then the synthetic PLAN.md. It wrote handoff-json-settings-20261007.md in Windows TEMP, outside the fixture workspace, and exited successfully. |
| Codex copy runtime, final ZIP layout | **PASS:** an approved fresh ephemeral Codex session read the final public wrapper and SKILL.md from upstream.zip using PowerShell, read PLAN.md, and wrote handoff-json-settings-zip-20261007.md in Windows TEMP outside the fixture. All commands and the session exited 0. |
| Codex installed-plugin runtime | **PASS:** the normal installer installed a uniquely named test plugin. A fresh session read the wrapper and archive from its installed cache, referenced PLAN.md, and wrote the correct handoff to Windows TEMP. Plugin and marketplace registrations were removed afterward. |
| Codex invocation metadata | Native model-context inspection omitted the installed test handoff while including its automatic diagnosing-bugs control skill. Explicit handoff invocation passed above. This checks catalog exposure, not every possible agent action. |
| OpenCode copy runtime | **PASS:** DeepSeek Flash through the existing configured provider called the native skill tool, loaded the public wrapper, read the archive, and wrote the handoff to Windows TEMP. Earlier fixture runs stopped on overly narrow test permissions; the final trace contains no tool errors. No global permission setting changed. |
| OpenCode explicit invocation and tool-call denial | **PASS with the local rule below:** run --command handoff read the archive and wrote a handoff while permission.skill.handoff was deny. A separate attempt to call skill("handoff") was rejected by that rule and loaded no skill. This covers the same tool path another skill would use; no additional router skill was introduced. |
| Personal/global copy installation | **PASS:** skills 1.7.1 --global --copy installed for Codex, Claude Code, and OpenCode into a disposable Windows USERPROFILE. Both .agents and .claude copies matched every source file and had one loose SKILL.md. Codex and OpenCode share the canonical .agents copy. This is install-byte evidence, not a model run in that profile. |

The runtime scenario kept a JSON settings format and handed off investigation
of missing-file handling. The output referenced the existing plan, preserved
the decision, and stated that no implementation or tests had run. The final
local description was then changed to explicit "Use when" trigger wording;
the method, delegation, and invocation flags did not change. Final discovery
and copy checks include that wording. After the user approved the follow-up
test, a fresh session exercised the final ZIP wrapper. The trace contains the
complete original archived instructions, and the output preserves the JSON
decision, plan reference, next investigation, and no-implementation/no-tests
status. The fixture package matched the source package byte for byte before
and after execution. This proves direct project-copy invocation in Codex; it
is separate from the later installed-plugin and OpenCode tests above.

The generic skill-creator quick_validate check rejected the existing
argument-hint and disable-model-invocation frontmatter keys. Those host fields
were retained. YAML parsing, repository lint, and native host checks are the
relevant evidence; the generic check is not reported as passing.

## OpenCode invocation configuration

OpenCode does not recognize disable-model-invocation; its
[documented skill fields and permissions](https://opencode.ai/docs/skills/#write-frontmatter)
use a separate host policy. To preserve explicit invocation for handoff, merge
this setting into the project's opencode.json, preserving existing settings,
then start a fresh session:

```json
{
  "permission": {
    "skill": {
      "handoff": "deny"
    }
  }
}
```

Use /handoff, or the CLI's run --command handoff, to invoke it explicitly.
The setting blocks model skill-tool calls, including those requested by another
skill, while the explicit command still loads the public wrapper. Both paths
were tested on 1.18.35. It is not installed by copying the skill directory;
the host configuration is required. Only disposable fixture configuration was
changed here. Apply the same pattern to other user-invoked skills only when
their migration is reviewed; this pilot does not migrate them.

### Slash-menu suggestions (1.18.35)

Follow-up menu check on 2026-10-09: a fresh OpenCode terminal found the candidate
handoff skill, but typing /handoff showed "No matching items". This is separate
from the earlier successful CLI execution. Version 1.18.35
[registers skill commands](https://github.com/anomalyco/opencode/blob/v1.18.35/packages/opencode/src/command/index.ts#L135)
but [hides them from autocomplete](https://github.com/anomalyco/opencode/blob/v1.18.35/packages/tui/src/component/prompt/autocomplete.tsx#L450).
Do not treat a missing suggestion as a missing skill or change the upstream
instructions to fix menu display.

For a visible /handoff suggestion, use an optional
[custom command](https://opencode.ai/docs/commands/#json). Merge these fields
into the project's existing opencode.json. Replace the path placeholder with
the absolute path to its installed public Myst entry. Preserve existing settings
and keep the skill-tool denial for this user-only skill.

```json
{
  "permission": {
    "skill": {
      "handoff": "deny"
    }
  },
  "command": {
    "handoff": {
      "description": "Compact the current conversation into a handoff document.",
      "template": "Read and follow the public Myst handoff wrapper at <absolute-installed-path>/handoff/SKILL.md. Follow its bundled source instructions for this request: $ARGUMENTS"
    }
  }
}
```

Start a fresh session. The disposable project used this configuration with its
actual absolute copy path. Typing /handoff then showed the command and its
description. The owner approved typing only; Enter was never pressed. This
proves alias display, not execution or policy enforcement for this template.
No provider was connected, no model request ran, and no real host configuration
was changed. The [candidate report](upstream-release-candidate-2026-10-09.md)
records the install, menu and rollback evidence and remaining limits.

## Deferred Claude verification

- Rerun Claude project-copy and installed-plugin invocation only after the
  owner explicitly reports Claude works. The attempt returned account_on_hold;
  offline registration and manifest checks do not substitute for execution.
- Complete Claude's explicit-only and cross-skill exclusion cases in that
  working runtime. Codex catalog filtering and OpenCode's tested host rule
  provide their stated cases, not a universal claim across versions.

The owner deferred these checks on 2026-10-07 until they notify us Claude works.
Do not retry or schedule them before that notification. The discovery blocker
is fixed, and this deferral removes the remaining Claude execution gate for
changeset closure and further migration. Keep Claude runtime unverified; the
exception does not turn missing evidence into a pass. Ordinary changeset
review, user verification, and publication requirements still apply.
The user approved the initial Codex model test and the follow-up ZIP-wrapper
test, then authorized the remaining host tests. Claude rejected its request
before execution; OpenCode calls used the existing configured DeepSeek provider.

## Reproduction and local evidence

Tools were temporary: skills ran under Node 24.19.0; Claude and OpenCode used
temporary Windows CLI packages. No installed Myst plugin clone was edited.
The fixture root on the test machine was
C:/Users/Shado/AppData/Local/Temp/myst-handoff-pilot-20261007.
Its local logs include codex-skills-list.json (visible-root failure),
codex-zip-final-skills-list.json, codex-plugin-read.json,
opencode-hidden-failure.json, opencode-recheck.json, opencode-zip-results.json,
codex-runtime.jsonl (earlier folder-layout run), and codex-zip-runtime.jsonl
(final ZIP-wrapper run, fixture codex-zip-runtime).
These temporary logs can expire;
this report retains the commands, versions, and bounded results.

Recreate the fixture from the handoff package and use:

```text
python tools/verify_upstream.py
python -m unittest discover -s tests -p test_verify_upstream.py -v
skills add <handoff-package> --list
skills add <handoff-package> --list --full-depth
skills add <handoff-package> --skill handoff --agent codex claude-code opencode --copy --yes --json
opencode debug skill
claude plugin validate ./plugins/myst-dev-kit
claude plugin validate .
```

Run copy installation and OpenCode discovery from the disposable project.
For Codex, initialize a fresh app-server and call skills/list with that fixture
in cwds and forceReload true; call plugin/read with the repository marketplace
path and pluginName myst-dev-kit. Count only handoff entries and confirm their
paths point at the local public wrapper.

The approved runtime used codex exec --ephemeral --json --sandbox workspace-write
with -C pointing to the fixture and an explicit $handoff request. It sent only
the synthetic scenario, fixture plan, skill, and normal session context to the
configured model service. Repeating external model tests requires the applicable
authorization; the local discovery commands do not invoke a model.

The follow-up used the same scenario and command options in codex-zip-runtime,
with output filename handoff-json-settings-zip-20261007.md. The prompt specified
the filename, not its directory; the agent obtained Windows TEMP itself. The
saved trace SHA-256 is
c030cc6b8a94f1195bdb6919022cbdf13697abdac803a9916d6ec725466ab2c2;
the output SHA-256 is
c393872a4b67a9802d1254102b94ad7cde4d96fbfab576024a125c64c17419af.

## Review status

The first review correctly blocked the loose-folder candidate after OpenCode
selected raw source. The ZIP revision is a fix within this same changeset;
source ownership and remaining acceptance requirements remain unchanged.
The revised staged diff was reviewed against 1a9cabf on 2026-10-07. Standards:
GREEN, no implementation defects; the reviewer independently reran all 19
acceptance tests. Spec: WARNING for the documented outstanding runtime cases,
with no new implementation mismatch or scope creep. Both reviewers confirmed
the source boundary and distinction between discovery and runtime evidence.
The direct Codex ZIP runtime case passed after that review; the other runtime
cases were then exercised as listed above. Claude execution remains blocked.
The host-evidence update was reviewed again: Standards GREEN; Spec WARNING
only for the acknowledged Claude runtime gate. No documentation defect found.
No publication or next changeset is authorized by a discovery-only pass.

## Host follow-up evidence and cleanup

Plugin checks used the separate marketplace myst-pilot-20261007 and plugin
myst-handoff-pilot. Only their test identities changed in the disposable
marketplace; installed handoff files matched the source package byte for byte.
Codex installed at user scope; Claude installed at the fixture's project scope.
Both test registrations and marketplace declarations were removed through
their CLIs. The regular myst-dev-kit@myst installation was not replaced.

The fixture directory contains codex-plugin-runtime.jsonl,
claude-copy-runtime.jsonl (account error), claude-plugin-initialize.json
(offline command registration), opencode-copy-runtime.jsonl,
opencode-direct-runtime.jsonl, opencode-user-only-denial.jsonl, and
global-copy-install.txt. Final successful runtime trace hashes:

| Trace | SHA-256 |
| --- | --- |
| Codex installed plugin | f9a49bc3dcc7ac05965a8abdd6f7b3a87a901a6c5cb1e5457c4a0c3d3165c072 |
| OpenCode skill invocation | 164178ae9d4f33e2534ef8b5673beef5fda25a217cb85d14d0b6b60afe78763c |
| OpenCode explicit command with deny rule | 4eeeddc88f501d4b73ec2d3a449f0e4025f1b911b8904cc1656f660d3b0ce663 |
| OpenCode rejected model skill call | 607cd935d8820b9c63719e24e3864b54d589e07cc664b711ba8c8c69e26b1bfd |
