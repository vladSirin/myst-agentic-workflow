---
name: p4-description
description: "Perforce-only: draft changelist descriptions with established title tags, review evidence, and submit risk. Use for P4 CL descriptions."
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first. Required copy dependency: agentic-workflow. Confirm the target work is
Perforce, including when a Git mirror is present. For a Git target, use its Git
workflow instead. If target ownership is unclear, resolve it before formatting.
This is a local P4 formatter. Do not invoke or read the Git-only pr workflow.

## Establish the input

Use the requested CL and workspace, shelf, or submitted version, with the caller's
verified scope and evidence. A supplied capture is a snapshot, not live-state
proof. Resolve conflicting versions before treating the description as complete.
Use the project's authoritative domain terms, tracker, and evidence conventions.

Check related submitted CL history through the project's read-only tools or
usable history supplied by the caller. Begin the title with the established
[jobFamily][name] tags. Reuse the matching series/family and author convention;
do not infer the author from the current tool account. If history is missing or
conflicting, ask for it. Independent drafting may continue, but label any title
placeholders as provisional and not ready to apply.

## Draft the description

Write brief English using ASCII characters. Use this structure:

```text
[jobFamily][name] <specific title>

## Summary

<change, reason, and a small ASCII diff sketch or tree when useful>
Ticket: <existing spec/ticket or the caller's justified workflow-skip line>

## Evidence

- Before: <observed behavior and evidence, or the missing-evidence limit>
- After: <observed result and evidence, or what remains unverified>
- Review: Standards <final result>; Spec <final result or skip reason>.
  Details: <existing evidence reference when useful>
- Not verified: <remaining checks or human acceptance, when applicable>

## Submit Risk

Reversibility: <how to undo the change and any limit>
Impact: <affected behavior, data, assets, or consumers; remaining risks>
```

Keep the ticket/source pointer or justified skip. If it is missing, request it
and label the draft incomplete; never invent a ticket or approved workflow skip.
If an authoritative name/path contains non-ASCII characters, use an existing
ASCII identifier or evidence alias when available. Otherwise report that limit
outside the provisional draft and request an accurate reference; do not silently
change identifiers or invent a transliteration that looks like a real path.
Link screenshots/logs through project evidence references. Use plain text rather
than relying on Mermaid, images, or HTML rendering in a CL description.

Use only actual supplied results for the same CL version and scope. Missing,
stale, mismatched, or unverified review evidence is not GREEN. State the reason
for skipped axes. Preserve WARNING/BLOCKING verdicts, stable finding anchors,
and actual dispositions. Link existing durable detail with its source/revision
context; if usable detail is absent, retain essential unresolved findings and
their known disposition briefly in Evidence. Include docs-alignment results or
limits where relevant. State missing human acceptance explicitly. Never turn a
proposed test or absent before capture into a passed or failed execution.

Describe blockers and acceptance gaps in Submit Risk when relevant. Distinguish
reverting code from restoring data or assets; do not promise that a destructive
change is fully reversible. Do not add a separate Review Record, require review
pass counts, or create a new report solely for this format.

## Return the draft

Return description text for inspection. Formatting does not run reviews, resolve
findings, edit the CL, shelve, or submit. Review-and-submit owns review execution,
finding handling, preflight, and publication approval. Its current description
format remains until its separate migration lands. Applying a draft is a separate
action under that protocol and the user's authority.
