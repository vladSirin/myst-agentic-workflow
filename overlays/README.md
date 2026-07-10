# overlays/

Optional content layered on top of the reusable core at install time, opt-in
via `-Overlays <names>`. **Since v4.0.0 most former overlay content ships in
the `myst-dev-kit` plugin instead** (skills/agents/commands install via the
plugin marketplace, not file-copy); what remains here is only what must be
file-copied into a consumer:

- `ue/` — UE `.p4ignore` fragment + the `unrealmcprules` rule (committed-core
  rule source). Auto-added when `*.uproject` is detected.
- `myst-project/` — Myst-only committed-core sources: `angelscriptrules`,
  the doc standards, the team creatives manual. **Never auto-added**; reference
  example for building your own project overlay.
- `afk-autonomy/` — opt-in autonomous auto-submit governance (workflow, agent
  lessons, afk-status hook script). Claude Code only; off by default.

**Retired overlays** (content now in `plugins/myst-dev-kit/`): `perforce`
(ChangelistVerification/ReviewAndSubmit are on-demand skills; P4-NOTES rides the
resolving-merge-conflicts skill), `core-local` (roundtable + setup wizard are
plugin skills). The overlay names remain accepted by old manifests but install
nothing new.

**Legacy alias**: `ue-perforce` (v1.0.0 – v1.1.0) is accepted by `init-consumer.ps1`
and expands to `perforce,ue`.

A core-only install (no overlays) must never emit Perforce/UE/Myst-specific files.

**Layout:** each overlay holds ONE shared content tree (no per-tool
`.claude/`/`.Codex/` split); the manifest maps each file to its tool targets.
