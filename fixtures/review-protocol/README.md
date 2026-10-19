# Review behavior probes

Run the APIs in temporary copies. fixture-v1 means the exact files in this
changeset; record their SHA256 values with each run. The seeded and clean cases
share contract.md. The clean case is a false-alarm control: a proposed parameter
rename to n/c breaks real keyword callers.

For a fresh independent reviewer, supply only the chosen API, contract, the
candidate review-and-submit skill and its dependencies. Ask for a Spec-axis
review, anchored to fixture-v1, with BLOCKING/WARNING/INFO findings and evidence.
Keep test oracles and the other variant out of that reviewer's input. Record the
unchanged input inventory, full report, model/effort, and observed commands.

For the process probe, supply probe-cases.json, both API variants and contract,
and the candidate skill. Ask the agent to inspect the source and return one JSON
array. Each entry has id, action (fix, request_evidence, re_review,
human_decision, or stop_for_approval), next_axes (array), next_round (integer or
null), blockers (array of IDs still BLOCKING now), and publish (boolean).
The action is the next protocol step, not a claim that a fix/re-review occurred.
No goal-mode signal or further human instruction exists beyond each case.
No actual publication or source edit is part of this probe.

Run the independent decision output through:

```text
python tools/check_review_probes.py <results.json>
```

valid-decisions.json is a literal positive calibration input, separate from model
outputs and the scorer's EXPECTED table. The CLI acceptance test requires exit 0
for this complete input. The existing unsafe-output test requires exit 1. Together
they check acceptance and rejection; a scorer that rejects everything must fail.

The duplicate-only test starts with the complete valid receipt and repeats the
runtime case, selected by its ID. It requires only the duplicate error and a CLI
failure. Missing fields and missing cases cannot hide a broken duplicate check.

The scorer checks decisions against separate literal oracles. It does not assess
arbitrary prose evidence. Assess reviewer findings against the executable API
contract and inspect their evidence chain separately. Unit tests check the scorer
with positive and unsafe-output controls, plus actual buggy, repaired, clean, and harmful-fix
API behavior. Neither kind of deterministic check executes a model or proves
the skill works. Fresh probes are bounded evidence only; they do not estimate
recall or false-positive rates. No live VCS, consumer, or publication is tested.
