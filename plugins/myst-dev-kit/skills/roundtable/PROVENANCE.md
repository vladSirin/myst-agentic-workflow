# Roundtable provenance

The complete source comes from [Hammer](https://github.com/dreamwords/hammer-releases).
[UPSTREAM.json](UPSTREAM.json) owns the current approved release, asset identity,
archive hash, subtree, and complete source inventory. The single original file
stays byte-for-byte intact under references/upstream; only SKILL.md maps to
UPSTREAM.md under ADR-0009. The author credit and revision date remain in it.

Myst owns this note, the source record, public English frontmatter, and display
metadata. Model invocation and argument hint remain as before. The entry only
loads the complete source; no method rule or workflow dependency is added.
The Chinese upstream description is preserved. Display metadata is local because
Hammer has no agents/openai.yaml in this skill subtree.

## History and ownership

The prior import came from Hammer v0.19.0 on 2026-08-27. It credited Li Jigang
and the 2025-11-12 revision in the body. The original roundtable files at v0.19.0
and the approved v0.30.0 release are byte-identical. The former Myst body matches
after removing frontmatter and normalizing line endings. There is no method delta.
The previous public entry combined Myst frontmatter with the body; that split is
now explicit. An earlier Myst English adaptation lacked the credit. The imported
revision restored it and retained simulated-speech honesty, lightweight MBTI,
free-form input, and no org-file archiving. All of these remain upstream.

Re-vendoring replaces only the complete source subtree and source record after
source comparison. Preserve the local entry, metadata, this permission record,
and credits. Follow ADR-0008/0009; never splice local rules into the source.

## Existing authorization

License note: upstream ships no public license for this content. Vendoring and
redistribution here are authorized by the project owner (sxc, 2026-08-27), who
holds the relationship with the app team and its authors; re-vendoring rides the
same authorization.
