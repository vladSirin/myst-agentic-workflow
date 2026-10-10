# Skill packaging research - 2026-10-08

**Status:** Research and proposal evidence. No packaging policy or production
skill changed. Claude runtime testing remains deferred.

## Finding

Use ordinary reference files for runtime loading. The official format supports
a public `SKILL.md` with optional documentation, scripts, and assets. It does
not prescribe ZIP files for runtime instructions. Its guidance also favors
short reference chains. A wrapper that reads preserved source as Markdown fits
this resource model. Renaming an upstream entry to avoid discovery is still a
Myst adaptation, not an officially endorsed vendoring format.
[Agent Skills specification](https://agentskills.io/specification)

The sampled entry points in Anthropic skills, OpenAI skills, Superpowers,
Vercel Agent Skills, and Matt Pocock skills use plain Markdown instructions and
supporting references. This is a sample, not a census or proof that every file
in these repositories is uncompressed. It does not establish rename-based
vendoring as common practice.
[Anthropic](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md),
[OpenAI](https://github.com/openai/skills/blob/main/skills/.system/skill-creator/SKILL.md),
[Superpowers](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md),
[Vercel](https://github.com/vercel-labs/agent-skills/blob/main/README.md),
[Matt Pocock](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md)

## Official host and installer evidence

| Surface | Verified behavior | Packaging implication |
| --- | --- | --- |
| Codex guide | Optional `references/`; explicit and implicit invocation; duplicate names can appear; disabling uses local path configuration. | Keep the public wrapper's metadata. Local disable settings are not a portable package exclusion. |
| Codex current source | Matches the exact `SKILL.md` basename. Ordinary roots default to recursive discovery; some plugin roots use direct children. | Do not assume all roots are shallow, or that every current plugin mode recurses. A nested `UPSTREAM.md` is not an entry under this scanner. |
| Claude Code guide | Linked supporting files are read as needed. User-only invocation is a host extension. `skillOverrides` is name-based and does not apply to plugin skills. | A plain reference is normal. The guide does not establish a portable subtree exclusion, or prove raw nested-entry discovery behavior. |
| OpenCode 1.18.35 source | Uses recursive `SKILL.md` patterns. External skill roots include dot directories. Duplicate names overwrite earlier records. | A hidden upstream directory is not a portable solution. Nested `UPSTREAM.md` does not match the entry pattern. |
| OpenCode V2 docs and current source | Matches Markdown at the source root and `SKILL.md` at any depth. | Nested reference Markdown remains a resource under a normal parent skill root. Do not register the reference directory itself as a source root. V2 is distinct from the installed 1.18.35 evidence. |
| Vercel Skills CLI source | Discovers exact `SKILL.md`, with recursive paths available. Installation copies the selected skill directory recursively, subject to exclusions. | Keep runtime source inside each installable skill. A sibling vendor directory is not automatically copied. |

Sources for the table:

- [Codex official guide](https://learn.chatgpt.com/docs/build-skills).
- [Codex discovery, revision 4d53e6b](https://github.com/openai/codex/blob/4d53e6ba0e71ed45510b5846424666a7687ffb33/codex-rs/ext/skills/src/loader/discovery.rs#L69)
  and [mode selection](https://github.com/openai/codex/blob/4d53e6ba0e71ed45510b5846424666a7687ffb33/codex-rs/ext/skills/src/loader/host.rs#L104).
- [Claude supporting files](https://code.claude.com/docs/en/skills#add-supporting-files)
  and [visibility settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings).
- [OpenCode 1.18.35 discovery](https://github.com/anomalyco/opencode/blob/v1.18.35/packages/opencode/src/skill/index.ts#L23).
- [OpenCode V2 guide](https://dev.opencode.ai/v2/docs/skills/)
  and [V2 source, revision 3865c696](https://github.com/anomalyco/opencode/blob/3865c696efc97f30a34ea55b1d0ea4c26d939ecd/packages/core/src/skill.ts#L79).
- [Vercel installer, revision 48dc9e8e](https://github.com/vercel-labs/skills/blob/48dc9e8eb8aa19040e91cb90ba0b642c9cbad57e/src/installer.ts#L374)
  and [discovery](https://github.com/vercel-labs/skills/blob/48dc9e8eb8aa19040e91cb90ba0b642c9cbad57e/src/skills.ts#L135).

No common exclusion marker was found in the standard or these guides. Host
settings differ in their scope and identity rules. Treat this as the result of
the inspected sources, not a claim about every host or future version.

## Candidate with the smallest runtime change

```text
skill-name/
  SKILL.md                    # Myst entry and local routing
  UPSTREAM.json               # Pin, original paths, packaged paths, hashes
  PROVENANCE.md
  agents/openai.yaml          # Public host metadata where needed
  references/upstream/
    UPSTREAM.md               # Original SKILL.md bytes, renamed on disk
    <all original companions and subdirectories>
```

The wrapper reads `references/upstream/UPSTREAM.md` through an ordinary file
read. Keep the original frontmatter, body, metadata, and companions byte-for-byte.
The raw frontmatter remains document content; it does not become a second
registered entry under the inspected scanners. Keep local invocation policy
in the public entry and its host metadata. Record each filename mapping and
verify it against the pinned original. Do not hand-edit preserved text.

This changes the current contract: [ADR-0008](adr-0008-strict-upstream-boundary.md)
requires original filenames as well as bytes. A proposal must explicitly amend
that narrow requirement. Do not describe a renamed package as preserving its
original paths. Do not restore the general render pipeline retired by
[ADR-0007](adr-0007-lean-library-supersedes-vendor-render-model.md) merely to implement
a small file mapping.

Relative links need care. In the current `codebase-design` source, both
`DEEPENING.md` and `DESIGN-IT-TWICE.md` link to `SKILL.md`. A rename leaves those
filesystem links unresolved. The wrapper must map an upstream-relative
`SKILL.md` reference to `UPSTREAM.md` and retain the source directory as the
base for other references. This preserves bytes, but it does not preserve
literal filesystem link behavior. A `SKILL.md` symlink alias could reintroduce
discovery. An upstream script that opens `SKILL.md` itself needs separate
assessment; prose routing cannot fix its file access.

## Options and limits

| Option | Benefit | Cost or constraint |
| --- | --- | --- |
| Plain preserved references with entry rename | Normal reads, visible Git text diffs, self-contained copy installs, no archive command at runtime. | Explicit filename exception and link mapping; pilot before broad migration. |
| Original upstream tree outside discovery roots | Preserves filenames and relative links. | Requires package/install coordination; selected-skill copy installs omit sibling trees. |
| Generated combined public entry | Can remove an extra read. | Requires source transformation, metadata separation, link handling, and generated-file checks; revives machinery the project retired. |
| Existing runtime ZIP | Preserves exact archive paths and keeps nested entries undiscoverable. | Custom runtime reader, shell/runtime dependency, weaker text review. |

Plain references remove the decompression command and its helper instructions.
They do not eliminate the wrapper, shared rules, or all additional reads, and
they do not guarantee a fixed token saving. No model-runtime cost comparison
was run for this proposal.

## Evidence boundary and next gate

The parent task ran a disposable `codebase-design` discovery fixture on Codex
0.160.1. Its four original source members retained their byte hashes under the
proposed mapping. Fresh app-server discovery returned one local wrapper; the
debug prompt included that entry. Evidence is at
`%TEMP%/myst-plain-source-proposal-20261008`. This proves that fixture's discovery
result only. It does not prove runtime companion routing, other hosts, or all
skills. Claude was not run.

Before adopting the layout, validate source/path mapping, one public entry,
normal plugin and selected-skill copy installs, and a real companion/back-link
load. Inventory other source references to `SKILL.md`, including scripts and
nested entries, before assuming the same mapping works for every import.
Keep Claude acceptance deferred under the user's existing instruction.
