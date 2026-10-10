# Implement wrapper migration

Changeset 4, based on local commit 5b3b1f3. Source and runtime checks are complete;
independent migration reviews are recorded below. Owner verification is required
before the next skill migration. No publication is authorized.

## Upstream comparison

Compare the historical Matt pin recorded in LICENSE,
0ab1b63a410a03d3627979a109c8695de27af954, with the approved new pin,
6fd947921b935b7e1e69293a200400f0fdd5c15f. Both complete implement subtrees contain
SKILL.md and agents/openai.yaml. The metadata is byte-identical across those pins.
The only source-text changes are explicit Skill-tool calls in place of slash
references:

```diff
-Use /tdd where possible, at pre-agreed seams.
+Call the Skill tool with "tdd" where possible, at pre-agreed seams.

-Once done, use /code-review to review the work.
+Once done, call the Skill tool with "code-review" to review the work.
```

The specification, regular checks, final suite, and current-branch commit
instructions are unchanged. This is upstream-to-upstream evidence, separate
from the local changes below. The old archive and full diff are retained in
the disposable evidence directory. The new complete subtree is in upstream.zip;
UPSTREAM.json records each original file hash. Independent Git acquisition
verified the bundled bytes against the approved pin.

## Local integration comparison

Previously, Myst's public SKILL.md held the implementation method inline. It
used `/tdd`, replaced upstream review with review-and-submit, and retained an
unqualified Git commit instruction. Original Codex metadata was absent locally.

Now the public entry loads agentic-workflow's shared contract and unchanged
source. It maps TDD to Myst tdd and review to the existing review-and-submit
coordinator, whose engine is myst-dev-kit:code-review. Copy installs declare
those four sibling dependencies and check their availability before implementation.
The project owns tracker paths and completion states. Git commits remain within
user authorization; a Perforce target uses its changelist workflow even when a
nested Git mirror exists. The public metadata keeps explicit user invocation.

The method and original metadata remain intact inside the ZIP. Myst owns the
wrapper, public metadata, source record, and provenance with the full MIT notice.
This changeset does not migrate TDD or code-review, retire Review Record, add
orchestration, or change any consumer project.

## Runtime checks

Codex CLI 0.160.1 with gpt-5.5 and medium reasoning ran fresh ephemeral sessions
against three disposable fixtures. Each used the actual new implement package
and its available project-local dependencies. A competing non-Myst code-review
entry was present. The prompts requested explicit local implement invocation.

| Case | Observed result |
| --- | --- |
| Bounded Git implementation | Loaded the wrapper, shared contract, source ZIP, Myst TDD, review-and-submit, and Myst code-review. Added a zero-value regression at the approved public seam; observed red before the fix, green after, and a passing full suite. Standards and Spec review results were GREEN at completion. |
| Completion and authority | Only the implementation, its test, and ticket changed. Ticket is resolved with owner acceptance outstanding. Git HEAD is unchanged; no commit, push, PR, or ticket closure occurred. |
| Missing copy dependencies | Missing local tdd and code-review were reported. Execution stopped before implementation, with no input-file changes or fallback to the competing/global entries. |
| Perforce target with real nested Git repository | Read-only preflight kept Perforce ownership, selected the Markdown tracker and Myst dependency paths, and rejected applying the upstream Git commit instruction to the target. Input files were unchanged; no Perforce server was contacted. |

The Git task used the public get_retry_count(settings) seam. The regression
asserted that configured zero stays zero; missing and positive values retained
their expected behavior. Actual commands:

```text
python -m unittest tests.test_settings.RetryTests.test_zero_is_preserved -v
python -m unittest discover -s tests -v
```

The focused test first failed with `AssertionError: 3 != 0`. It later passed;
the final suite passed three tests. No type checker was configured, and the
runtime correctly reported that limitation rather than claiming type-check proof.
The fixture's Spec review initially questioned the ticket's completion state.
It was re-reviewed with the explicit tracker rule requiring owner acceptance;
the final result remained resolved, not closed.

The initial Git fixture setup failed Windows ownership checks. Its prematurely
started runtime was stopped; baseline hashes confirmed no input changes. The
fixture was then seeded successfully using trust scoped to exact fixture paths.
The final runs used process-scoped Git trust, not a global configuration change.
Only the completed runs in the table count as runtime evidence.

The P4 case proves routing and the commit restriction in a synthetic preflight.
It does not prove real P4 checkout, changelist review, or submission. The competing
entry is a fixture skill, not an installation of another review plugin. Claude
runtime remains deferred until the owner reports that it works. Existing host
invocation limits from the handoff pilot still apply; source equality is not
cross-host execution proof.

## Repository validation

- Independent source verifier passed for two migrated bundles, with 23 declared
  pending imports and four local skills.
- All 19 verifier acceptance tests passed.
- Existing CI checks passed: PowerShell 5.1 parsing, ASCII/BOM, public entry
  frontmatter, manifest version agreement, README install commands, dead references.
- git diff --check passed. The implement package contains one loose SKILL.md;
  original source and metadata are complete inside the ZIP.

## Independent migration review

Final reviews against baseline 5b3b1f3: Standards GREEN; Spec GREEN. Neither
review found an actionable defect. These reviews are separate from those
executed inside the implementation fixture. Owner verification remains required
before the next migration; no publication is authorized.

## Evidence location

Disposable root: `%TEMP%/myst-implement-migration-20261007`.
It contains upstream.diff, old-upstream.zip, run.py, and verification.json.
Each case has prompt.txt, baseline.json, trace.jsonl, final.md, and run.json.
Git fixtures also have base.txt. The runner used `codex exec --ephemeral --json
--skip-git-repo-check --sandbox workspace-write` with an explicit gpt-5.5 model
and medium reasoning setting. Actual source, spec, tests, and ticket remain in
the fixture. Temporary evidence can expire; this report retains bounded results.

| Completed trace | SHA-256 |
| --- | --- |
| git/trace.jsonl | 9ae44d6fe14c921873e4d7176232bd77557a9ea8e3071561a123dfc5b5d10e1e |
| missing/trace.jsonl | 7944bea0c07a9a1b4aa4815c5e69ac55e975016326e4c1934f4029c59978ad18 |
| p4/trace.jsonl | 1a508a48b7f45cefa54141eebeef23785d820d48e2c3725507dc789c1494fd1a |
