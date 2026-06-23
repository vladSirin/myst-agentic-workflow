# radical-design-critic — AFK lessons

This file accrues anti-patterns from AFK auto-submits that were later reverted. It starts empty.

When the user runs `revert AFK CL <N>` and states a reason, the AFKAutoSubmit workflow appends a
lesson here. The radical-design-critic agent loads this file on every AFK review and matches against the
recorded patterns before emitting `AFK-Verdict: SAFE`.

Format (one block per lesson):

```markdown
## Lesson <N>: <short title>
**From:** CL <N> (reverted <date>)
**Reviewer said:** AFK-Verdict: SAFE
**Should have flagged:** <user reason>
**Pattern:** <generalization to match against in future reviews>
```

---

<!-- lessons accrue below -->