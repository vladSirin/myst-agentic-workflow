# Myst review input mapping

Apply this mapping to the upstream input steps. The review method stays upstream.

## Project and spec

Use the target project's tracker workflow and explicit spec pointers selected by
LOCAL-INTEGRATION. Map upstream docs/agents/issue-tracker.md to that workflow.
The excluded setup-matt-pocock-skills is not a fallback: report the missing pointer
and establish the project contract. Honor a caller's verified spec, including a
Ticket: pointer supplied by review-and-submit. Otherwise use upstream's ordered
lookup. If no spec is found, ask; skip the Spec axis only when the user confirms
there is no spec, and report the skip explicitly.

## Pin one review input

Keep the target, requested scope, file actions, base revisions, evidence source,
and diff fixed for both reviewers. Reuse a caller's pinned evidence after checking
that it matches the requested scope and current revisions/content. If it is stale,
incomplete, empty, or cannot be checked, report the gap before dispatch. An
explicitly supplied snapshot may be reviewed as that snapshot; identify its age
and limits instead of presenting it as a fresh live-state check.

Before the upstream workflow, read only the input reference for the target VCS
resolved through LOCAL-INTEGRATION:

- **Git:** read [Git review inputs](GIT-INPUTS.md).
- **Perforce:** read [Perforce review inputs](PERFORCE-INPUTS.md).
- **Unclear target:** resolve it before reading either detail reference or dispatching.

Give both axes the same pinned evidence, file list, revision identity, and command
or snapshot source. Include the spec and standards references each axis needs.
For immutable captured evidence, include its recorded hashes when available.
Keep any caller-supplied finding categories, read-only constraints, and artifact
anchors. No VCS action in this adapter authorizes publication or description edits.
