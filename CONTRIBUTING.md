# Contributing

The marketplace ships to every teammate's sessions, so content enters it through
a **per-skill contribution gate**: one skill (or agent/command/hook) per PR,
reviewed before it lands. The unit of review is the unit of installation.

## The gate, end to end

1. **Author where you'll use it.** Write or improve the skill in your consumer
   project first (`.claude/skills/...` locally, or straight in a package branch
   if it's package-native). Dogfood it in real sessions before proposing it.
2. **Promote it into the package working tree:**
   ```powershell
   ./promote.ps1 -TargetRoot c:/path/to/your-project -Paths '<file>'
   ```
   `promote.ps1` classifies the change, reverse-substitutes project values back
   to `{{var}}` placeholders, roundtrip-verifies, and writes into the package
   tree (shared source: `plugins/myst-dev-kit/...`).
3. **One skill per PR.** Branch, commit, open a PR against `main`. Multi-skill
   PRs get asked to split — a reviewer must be able to hold the whole change.
4. **Pass the mechanical bar.** CI (`.github/workflows/tests.yml`) runs every
   `scripts/run-*-tests.ps1` suite plus the PowerShell 5.1 gates on each PR and
   push to `main` -- a red run blocks the merge. Run the same checks locally
   before pushing:
   ```powershell
   claude plugin validate ./plugins/myst-dev-kit     # frontmatter, structure
   claude plugin validate .                          # marketplace manifest
   ./scripts/run-marketplace-tests.ps1               # 4-manifest lockstep etc.
   ./scripts/run-linkcheck-tests.ps1                 # no dangling references
   ./scripts/run-p4spec-tests.ps1                    # installer CL spec: no Files:, no BOM
   ```
5. **Pass the review bar** — the reviewer (project lead, or anyone with
   believability on the topic) checks the [checklist](#per-skill-review-checklist)
   below and approves. Fix-and-re-push until green.
6. **Version bump on merge**: skill added or changed compatibly → MINOR;
   anything that breaks consumers (renamed skill, changed trigger contract,
   removed content) → MAJOR. Bump all **five** version sites — `package-manifest.json`,
   both `plugin.json` files, the plugin entry in `.claude-plugin/marketplace.json`
   (the marketplace entry version **pins updates**: forget it and consumers never
   receive the release; `run-marketplace-tests.ps1` fails the lockstep check for you),
   and the README version badge (CI asserts the badge against the tree).
7. Teammates receive it on their next plugin update — no Perforce interaction.

## Per-skill review checklist

- [ ] **Frontmatter**: valid YAML (quote any description containing `: `),
      kebab-case `name` matching the directory, `description` written as a
      TRIGGER ("use when...", "MANDATORY before...") — it's the only part the
      model sees before deciding to load the skill.
- [ ] **Genericity**: core skills carry no project-specific paths or names;
      project specifics use `{{var}}` placeholders or live in a clearly
      project-scoped skill.
- [ ] **Provenance**: upstream-derived content (mattpocock/skills) stays
      byte-faithful and keeps the MIT attribution; local-origin content must
      not collide with an upstream skill name (re-vendor safety).
- [ ] **No hidden authority**: skills that touch version control state the
      submission-authority rule (reviewers never submit; agents never push
      shared state without the protocol).
- [ ] **Advisory posture**: nothing in a skill may hard-block a human; the
      server-side Submit-Audit is the accountability backstop.
- [ ] **Size**: a skill the model loads on demand should earn its tokens —
      prefer one tight SKILL.md + reference files over a monolith.

## Review capability without agents (Codex)

Reviewer subagents (`architecture-reviewer`, `radical-design-critic`) are
Claude-only. Codex sessions -- and the `review-and-submit` fast path, in any
session -- perform reviews inline via the **`review-changes`
skill**, which loads the same two rubric files from the plugin's `agents/` dir
and ends with the same parseable `Verdict:` line. Inline self-review is the
floor, not the ceiling — risky CLs over the Submit-Audit thresholds deserve an
independent reviewer.

## Versioning

Rules live at the top of [CHANGELOG.md](CHANGELOG.md). The short version:

- **MAJOR** only when an existing install breaks or needs manual migration. Retiring a
  skill or rule is **MINOR** — `upgrade.ps1` handles it.
- **One bump per merge to `main`**, not per commit and not per PR in a stack.
- **Tag it or don't bump it.** An untagged bump is a string in a JSON file.
- The number lives in **five** places (four manifests + the README badge) — change them
  together.

## Larger changes

New overlay, new tool support, manifest schema bump, hook changes: open an
issue first and get the shape agreed before writing code. Hooks in particular
run on every teammate's machine — they get the strictest review.
