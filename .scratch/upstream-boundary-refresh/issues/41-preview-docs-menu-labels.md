# Align preview documentation and Codex menu labels

Type: task
Status: resolved

Owner scope on 2026-10-10: update documents and README that are out of date.
After the mixed Codex menu labels were explained, the owner said:
"ofc we need to make them consistnet and push to our repo if needed."

Bring the release-status documents up to date with PR #107 merged, CL 4089
submitted, the PC packages refreshed, and task fixtures retired. Keep 5.5.0
marked as an unreleased daily-use preview; tagging needs a later owner request.
Retain the original dated acceptance evidence as history and preserve its limits.

Give all 31 public Codex skill entries the display label
Myst Dev Kit: <existing skill title>. Add local display metadata for the four
entries that previously relied on a generated label. Keep all SKILL.md files,
command names, triggers, invocation policies, dependencies, source records,
and archived upstream files unchanged. Correct only provenance claims invalidated
by the local display-name prefix. Record this bounded cosmetic exception to the
one-skill PR rule; the normal rule remains in force for later skill changes.

Check the 31 metadata entries, compare all non-display metadata to the base,
verify the pinned source, and check documentation links and release headings.
Use a fresh native Codex catalog to confirm labels and Myst wrapper paths.
Catalog evidence does not prove model runtime or the visible menu in an existing
session. Claude model tests remain deferred. Review the exact diff, push the
follow-up branch, and open a PR; do not merge, tag, or release it in this task.

Evidence on 2026-10-11: all 31 local labels have the prefix. Only display_name
changed in the 27 existing metadata files; four new files have no policy field.
All 31 SKILL.md entries and 69 archived source hashes match the base. Independent
source verification passes for 26 imports with no waivers; all 26 verifier tests
and both Claude static validators pass. The README catalog, both 5.5 manifests,
Unreleased heading, and changed-document relative links pass the scoped checks.

The normal Codex installer refreshed this PC from the follow-up source. Its 192
package files match that source. Four fresh native catalogs (console and desktop,
Git repo and UE_Blank_Proto) each find 31 entries with exact new labels, no errors,
and unchanged names, descriptions, wrapper paths, scopes and dependencies.
This is metadata/discovery proof with zero model requests. It is separate from
the dated PR #107 receipts for the 188-file merged package and earlier catalogs.
The Claude package is still the merged-main install; no Claude model test ran.

Outstanding: the owner checks the labels in a fresh visible Codex session.
The follow-up still needs review and PR CI. Daily-use acceptance of 5.5 and its
tag/release decision remain in task 40; this task does not pre-record them.
