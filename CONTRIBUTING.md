# Contributing

The marketplace ships to every teammate's sessions, so content enters it through
a **per-skill contribution gate**: one skill per PR, reviewed before it lands.
The unit of review is the unit of installation.

## The gate, end to end

1. **Author where you'll use it.** Write or improve the skill in your consumer
   project first (personal-scope `.claude/skills/...`) and dogfood it in real
   sessions before proposing it.
2. **Port it into the package tree by hand.** Copy the skill directory into
   `plugins/myst-dev-kit/skills/<name>/` and strip anything project-specific —
   the repo ships only project-agnostic content; project specifics live in the
   consuming project's own committed docs and rules. Stack-specific but
   reusable (Perforce command forms, UE debugging) counts as agnostic.
3. **One skill per PR.** Branch, commit, open a PR against `main`. Multi-skill
   PRs get asked to split — a reviewer must be able to hold the whole change.
4. **Pass the mechanical bar.** CI (`.github/workflows/tests.yml`) runs the
   PowerShell 5.1 parse gate, the ASCII/BOM gate, and the lint job (SKILL.md
   frontmatter validity, version agreement across the two manifests, README
   install one-liners present, dead-reference grep). Run
   `claude plugin validate ./plugins/myst-dev-kit` and
   `claude plugin validate .` locally before pushing.
5. **Pass the review bar** — the reviewer (project lead, or anyone with
   believability on the topic) checks the checklist below and approves.
   Fix-and-re-push until green.
6. **Version bump on merge** (see Versioning below). Then **push the tag and
   the release publishes itself** — `.github/workflows/release.yml` turns every
   `v*` tag into a GitHub Release with that version's CHANGELOG section as the
   body.
7. Consumers receive it on their next plugin update (Claude/Codex) or
   `npx skills add` re-run.

## Per-skill review checklist

- [ ] **Frontmatter**: valid YAML (quote any description containing `: `),
      kebab-case `name` matching the directory, `description` written as a
      TRIGGER ("use when...", "MANDATORY before...") — it's the only part the
      model sees before deciding to load the skill.
- [ ] **Genericity**: no project-specific paths or names; protocols state the
      neutral rule and may carry per-VCS command forms (Perforce and git).
- [ ] **Provenance**: vendored upstream content (see the skill's PROVENANCE.md)
      stays verbatim and keeps its attribution; local additions go in same-dir
      reference files, never in upstream's files. Re-vendoring replaces the
      skill wholesale from upstream and updates the note.
- [ ] **No hidden authority**: skills that touch version control state the
      submission-authority rule (reviewers never submit; agents never publish
      shared state without the protocol).
- [ ] **Advisory posture**: nothing in a skill may hard-block a human.
- [ ] **Size**: a skill the model loads on demand should earn its tokens —
      prefer one tight SKILL.md + reference files over a monolith.

## Versioning

Rules live at the top of [CHANGELOG.md](CHANGELOG.md). The short version:

- **MAJOR** only when an existing install breaks or needs manual migration.
  **Retiring a skill is MINOR for plugin consumers** — the plugin directory is
  replaced wholesale on update; copy-install (`npx skills add`) consumers
  self-manage removal, which is inherent to the npx model.
- **One bump per merge to `main`**, not per commit and not per PR in a stack.
- **Tag it or don't bump it.** An untagged bump is a string in a JSON file.
- The number lives in **two** places — `plugins/myst-dev-kit/.claude-plugin/plugin.json`
  and `plugins/myst-dev-kit/.codex-plugin/plugin.json`. `./bump.ps1` updates
  both, checks the CHANGELOG section exists, and tags.

## Larger changes

New tool support, or a change to a protocol skill's trigger contract: open an
issue first and get the shape agreed before writing code.
