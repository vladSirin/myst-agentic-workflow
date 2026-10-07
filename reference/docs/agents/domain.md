# Domain Docs

Project setup: identify the authoritative glossary or context map here using
links relative to this file. Point to existing files; do not rename them as part
of setup. Also identify the ADR directory. Replace this paragraph with the
project's choices before treating this template as project configuration.

## Before exploring

Read the authoritative domain docs for the work area and relevant ADRs. A map's
links select the scoped glossaries; follow those links rather than guessing
filenames. Live project pointers take precedence over starter templates.

For a Myst wrapper, use agentic-workflow's LOCAL-INTEGRATION.md to resolve
legacy CONTEXT.md / CONTEXT-MAP.md and new GLOSSARY.md / GLOSSARY-MAP.md names.
Use the selected files for both reads and writes. If both naming families exist
without authoritative pointers, establish ownership before writing. During
staged migration, retain the project's established convention. A new default
requires verified reader/writer readiness; absence of files is not that proof.

## Consumer rule

Use the selected glossary's vocabulary in issues, refactors, hypotheses, and
tests. Check existing domain language before inventing a synonym. Glossaries
hold vocabulary; specs and implementation decisions belong in their own docs
and ADRs. Do not create a second vocabulary source during an upstream refresh.
