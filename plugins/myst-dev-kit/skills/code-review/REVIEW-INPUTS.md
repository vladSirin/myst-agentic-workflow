# Myst review input mapping

Apply this mapping to the upstream input steps. The review method stays upstream.

## Project and spec

Use the target project's tracker workflow and explicit spec pointers selected by
LOCAL-INTEGRATION. Use that workflow for upstream's tracker lookup.
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

Use the upstream brief and questions for each axis. Both get the same pinned
change. When the committed Git range covers the request, use upstream Step 4's
diff command, commit list, axis references and review questions. Keep the
coordinator's pin checks, file inventory and context record in its own ledger.
Supplement the briefs only with ticket changes inside the requested scope
that the range misses.
For Perforce, supply the selected CL evidence. Standards gets the standards
paths and full smell baseline.
Spec gets the original spec path or its fetched contents.

If an axis needs an observation it cannot obtain from the change, quote it
exactly and identify the source and test conditions. Mark any missing condition
unknown. Leave interpretation and the verdict to the reviewer.
For immutable captured evidence, include its recorded hashes when available.
No VCS action in this adapter authorizes publication or description edits.
