---
name: changelist-verification
description: "HARD RULE - use whenever a task involves MORE THAN ONE changeset (Perforce changelist, PR, or commit batch). Execute changeset-by-changeset with a stop-and-verify gate between each; never batch them."
---

# CRITICAL WORKFLOW REQUIREMENT

## Changeset-by-Changeset Verification

A **changeset** is one named, reviewable unit of work — a Perforce changelist, a git PR, or
a commit batch published as one step. When executing a multi-step plan that spans multiple
changesets, you **MUST**:

---

## Hard Rule

> [!CAUTION]
> **NEVER** batch multiple changesets into a single action or auto-publish them sequentially.
>
> Each changeset requires **explicit user verification** before proceeding to the next.

---

## Required Workflow

For plans with multiple changesets (CL1/PR1, CL2/PR2, etc.):

1. **Execute changeset 1's work** → Present results → **STOP**
2. **Wait for user verification** of changeset 1
3. **Only after approval**: Execute changeset 2's work → Present results → **STOP**
4. **Wait for user verification** of changeset 2
5. Continue this pattern for all subsequent changesets

---

## Exception

The **ONLY** exception is when the user **explicitly** states one of:
- "Do all changesets at once"
- "Submit them all without verification"
- "Skip changeset-by-changeset verification"
- Or similar explicit override

> [!CAUTION]
> **The exception itself has one carve-out: `ready-for-human` tickets.** That label means a human implements the ticket, so a changeset against one should not exist — and if you are holding one, it is NEVER covered by the batch override above, in any mode. Park it instead (Perforce: `p4 shelve -c <CL>` — files stay open locally, exclude from later reconcile/submit-all; git: leave on its branch, no merge/PR), append `GATED-SHELVED: process error - agent implemented a ready-for-human ticket` to its description, report it, and continue; the human reviews and publishes it personally. Changing its `Status:` to clear the block — to `ready-for-agent`, to `claimed`, to anything — is user-only, never yours. Full mechanics: the review-and-submit skill's `ready-for-human` rule.

---

## Why This Matters

- Allows user to catch issues early before they compound
- Enables course correction between steps
- Prevents cascading errors across multiple publications
- Maintains user control over version control state

---

## Enforcement

If you execute multiple changeset steps without stopping for verification between each, you have violated this requirement.

**Workflow**: `CS1 → Verify → CS2 → Verify → CS3 → Verify` (NEVER: `CS1 → CS2 → CS3 → Done`)

---

## Implementation note

This rule is advisory — it lives as documentation the agent reads at session start. The package briefly experimented with hook-based enforcement (v1.8.0/v1.8.1) but rolled it back in v1.9.0 as over-engineered for the actual drift rate. If you find yourself violating the rule frequently, address it via stronger workflow language or a per-turn reminder, not via hard hook blocks.
