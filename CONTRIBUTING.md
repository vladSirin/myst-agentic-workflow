# Contributing

The marketplace ships to every teammate's sessions, so content enters it through
a **per-skill contribution gate**: one skill per PR, reviewed before it lands.
The unit of review is the unit of installation.

The one-time [migration exception](#upstream-boundary-migration-exception)
closed when [PR #107](https://github.com/vladSirin/myst-agentic-workflow/pull/107)
merged on 2026-10-10. Each skill retains its own review evidence. Later skill
contributions use the normal one-skill PR gate, except for the bounded
[Codex display-label follow-up](#codex-display-label-follow-up) below.

## The gate, end to end

1. **Author local behavior where you'll use it.** Write or improve the skill in your consumer
   project first (personal-scope `.claude/skills/...`) and dogfood it in real
   sessions before proposing it.
2. **Keep source and local integration separate.** Import the complete selected
   upstream skill at a recorded revision, unchanged in bytes. The sole packaged
   filename exception, SKILL.md to UPSTREAM.md, is defined in
   [ADR-0009](docs/adr-0009-plain-upstream-references.md). Put Myst behavior in its
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
   install one-liners present, default Codex display naming, dead-reference grep).
   The upstream-source job
   also runs source-verifier acceptance tests and independent pinned-source
   verification; PRs targeting main require complete source records. Run
   `claude plugin validate ./plugins/myst-dev-kit` and
   `claude plugin validate .` locally before pushing.
5. **Pass the review bar** — the reviewer (project lead, or anyone with
   believability on the topic) checks the checklist below and approves.
   Fix-and-re-push until green.
6. **Version bump on merge** (see Versioning below). With the owner's release
   approval, **push the tag and the release publishes itself** —
   `.github/workflows/release.yml` turns every
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
- [ ] **Codex menu label**: omit interface.display_name from public
      agents/openai.yaml so Codex formats the namespaced skill name. Retain
      invocation policy, short descriptions, and other needed host metadata. The
      CI gate checks public metadata only; archived upstream metadata stays intact.
- [ ] **Local genericity**: no project-specific paths or names; protocols state the
      neutral rule and may carry per-VCS command forms (Perforce and git).
- [ ] **Source and provenance**: preserve complete selected upstream files and
      attribution. Migrated imports have UPSTREAM.json for source identity and
      file records, plus PROVENANCE.md for ownership and local adaptations.
      All current imports carry these records; [LICENSE](LICENSE) retains
      attribution and the inventory links acceptance evidence. Replace only the source
      bundle when re-vendoring, preserving local files. Follow
      [ADR-0008](docs/adr-0008-strict-upstream-boundary.md) and its narrow
      [packaging amendment](docs/adr-0009-plain-upstream-references.md).
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

**Closed on 2026-10-10 by PR #107.** The migration branch has been removed.
The following scope is the historical exception, not a route for new work.

This one-time exception covered only the final integration PR from
`codex/upstream-boundary-refresh` to main for the owner's approved
[refresh plan](docs/plan_upstream_boundary_refresh.md). The
[inventory](docs/migration-upstream-boundary.md) links the completed per-skill
reviews and owner gates. This final PR is the sole multi-skill migration exception; it
does not replace those reviews.

The candidate prepares one version bump in both manifests and one CHANGELOG
section. There are no intermediate migration tags. Required consumer parser
compatibility must be ready before exposure. Candidate review, preflight and
explicit publication decisions still apply. Deferred tests stay unverified.

The final integration PR is merged, so the exception is closed. Later
skill contributions follow the normal one-skill PR process against main, with
the separate display-label follow-up below limited to cosmetic metadata. Do not use
the migration branch for further contributions. Any later migration needs its
own decision. Merge alone does not prove runtime or consumer acceptance, and
tagging remains a separate release decision.

## Codex display-label follow-up

On 2026-10-10, the owner requested consistent Myst labels and a repository push.
On 2026-10-11, the owner rejected duplicated prefixes and requested the host
default. This one follow-up may omit public display_name overrides, remove the
four display-only files, correct provenance and preview docs, and add the CI
gate for that policy. It changes no skill method, command name, trigger, or
invocation policy and does not reopen the migration exception. Later skill
changes still use one skill per PR. Scope and checks:
[follow-up task](.scratch/upstream-boundary-refresh/issues/41-preview-docs-menu-labels.md).

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
- **Tag it or don't bump it** is the normal release rule. A manifest bump
  alone is not a published release.
- **Owner-approved 5.5 preview exception**: main carries 5.5.0 for daily-use
  testing. The owner will give a separate instruction to tag and release it.
  Keep its notes marked Unreleased. Status, documentation, and display-label follow-ups extend
  that preview; do not add another bump or tag for them. See the
  [current release gate](docs/upstream-release-candidate-2026-10-09.md#current-status---2026-10-10).
- The number lives in **two** places — `plugins/myst-dev-kit/.claude-plugin/plugin.json`
  and `plugins/myst-dev-kit/.codex-plugin/plugin.json`. `./bump.ps1` updates
  both, checks the CHANGELOG section exists, and tags.

## Larger changes

New tool support, or a change to a protocol skill's trigger contract: open an
issue first and get the shape agreed before writing code.
