# CRITICAL WORKFLOW REQUIREMENT

## Changelist-by-Changelist Verification

When executing a multi-step plan that spans multiple changelists, you **MUST**:

---

## Hard Rule

> [!CAUTION]
> **NEVER** batch multiple changelists into a single action or auto-submit them sequentially.
>
> Each changelist requires **explicit user verification** before proceeding to the next.

---

## Required Workflow

For plans with multiple changelists (CL1, CL2, CL3, etc.):

1. **Execute CL1 work** → Present results → **STOP**
2. **Wait for user verification** of CL1
3. **Only after approval**: Execute CL2 work → Present results → **STOP**
4. **Wait for user verification** of CL2
5. Continue this pattern for all subsequent changelists

---

## Exception

The **ONLY** exception is when the user **explicitly** states one of:
- "Do all changelists at once"
- "Submit them all without verification"
- "Skip CL-by-CL verification"
- Or similar explicit override

---

## Why This Matters

- Allows user to catch issues early before they compound
- Enables course correction between steps
- Prevents cascading errors across multiple submissions
- Maintains user control over version control state

---

## Enforcement

If you execute multiple changelist steps without stopping for verification between each, you have violated this requirement.

**Workflow**: `CL1 → Verify → CL2 → Verify → CL3 → Verify` (NEVER: `CL1 → CL2 → CL3 → Done`)

---

## Implementation note

This rule is advisory — it lives as documentation the agent reads at session start. The package briefly experimented with hook-based enforcement (v1.8.0/v1.8.1) but rolled it back in v1.9.0 as over-engineered for the actual drift rate. If you find yourself violating the rule frequently, address it via stronger workflow language or a per-turn reminder, not via hard hook blocks.
