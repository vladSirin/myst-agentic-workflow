# resolving-merge-conflicts — Perforce (text files) project notes

Project adaptation for this Perforce codebase. The base skill is git-centric; here, resolve text-file conflicts through Perforce. The base skill's *discipline* (understand both sides, resolve the smallest hunks first, re-run tests after) applies unchanged — only the tooling differs.

## Perforce equivalents
- A conflict shows as a file that "needs resolve" after `p4 sync` / `p4 integrate` / `p4 merge`. List them: `p4 resolve -n`.
- Resolve interactively: `p4 resolve`. For safe automatic text merges: `p4 resolve -am`. Only use `-at` (accept theirs) / `-ay` (accept yours) when you are certain.
- 3-way text merges use the configured merge tool via `P4MERGE` — inspect base / theirs / yours; never accept a side blindly.
- After resolving, submit the changelist with `p4 submit` (follow `ReviewAndSubmit` / `ChangelistVerification` if the perforce overlay's workflows are installed).

## Binary assets
`.uasset` / `.umap` cannot be text-merged. Resolve by choosing a revision (`p4 resolve -at` / `-ay`) or re-author in the editor, and coordinate to avoid concurrent edits in the first place.
