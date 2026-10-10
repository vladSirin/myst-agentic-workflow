# ADR 0009 - Plain upstream references with one filename mapping

**Status**: Accepted
**Date**: 2026-10-08
**Context owner**: package maintainer

## Context

ADR-0008's ZIP layout fixed duplicate discovery but required archive commands at
runtime. The owner approved a plain-file pilot, reviewed its Codex and OpenCode
results, and authorized production implementation. See the
[research](research-skill-packaging-2026-10-08.md) and
[pilot evidence](plain-source-pilot-2026-10-08.md). Claude runtime remains deferred.

## Decision

Keep one public Myst SKILL.md. Store the complete upstream subtree under
references/upstream, with the original entry packaged as UPSTREAM.md. Preserve
all upstream bytes, including frontmatter and companion files. Preserve every
other filename and relative directory. This is an explicit filename exception,
not a claim that the original filesystem layout remains identical.

UPSTREAM.json version 2 records the original inventory and hashes, with exactly
`"pathMap": {"SKILL.md": "UPSTREAM.md"}`. The verifier maps packaged files back
to those original names before comparing with independently acquired source.
It rejects extra or missing files, modified bytes, collisions including case-only
collisions, other filename mappings, and additional discovery entries. Version 2
requires a directory; existing version 1 directories and ZIP packages remain
supported during the per-skill transition.

The wrapper links directly to the plain upstream entry and relevant companions.
It resolves upstream-relative links from the source directory and maps back-links
to SKILL.md to UPSTREAM.md. Ordinary Markdown viewers do not apply that mapping.
Do not add a SKILL.md symlink or alias. If an upstream script requires that
physical filename, or a subtree contains another skill entry, stop that skill's
conversion and review its packaging separately. Do not rewrite upstream content.

Scope Git `-text` attributes to each imported reference subtree so checkout
preserves exact bytes. Keep local invocation metadata, routing, glossary rules,
VCS guards, and publication rules outside upstream files. No runtime download,
renderer, custom installer, or generated merged instruction body is introduced.

## Supersession and rollout

This decision supersedes only ADR-0008's original-filename requirement for the
root entry and its ZIP packaging default. ADR-0008 remains the source-ownership
contract; historical ADRs remain unchanged. The plain-reference layout becomes
the default for reviewed conversions and new imports that meet these conditions.
Unconverted ZIP packages stay valid until their own changeset is accepted.

Convert codebase-design first with verifier, provenance, and evidence updates.
Retain one skill per changeset and owner verification before the next conversion.
Restore the complete prior package for rollback. Preserve source pins, licenses,
and credits; publication and consumer changes remain separately scoped.

## Evidence limits

The pilot passed normal copy and plugin installation, Codex explicit/automatic
use, OpenCode native skill loading, companion/back-link reads, local vocabulary
mapping, and copy upgrade/rollback. It found model answer variation, not exact
output equivalence. Reference reads and local wrapper overhead remain. This does
not prove every host or future source layout will behave identically.
