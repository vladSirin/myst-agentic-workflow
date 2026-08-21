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
   Then **push the tag and the release publishes itself** —
   `.github/workflows/release.yml` turns every `v*` tag into a GitHub Release with
   that version's CHANGELOG section as the body.
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
- [ ] **Verbatim by default** ([ADR-0006](docs/adr-0006-verbatim-by-default-and-the-divergence-ledger.md)):
      any change to vendored content needs a written necessity rationale, a
      reviewer pass, and owner confirmation, recorded in the release's
      divergence ledger. Preference is not necessity — if the honest reason is
      preference, take upstream's version.

## Upstream sync checklist (every release, and monthly)

- [ ] `pwsh scripts/check-mattpocock-updates.ps1` — run it **at every release
      and at least monthly**. The v4.43.0 re-vendor found the pin 141 commits
      behind because nothing ran the detector between syncs.
- [ ] `pwsh scripts/vendored-hashes.ps1 -Verify` — every vendored file still
      matches its recorded hash. After a re-vendor, `-Update` regenerates it
      and refuses undeclared divergences.
- [ ] Dangling-ref guard — every hit must be a ledgered divergence, and the
      pattern grows when a new skill is rejected:

      git grep -nE "setup-matt-pocock-skills|code-review|ask-matt" plugins/myst-dev-kit/skills/

- [ ] Enumerate divergences **by grep, never by hand** — three review passes
      over the v4.43.0 plan each mis-enumerated the set by reading.
- [ ] **No hidden authority**: skills that touch version control state the
      submission-authority rule (reviewers never submit; agents never push
      shared state without the protocol).
- [ ] **Advisory posture**: nothing in a skill may hard-block a human; the
      server-side Submit-Audit is the accountability backstop.
- [ ] **Size**: a skill the model loads on demand should earn its tokens —
      prefer one tight SKILL.md + reference files over a monolith.

## Review capability without agents

Reviewer subagents (`architecture-reviewer`, `radical-design-critic`) run natively
under Claude, and as `setup-devkit.ps1`-generated read-only variants under Codex
(TOML) and OpenCode. Sessions without them installed -- and the
`review-and-submit` fast path, in any session -- perform reviews inline via the
**`review-changes` skill**, which loads the same two rubric files from the
plugin's `agents/` dir and ends with the same parseable `Verdict:` line. Inline
self-review is the floor, not the ceiling — risky CLs over the Submit-Audit
thresholds deserve an independent reviewer.

## Versioning

Rules live at the top of [CHANGELOG.md](CHANGELOG.md). The short version:

- **MAJOR** only when an existing install breaks or needs manual migration. Retiring a
  skill or rule is **MINOR** — `upgrade.ps1` handles it. The same install-break test
  decides renames: gate-step 6's "renamed skill → MAJOR" is about consumer-facing
  trigger contracts; renaming a **maintainer-only command** with no committed consumer
  references breaks no install and ships as MINOR (precedent:
  `/update-myst-skills` → `/update-project-scaffold`, v4.41.0).
- **One bump per merge to `main`**, not per commit and not per PR in a stack.
- **Tag it or don't bump it.** An untagged bump is a string in a JSON file.
- The number lives in **five** places (four manifests + the README badge) — change them
  together.

## Larger changes

New overlay, new tool support, manifest schema bump, hook changes: open an
issue first and get the shape agreed before writing code. Hooks in particular
run on every teammate's machine — they get the strictest review.
