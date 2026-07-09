# Raw Materials Protection

**HARD RULE — NON-NEGOTIABLE**: Files under `{{game_docs_root}}/_Raw/` are raw source materials imported from external resources (PDFs, reference docs, exports from other tools, etc.). They are **read-only** from Claude's perspective.

---

## The Rule

1. **NEVER modify, rename, delete, or reformat any file under `{{game_docs_root}}/_Raw/`** as part of normal work.
2. **NEVER move files out of `_Raw/`** — if a derivative doc is needed, create a new file elsewhere and reference the raw source.
3. This applies to **all operations**: edits, `p4 edit`, `p4 delete`, `p4 move`, shell `mv`/`rm`, Write tool overwrites.

## If the User Explicitly Requests a Change

Even when directly asked, you **MUST**:

1. **STOP** — do not perform the action.
2. **Present this warning verbatim:**
   > ⚠️ **`Docs/_Raw/` is protected.** Files here are raw materials from external resources and must not be modified without project-lead approval. Please confirm with the project leads before proceeding.
3. **Ask the user to confirm they have spoken with the project leads** and have authorization.
4. Only proceed after the user provides **explicit confirmation of lead approval** in the current conversation.

## Allowed Operations (No Warning Needed)

- **Reading** files in `_Raw/` for reference.
- **Adding new files** to `_Raw/` (importing new raw materials) — this is additive and does not alter existing sources.
- **Citing or linking** raw files from derivative docs elsewhere in `Docs/`.

## Rationale

Raw materials are the ground truth imported from external authorities (design leads, publishers, reference documents). Silent or well-intentioned edits to these sources corrupt the reference chain and can invalidate downstream work that depends on them. Protection is absolute to prevent drift.
