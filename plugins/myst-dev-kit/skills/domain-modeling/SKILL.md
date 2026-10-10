---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing project glossaries (including CONTEXT.md or GLOSSARY.md), or recording or editing an ADR.
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Resolve authoritative domain pointers, scoped maps,
and glossary read/write targets through its legacy/new naming rules. Map upstream
GLOSSARY.md and GLOSSARY-MAP.md references to those selected project files.
Resolve scoped links relative to the map that declares them. Establish missing
or conflicting ownership before glossary writes; this migration does not rename
consumer files or create a second glossary.

Required Myst dependency for copy installs: agentic-workflow. Check its local
entry and shared contract before proceeding; use the Myst namespace or these
sibling paths rather than a same-name third-party skill.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those mappings. For glossary edits, use
[GLOSSARY-FORMAT.md](references/upstream/GLOSSARY-FORMAT.md). When an ADR is
warranted, use [ADR-FORMAT.md](references/upstream/ADR-FORMAT.md) and the project's
ADR location. Keep vocabulary and design decisions in their respective project
documents. The original source bytes are unchanged; only the packaged entry
filename differs.
