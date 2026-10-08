# Description evidence handoff

The protocol owns evidence and authority; the selected formatter owns presentation.
Use only the target VCS's formatter. Give it the pinned changeset/version and file
scope, ticket/spec source or justified workflow skip, actual before/after evidence,
final Standards/Spec results, skip reasons, finding dispositions and anchors,
existing detail references, docs-alignment result or limit, human acceptance, and
remaining risks. Mark unavailable values as unknown; never infer GREEN or approval.

Use the formatter's three sections. Inside Evidence, preserve separate axis lines:

```text
Standards: <actual final result, or not reviewed>
Spec: <actual final result, or skipped with its confirmed reason>
```

Keep those labels at the start of unbulleted lines. They retain separate axis
meaning and work with consumers that recognize line-start Standards:/Spec:.
They are evidence fields within Evidence, not a standalone Review Record.
Missing or stale reports remain explicit limitations and do not pass the review
gate. A parser matching these labels proves only that the labels are present.

Retain essential unresolved findings and their actual dispositions, including
WARNING and BLOCKING. Preserve Step 5's recorded ACCEPTED/DEFERRED disposition
for every remaining WARNING and INFO item, including an INFO scope limitation.
Before returning a complete draft, check those fields against the protocol's
actual decision record. If a disposition is missing, return that gap to the
protocol; the formatter never invents acceptance or deferral. Link existing
durable detail when useful, with artifact/revision context. Without usable detail,
include the essentials in the body. Do not require pass counts, copied full
reports, or a new report solely for the description.
State skipped checks, absent before evidence, missing human acceptance, and
preflight limits. Carry relevant unresolved risks into Merge Danger / Submit Risk.

Description repairs that only render existing verified facts use Step 5's closed
repair list; new findings, changed claims, missing reviews, and content fixes do
not. Formatting never performs a review or grants publication permission.

## Consumer compatibility before exposure

Inventory the target project's validators and audit/report consumers before
using the new format there. Test the rendered text against available offline
interfaces or safe fixtures, preserving existing tag, ASCII, evidence, and
approval checks. Include a negative control so a silent/dead check cannot pass.
Use compatible concise wording when possible; otherwise complete required parser
updates as separately reviewed dependencies before rollout. An unknown deployed
consumer version is a stated limit, not a compatibility pass. Do not expose the
format to a consumer with an unresolved required compatibility dependency.

Run configured preflight validators normally for the actual changeset. A format
fixture or loose audit marker never proves live review, acceptance, or submit
readiness. If a consumer needs a specific review marker, retain the true result;
do not add GREEN, Approved, or a fictitious review just to silence it.
