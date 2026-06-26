---
name: btav-review-loop
description: Run a bounded review-and-fix loop over a diff / branch / PR. Repeatedly launch fresh code-review passes with `btav-code-review`, fix concrete findings locally, and stop after two consecutive clean fresh reviews or an explicit loop stop condition.
disable-model-invocation: true
---

# Review loop

Invoked explicitly via `/btav-review-loop` in Claude, `$btav-review-loop` in Codex, or `/skill:btav-review-loop` in Pi. Do not auto-fire on adjacent phrasings.

Run a fresh reviewer. Fix what is real. Re-run the reviewer with cleared context. Prefer exiting after two consecutive clean fresh reviews, but stop earlier when an explicit loop stop condition is reached.

## What to review

Pick the source of changes in this order, unless the user specifies otherwise:

1. **A specific PR** if the user named one.
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch.
3. **Uncommitted working changes** otherwise.

Before starting, read the PR title and description or the user's framing. Authorial intent matters for distinguishing intentional changes from accidental regression.

This skill fixes code locally. If the user names a PR URL or number, resolve it to a local writable checkout before starting the loop. If you can't access the PR branch locally, stop and ask the user to check out the branch or point you at a writable repo.

Skim mechanical churn once and group it. Don't spend loop budget on lockfiles, generated files, formatter sweeps, or repeated import-path updates unless they are the point of the change.

If you're unsure which change set the user meant, ask in one short sentence before starting the loop.

## Review anchor

Resolve the review anchor once at loop start and keep it fixed for the rest of the loop. Every review and re-review must cover the full cumulative change set against that same anchor.

Anchor rules:

- **Specific PR with a local checkout**: use the checked-out PR branch's merge-base with the default branch as the anchor, then review the full cumulative local diff from that anchor.
- **Current branch vs the default branch**: use the current branch's merge-base with the default branch as the anchor, then review the full cumulative branch diff from that anchor.
- **Uncommitted working changes**: use `HEAD` as the anchor, then review the full cumulative working tree diff from that anchor.

Do not review only the latest fix hunk. Do not switch anchors mid-loop.

## Core loop

Use fresh review passes. Don't trust your own prior review text as proof that the code is now correct.

### 1. Launch a fresh reviewer

When subagents are available, start a fresh subagent and have it use `btav-code-review` on the current change set.

Prompt shape:

```text
Use the `btav-code-review` skill at <path> to review the full cumulative change set against <review-anchor>. Include both the original changes and all fixes made in this loop. Return only the review.
```

Give the subagent the minimum necessary context. Don't leak your suspected bugs, intended fixes, or prior conclusions into the prompt.

After you have consumed a completed reviewer result, close that reviewer subagent before starting another reviewer pass.

If fresh subagents are not available, stop and tell the user that `btav-review-loop` requires fresh review passes to preserve cleared-context validation.

If the user explicitly asks to continue without subagents, you may run at most one degraded same-agent review/fix pass. After that pass, stop and explicitly say the result was not validated by fresh subagents. Degraded passes do not count toward the two-clean-pass exit rule and do not start a degraded loop.

### 2. Parse the findings

Treat these as actionable by default:

- `issue (blocking):`
- `issue (non-blocking):`

Treat these as conditionally actionable:

- `suggestion:` only when it clearly prevents a bug, regression, or concrete convention violation and the fix is locally provable

Treat these as non-fixable by default:

- `nitpick:`
- `question:`
- `praise:`

A clean pass is a review with no actionable findings. Ignore `praise:` for loop control.

If the review output is exactly:

```text
Verdict: approve — no issues found.
```

that is a clean pass.

If only `question:` items remain, stop and show them to the user instead of guessing.

### 3. Verify before fixing

Don't blindly patch from the review text alone.

For each actionable finding:

- read the referenced file and surrounding code
- trace at least one real call path when correctness depends on reachability
- confirm the finding is real
- drop anything not supported by the code
- merge duplicate findings before editing

False positives are worse than missed nits.

If verification eliminates all actionable findings, do not treat the prior reviewer output as a clean pass. Launch a fresh reviewer pass without making edits.

### 4. Fix the real findings

Apply the smallest correct fix at the ownership boundary where the bug belongs.

Prefer:

- root-cause fixes over symptom-only guards
- preserving expected public behavior unless the change is intentionally breaking
- small local refactors when they make the invariant obvious
- updating or adding the smallest nearby regression test when it directly locks in the fix

Don't create speculative cleanups unrelated to the finding.

### 5. Re-review

After fixing, launch a new fresh reviewer pass against the updated diff.

Every re-review must use the same review anchor chosen at loop start. Review the full cumulative change set, not only the most recent edits.

Do not start a degraded re-review loop. If you are in degraded mode, stop after the single degraded review/fix pass.

Track consecutive clean passes:

- initialize clean-pass count to `0` before the first review
- actionable findings found: reset clean-pass count to `0`
- clean pass: increment clean-pass count by `1`
- initialize total-pass count to `0` before the first review
- every fresh reviewer output, including the initial review, increments total-pass count by `1`

If a pass is clean and `clean-pass count` is `1`, immediately launch one more fresh reviewer pass without making edits.

Stop when either:

- clean-pass count reaches `2`
- total-pass count reaches `6`

## Stop conditions

Stop the loop when any of these is true:

- two consecutive fresh review passes are clean
- total review passes reach `6`
- a single degraded review/fix pass has completed
- only `question:` findings remain
- the remaining findings can't be verified from the code with reasonable confidence
- the same finding survives two fix attempts without a clear next move

When stopping due to uncertainty, show the unresolved findings and what blocked resolution.

If the loop stops in degraded mode, explicitly say the review was not validated by fresh subagents.

## Output

During the loop:

- briefly summarize what the latest review found
- briefly summarize what you fixed
- briefly note whether the clean-pass counter is `0`, `1`, or `2`

At the end:

- summarize the fixes made
- state whether the loop exited cleanly or with unresolved questions
- don't print scratchpad reasoning or rejected findings

## Safety rules

- Do not stage files.
- Do not create commits.
- Do not amend commits.
- Do not push.
- Do not open, edit, comment on, approve, merge, or close PRs or issues.
- Do not change GitHub state in any way.
- The user will handle commits manually.

## What NOT to do

- Don't trust a single review pass as final proof.
- Don't use stale findings after the code has changed; re-review from fresh context.
- Don't keep looping on praise or subjective stylistic comments.
- Don't run builds, linters, typecheckers, or tests unless the user explicitly asks.
