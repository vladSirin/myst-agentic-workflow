# Deep-dive provenance

The method is from the Hammer desktop app, by 卡兹克
(credited in the source body). The releases repository is
[dreamwords/hammer-releases](https://github.com/dreamwords/hammer-releases).
The source repo is private. [UPSTREAM.json](UPSTREAM.json) records the release,
asset ID, complete-archive hash, selected subtree, and original file hash.

references/upstream preserves the complete selected subtree: SKILL.md is
packaged as UPSTREAM.md, with its original Chinese frontmatter and unchanged body. There is no original agents/openai.yaml
or companion inside this subtree. The adjacent advanced-capabilities README
only describes bundled directories and Hammer's installation behavior; it adds
no method instruction, required companion, or license grant.

Myst owns this directory's public SKILL.md, agents/openai.yaml, source record,
and this note. The public frontmatter retains the existing English description,
argument hint, and disable-model-invocation: true. The local Codex metadata adds
allow_implicit_invocation: false. The wrapper reads the original source through a
plain reference and adds no method changes or skill dependencies. ADR-0009
authorizes the single filename mapping; only the public SKILL.md is discoverable.
Host invocation limits still require host-specific evidence.

Previously Myst recorded v0.19.0 and kept a local frontmatter above the upstream
body. The migration separates those owners and advances the pin. Re-vendoring
replaces only the complete source bundle and updates its record/provenance;
local discovery metadata stays separately owned and reviewed.

## Existing authorization

License note: upstream ships no public license for this content. Vendoring and
redistribution here are authorized by the project owner (sxc, 2026-08-27), who
holds the relationship with the app team and its authors; re-vendoring rides the
same authorization.
