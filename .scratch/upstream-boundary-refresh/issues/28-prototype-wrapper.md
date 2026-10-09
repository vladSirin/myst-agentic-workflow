# Restore Prototype source and local capture mapping

Type: task
Status: done; owner verification pending
Review base: f783dd4
Spec: [complete Matt imports](../../../docs/plan_upstream_boundary_refresh.md#changesets-4-onward-restore-and-refresh-each-imported-skill)
and [strict source boundary](../../../docs/adr-0008-strict-upstream-boundary.md).

Preserve the full approved prototype entry, LOGIC.md, UI.md, and Codex metadata.
Move only project/VCS capture and authority into a local entry. Preserve both
branches and model/user reach. Resolve companion links to the packaged source
entry, declare copy dependencies, remove only this pending waiver, retain credits.
Test direct/wrapped logic and UI alignment, artifact behavior, P4 routing, package
integrity, and discovery. No prototype test suite in the imported method. No
consumer update, live Perforce writes, publication, or Claude model tests.

Evidence: [report](../../../docs/prototype-wrapper-2026-10-09.md).
Owner verification remains the gate before another skill changeset.

Complete four-file source verified; former entry/companions have no method delta.
Five grounded runtime runs and external checks pass: both branch comparisons,
actual module/walkthrough and UI route/keyboard/production behavior, and synthetic
P4 capture despite a Git mirror. Differences and untested branches are recorded.
Source/unit/package/CI checks pass; independent Standards and Spec reviews GREEN.
No installed consumer or live project update and no publication.
