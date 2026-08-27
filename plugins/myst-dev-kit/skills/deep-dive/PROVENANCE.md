# Provenance

Vendored from the Hammer desktop app: github.com/dreamwords/hammer-releases,
release v0.19.0 (2026-08-27). Author: 卡兹克 (credited in the body and the
release notes). The app's source repo is private; the releases repo ships
binaries only, so the pin is the release tag plus the bundle path:

`Hammer-0.19.0-mac.zip :: Hammer.app/Contents/Resources/advanced-capabilities/deep-dive/SKILL.md`

VERBATIM: everything below the frontmatter. LOCAL: the frontmatter block only —
trigger-grade English description, `disable-model-invocation: true` (Hammer fires
this capability only via the explicit prefix `深挖一下：`; mirrored here as
user-invoked), and `argument-hint`. Upstream's own frontmatter carried a Chinese
summary description and no invocation marker.

Re-vendoring = download the newest release zip, extract the same bundle path,
replace everything below the frontmatter wholesale, update this note. Keep the
local frontmatter unless upstream's gains trigger semantics.

License note: upstream ships no public license for this content. Vendoring and
redistribution here are authorized by the project owner (sxc, 2026-08-27), who
holds the relationship with the app team and its authors; re-vendoring rides the
same authorization.
