# P4-description provenance

This is original Myst integration content, not a vendored upstream skill.
Myst owns all files in this directory. It has no UPSTREAM.json or raw source
bundle. Its runtime copy dependency is agentic-workflow only.

The Summary / Evidence / risk-section approach is inspired by Matt Pocock's
[pr skill at the approved pin](https://github.com/mattpocock/skills/blob/6fd947921b935b7e1e69293a200400f0fdd5c15f/skills/engineering/pr/SKILL.md).
The visual-summary idea is credited to Dex Horthy / Humanlayer's show-me skill,
as retained in Matt's [source credits](https://github.com/mattpocock/skills/blob/6fd947921b935b7e1e69293a200400f0fdd5c15f/skills/engineering/pr/CREDITS.md).

The complete unchanged pr source remains in the separate pr package. This local
skill adapts the purpose to Perforce: established title tags, English/ASCII text,
CL-version evidence, stable finding anchors, and Submit Risk. It does not copy a
second modified bundle or load pr/show-me at runtime. Attribution is not a skill
dependency. Description application and publication remain protocol-owned.
