# Verify upstream source bundles

Run from the repository root with Python 3.12 or later and Git installed:

```text
python tools/verify_upstream.py
python tools/verify_upstream.py --require-complete
python -m unittest discover -s tests -p test_verify_upstream.py -v
```

The first command permits explicitly listed migration debt. The second is the
final release gate and rejects any remaining debt. Both compare every migrated
bundle against independently acquired pinned source, not just local hashes.
Network/acquisition failure is a failed check. Nothing is installed or executed
from downloaded sources. These are repository tools, not plugin runtime files.

CI runs the fixture tests and verifier on the migration branch and main. PRs
targeting main and pushes to main use --require-complete. Existing checks remain.
At the Changeset 1 baseline, no bundles had migrated. The handoff pilot now
verifies one import, with 24 pending imports and four local skills. This does
not certify the old imports or complete the host-runtime acceptance gate.

## Source record

Each migrated import has UPSTREAM.json at its public skill root. The
[version 1 schema](upstream-source-record.schema.json) documents the format;
the command validates its fields with the standard library and adds filesystem
and cross-file checks. Use lowercase full SHA-256 values for every source file.

| Field | Meaning |
| --- | --- |
| schemaVersion | Integer 1 |
| provider | git or github-release-zip |
| root | Relative source directory or ZIP inside this skill; handoff uses upstream.zip to prevent nested skill discovery |
| source.url | HTTPS GitHub repository URL |
| source.revision | Full Git commit SHA, or the release tag for ZIP assets |
| source.subtree | Original skill directory in the repository or archive |
| source.assetId | Required for ZIP: immutable GitHub release asset identity |
| source.archiveSha256 | Optional ZIP archive hash; when present, checked against the whole downloaded archive |
| files | Object mapping every raw-source relative filename to its SHA-256 |
| dependencies | Unique list of required public Myst skill names; empty when none |

Preserve original paths and all companions. The raw-source file set must equal
both the record and the complete upstream subtree. A changed file plus a new
local hash still fails comparison with pinned source. A missing companion cannot
be excused by removing it from the record. Symlinks, escaping paths, and
case-colliding file names are rejected. Source files are compared as raw bytes,
without newline or BOM normalization.

A source ZIP contains only files, with member paths relative to the original
skill root. It preserves each original filename, relative path, and byte.
The verifier reads members without extracting them and rejects duplicate,
unsafe, linked, or non-file entries. It compares member hashes against the same
independent source as a directory bundle. Container timestamps and compression
are not source content. Do not leave loose source copies beside an archive:
they would restore the discovery bug documented in the
[handoff pilot](handoff-pilot-2026-10-07.md).

The local SKILL.md must contain an inline Markdown link to the raw SKILL.md
or, for an archived bundle, its ZIP and instructions to read SKILL.md inside it;
PROVENANCE.md must link to UPSTREAM.json. Relative inline links in those two
local files must resolve inside this repository. Each declared dependency must
have a public SKILL.md in the library. These are structural checks: they do not
prove runtime loading, correct invocation, or a complete dependency declaration.
Those remain pilot/review obligations. Raw upstream prose is not rewritten to
make local link checks pass.

## Acquisition and evidence

Git acquisition fetches the full recorded commit SHA into a temporary bare
repository and reads its blobs directly. It never relies on a source working
tree's newline settings. Each repository/revision pair is fetched once per invocation.

ZIP acquisition resolves the recorded release through GitHub's API, checks its
asset ID, downloads the whole asset once per invocation, and reads only the
selected subtree. ZIP member CRCs are checked while reading. When the record
provides an archive hash, the complete downloaded archive is also verified.
An earlier research report's advertised archive hash remains advertised evidence
until an actual full-download check passes. Tests use small synthetic archives;
they do not establish equality of the real Hammer release.

There is no persistent acquisition cache or wrapper-only shortcut in this first
version. Temporary downloads are removed when the command ends. A review must
still establish that the selected source/pin and any policy edits are intended;
the verifier establishes equality to that source, not trust in its content.

## Migration policy

[upstream-policy.json](../upstream-policy.json) classifies current exceptions:
localSkills lists local-origin entries; pendingImports is the explicit waiver
for existing imports awaiting migration or removal. The
[inventory](migration-upstream-boundary.md) explains the work behind those rows.

In a skill migration PR, add its source record and remove its pending waiver
together. On retirement, remove the package and its waiver together. A new
local-origin skill gets a localSkills entry. Unknown installed entries, stale
policy names, overlapping classifications, and records still waived as pending
fail. Pending imports are never reported as verified source. Changes to this
policy require the same per-skill review as the package they classify.

The verifier does not infer dependency closure from natural-language source,
run skills, update consumers, or grant publication authority.
