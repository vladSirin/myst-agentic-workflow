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

## Strict-mode hook (when enabled)

If the user has enabled strict mode (`enable-strict-mode.ps1`), this rule is enforced at the tool level. A PreToolUse hook blocks any `p4 submit -c <N>` unless `.scratch/.approved-cl-<N>.marker` is present at the project root.

**The marker dance** — when the hook blocks you:

1. **Don't retry blindly.** The block is the protocol asserting itself; you skipped a step.
2. **Surface the CL to the user**: description (`p4 describe -c <N>`), file list (`p4 opened -c <N>`), and the diff if non-trivial. Keep it focused — what's in the CL, why, and any risks.
3. **Ask explicitly**: "Approve CL `<N>` for submit?" — wait for an explicit "yes / approve / go ahead" or equivalent. Implicit instructions ("submit it", "ship it") still need this confirmation beat.
4. **Create the marker** after user approves:
   ```powershell
   New-Item -ItemType File -Path '.scratch/.approved-cl-<N>.marker' -Force | Out-Null
   ```
5. **Run the submit**: `p4 submit -c <N>`. The hook now allows it, and a paired PostToolUse hook deletes the marker so each approval is one-shot.

If the user has said something ambiguous like "submit those", treat that as "you can prepare to submit, but still ask explicitly which CL and confirm before each one."

If the hook isn't installed (strict mode not enabled), the rule still applies — just unenforced. Same protocol; same expected behavior; you just have to remember.

---

## Powermode (v1.8.1)

For autonomous multi-CL work (e.g., `/goal`-driven bugfix sprints), the user may grant batch approval via `enable-powermode.ps1 -SubmitCount N -DurationMinutes M`. While powermode is active, the per-CL gate is bypassed up to N submits or until the clock runs out — whichever comes first.

**When you see `POWERMODE: allowing submit of CL <N> (remaining: M; expires: T)` in tool output**, that's the hook signaling powermode is being burned. You can submit without creating a marker. Two things to do:

1. **Still surface each CL to the user** — powermode bypasses the *gate*, not the protocol. The user granted you a quota because they trust you to drive the work; honor that by being transparent about what each CL contains.
2. **Watch the remaining counter** — when it hits 1, the next submit is your last freebie. After that, the per-CL gate is back.

If powermode wasn't enabled but you think it should be (because the user explicitly said "go ahead, do all of them"), don't assume — pause and ask whether to enable powermode for the rest of the task.
