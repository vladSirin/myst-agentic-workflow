# Align preview documentation and restore default Codex labels

Type: task
Status: resolved

Owner scope on 2026-10-10: update stale documents and README, make Myst labels
consistent, and push the follow-up. On 2026-10-11 the owner rejected the explicit
prefix approach: "So this PR is totally wrong, we need to fix in another way?
if so revert and work on the real durable soltuion."

Keep the valid documentation closeout for PR #107, CL 4089, the PC upgrade and
fixture cleanup. Keep 5.5.0 an unreleased daily-use preview. Its tag and release
still need a later owner request. Preserve the original dated acceptance checks.

Replace PR #108's explicit labels with default Codex naming. Omit only the local
interface.display_name field from the 27 existing agents/openai.yaml files.
Remove the four files added only for labels; those skills used the host default
before this PR. Keep all other existing metadata byte-for-byte, including
allow_implicit_invocation: false, descriptions and dependencies. Keep SKILL.md,
command names, source records, archived files and skill methods unchanged.
Correct provenance to state that only the local display_name field is omitted.

Add a small CI gate over public agents/openai.yaml paths so later imports cannot
restore overrides by mistake. Do not scan or alter references/upstream. Exercise
the actual gate with a passing package and failing explicit-label controls.

Refresh the PC through the normal installer and check fresh CLI/desktop catalogs
for both example projects. Verify the default renderer and unchanged catalog
identity, routing and dependencies. Check OpenCode discovery with an isolated
copy fixture; it uses its own skill names, not the Codex prefix. No new alias,
OpenCode host configuration or model runtime is required for this metadata fix.
Claude model tests remain deferred. Re-review the final PR diff, push the revision
and replace the PR description with its actual results. Do not merge or release.

The earlier 9bc2d1f prefix revision and its 192-file install evidence are
superseded. Those receipts remain outside discovery as history; they do not
verify this replacement. New checks and review results belong to the revised PR.

Verification on 2026-10-11: only display_name was removed from 27 existing metadata
files; the four files added only for labels are absent. All 31 SKILL.md entries,
all other metadata fields and all 69 archived source files match the main base.
The source verifier and both Claude static plugin validators pass. The actual CI
gate passes the package and rejects bare, prefixed, quoted and flow-style override
controls; archived metadata is excluded.

Four fresh Codex catalogs (CLI and desktop, Git and UE example projects) each load
31 skills with unchanged identities, routing and dependencies. The installed
desktop renderer generates a Myst Dev Kit prefix for every entry. The normal
Codex installer matches all 188 package files to this source. OpenCode 1.18.31
discovers all 31 canonical names in an isolated copy fixture. These checks made
no model requests. Check PR #108 for final reviews and CI results.

Outstanding: fresh visible-menu acceptance by the owner and 5.5 daily-use
acceptance remain separate from catalog and renderer checks. Release decisions
remain in task 40. Do not pre-record them as complete.
