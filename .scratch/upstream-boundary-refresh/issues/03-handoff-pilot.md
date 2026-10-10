# Changeset 2: Pilot the handoff source boundary

Type: task
Status: closed
Spec: [approved plan, Changeset 2](../../../docs/plan_upstream_boundary_refresh.md#changeset-2-pilot-handoff-without-changing-all-skills)

## Scope

Preserve the complete pinned handoff subtree. Add a local public entry, host
metadata, source record, and provenance. Keep its public name and user-only
invocation. Use disposable install fixtures for discovery, bundled bytes,
relative links, Windows temporary output, and fresh-host invocation checks.
Record recursive discovery separately from normal installation. No installed
plugin clone or consumer project is edited.

## Acceptance

- Source bytes match the pinned upstream subtree, including metadata.
- Supported normal discovery exposes one public wrapper, with readable source.
- Direct use reaches that wrapper and source, and writes outside the workspace.
- Record the actual host/installer versions and limits; static checks do not
  count as successful runtime invocation.
- Stop further migration if default discovery exposes duplicate raw skills.

User verified Changeset 1 on 2026-10-07. The local branch is
codex/handoff-source-pilot, stacked on the preceding verified changesets.

## Evidence and remaining gate

See [pilot evidence](../../../docs/handoff-pilot-2026-10-07.md).
Source equality, copy integrity, Codex discovery, Claude manifest
validation, and one approved Codex copy runtime passed. The visible upstream/
layout failed Codex discovery; .upstream/ fixed that duplicate. Repeated OpenCode
scans then selected the nested raw entry in one run and wrappers in others.
The ZIP revision resolves that failure: one loose SKILL.md per copy, Codex
discovery passed, and ten fresh OpenCode scans selected public wrappers. Both
Python and PowerShell archive readers passed. Nineteen verifier tests and an
independent upstream comparison passed. Remaining supported-host, installed-plugin,
cross-skill, and personal-copy checks keep this ticket open. Changeset 3 has
not started. A follow-up approved fresh Codex session then passed with the final
ZIP wrapper: it read the archived instructions, referenced the synthetic plan,
and wrote the handoff to Windows TEMP. The trace and output hashes are in the
pilot report. This closes the direct Codex project-copy runtime case only.

The later host checks passed Codex installed-plugin execution, OpenCode
copy execution, and isolated personal/global copying. OpenCode's native
permission.skill.handoff=deny rule blocked a model skill call while its explicit
/handoff command still worked. README now states the host difference and links
the tested configuration. Claude copy discovery, normal plugin installation,
and offline command registration passed; its model request returned
account_on_hold. Claude runtime and invocation restrictions remain unverified.
Temporary plugin and marketplace registrations were removed. Keep this ticket
open and do not start Changeset 3 until the remaining acceptance is resolved.

## Owner deferral, 2026-10-07

The owner deferred the remaining Claude runtime and invocation tests until
they explicitly notify us Claude works. Do not retry or schedule these tests
before that notification. This supersedes the Claude execution gate above;
the tests remain unverified and no longer block changeset closure or further
migration. Implementation and reviews are ready for changeset closure, subject
to ordinary user verification. No publication is authorized by this exception.

The owner authorized moving to the next step on 2026-10-07 after reviewing the
pilot results and deferring Claude tests. This closes the current pilot scope.
Claude verification remains deferred in the pilot report until owner notification.
