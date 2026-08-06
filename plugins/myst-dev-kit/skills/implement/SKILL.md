---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Keep the changelist current as you go: `p4 edit`/`p4 add` every file immediately after modifying it, in a named CL.

Once done, follow the team review protocol in the `review-and-submit` skill — reviewer routing, Review Record block, preflight validators. Never submit without explicit user approval.
