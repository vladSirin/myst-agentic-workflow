# Contributing

The marketplace ships to every teammate's sessions, so content enters it through
a **per-skill contribution gate**: one skill per PR, reviewed before it lands.
The unit of review is the unit of installation.

During the upstream-boundary refresh, use the temporary
[migration exception](#upstream-boundary-migration-exception) below. It changes
PR targets and release timing; each skill still has its own review gate.

## The gate, end to end

1. **Author local behavior where you'll use it.** Write or improve the skill in your consumer
   project first (personal-scope `.claude/skills/...`) and dogfood it in real
   sessions before proposing it.
2. **Keep source and local integration separate.** Import the complete selected
   upstream skill at a recorded revision, unchanged. Put Myst behavior in its
   local entry point and references. For local-origin content, remove project
   specifics; those belong in the consuming project's docs. Stack-specific but
   reusable content (Perforce command forms, UE debugging) counts as agnostic.
   If an upstream skill cannot be used within that boundary, record an explicit
   exclusion instead of stripping or rewriting its source. The packaging pilot
   and current migration debt are in the
   [inventory](docs/migration-upstream-boundary.md).
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

- [ ] **Local entry frontmatter**: valid YAML (quote any description containing `: `),
      kebab-case `name` matching the directory, `description` written as a
      TRIGGER ("use when...", "MANDATORY before...") — it's the only part the
      model sees before deciding to load the skill. Apply these rules to the
      Myst entry point; preserve upstream frontmatter and host metadata intact.
- [ ] **Local genericity**: no project-specific paths or names; protocols state the
      neutral rule and may carry per-VCS command forms (Perforce and git).
- [ ] **Source and provenance**: preserve complete selected upstream files and
      attribution. Migrated imports have UPSTREAM.json for source identity and
      file records, plus PROVENANCE.md for ownership and local adaptations.
      Historical imports still use [LICENSE](LICENSE) and existing provenance;
      the inventory names their pending migration. Replace only the source
      bundle when re-vendoring, preserving local files. Follow
      [ADR-0008](docs/adr-0008-strict-upstream-boundary.md).
- [ ] **Loading and integrity**: provide source comparison evidence and a
      working entry-to-source/reference path. Run `python tools/verify_upstream.py`
      using the [source-record contract](docs/upstream-source-verification.md).
      Remove the skill's pending waiver when adding its source record. A skill's
      wrapper, bundle, provenance, catalog row, and evidence belong in its PR.
- [ ] **No hidden authority**: local entry points that touch version control must state or load the
      submission-authority rule (reviewers never submit; agents never publish
      shared state without the protocol). Keep this rule outside upstream files.
- [ ] **Advisory posture**: nothing in a skill may hard-block a human.
- [ ] **Size**: a skill the model loads on demand should earn its tokens —
      keep local entries tight and disclose references when needed. Preserve
      upstream files whole rather than shortening them to meet local style.
- [ ] **Catalog row**: the README's skills catalog gains (or updates) the
      skill's one-line entry — right category, and under the invocation type
      matching its public entry's frontmatter (`disable-model-invocation: true` ⇒
      User-invoked). Retiring a skill removes its row in the same PR. State
      source ownership, VCS limits, and migration status accurately; source
      equality alone does not prove identical runtime behavior.

## Upstream-boundary migration exception

This one-time exception implements the owner's approved
[refresh plan](docs/plan_upstream_boundary_refresh.md).

- Target `codex/upstream-boundary-refresh` for each skill PR and for related
  infrastructure/documentation PRs. Keep one skill per PR and obtain user
  verification before starting the next changeset. Existing CI runs on this
  branch as well as main.
- Do not bump versions or tag intermediate migration merges. The normal
  consumer update path stays on the current main release.
- After full acceptance, open one final integration PR from the migration
  branch to main. This final PR is the sole multi-skill exception: link each
  completed review and check combined compatibility. It does not replace the
  per-skill reviews.
- Prepare one version bump across both manifests and the corresponding
  CHANGELOG section for that final merge. Merge and tagging retain the existing
  publication protocol and approval requirements. Required consumer parser
  compatibility must be ready before the new format reaches main.
- After final integration, close this exception and resume the normal
  main-target contribution process. Any later migration needs its own decision.

The migration inventory lists pending work; a branch merge alone does not prove
source integrity, runtime loading, or consumer acceptance.

## Versioning

Rules live at the top of [CHANGELOG.md](CHANGELOG.md). The short version:

- **MAJOR** only when an existing install breaks or needs manual migration.
  **Retiring a skill is MINOR for plugin consumers** — the plugin directory is
  replaced wholesale on update; copy-install (`npx skills add`) consumers
  self-manage removal, which is inherent to the npx model.
- **Copy-install cleanup**: release instructions identify obsolete Myst-owned
  folders for both upgrade and rollback. Preserve personal edits outside skill
  discovery before removal, leave unrelated copies alone, and check the final
  discoverable catalog. Do not rely on re-running add to remove retired skills.
  This is documented cleanup, not an automatic deletion service.
- **One bump per merge to `main`**, not per commit and not per PR in a stack.
- **Tag it or don't bump it.** An untagged bump is a string in a JSON file.
- The number lives in **two** places — `plugins/myst-dev-kit/.claude-plugin/plugin.json`
  and `plugins/myst-dev-kit/.codex-plugin/plugin.json`. `./bump.ps1` updates
  both, checks the CHANGELOG section exists, and tags.

## Larger changes

New tool support, or a change to a protocol skill's trigger contract: open an
issue first and get the shape agreed before writing code.
