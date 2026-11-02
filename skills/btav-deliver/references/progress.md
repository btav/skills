# Local progress and recovery

Keep execution notes outside the reviewed diff. Resolve the local path from the target repository using `git rev-parse --git-path btav/<change>/progress.md`; do not assume `.git` is a directory. Use a short task key based on the spec directory, and check the recorded absolute spec path before reusing an existing record. Choose a distinct key for a collision rather than overwriting another task.

## Record

Use concise Markdown rather than introducing a database or runner. Include:

- Absolute spec directory, product/tech readiness, and the spec content or content hashes used for this attempt.
- Starting revision, fixed review-anchor commit, task scope, and the inventory of pre-existing changes that must be preserved.
- Current stage: prerequisites, implementation, acceptance, review, or handoff; and whether active, stopped, or complete.
- Completed steps, remaining work, justified design adjustments, and unresolved decisions.
- Acceptance labels with check commands/reproductions, actual outcomes, code identity, and limitations. Identify uncommitted code using a diff or content snapshot that includes relevant untracked additions; `HEAD` alone is insufficient.
- Review outcome, completed pass count, available clean-pass/finding-attempt counts, unresolved findings, and any terminal stop reason. Keep the review loop's detailed finding ledger in session notes as it requires; summarize recovery-critical results here.
- The next action and any environment requirements.

Update at stage boundaries and when stopping. This is advisory recovery context, not an atomic job ledger or proof of execution. A crash can occur before an update.

## Resume

Read the specs, Git status, relevant code, and local record. Compare actual state with saved observations. Reuse the fixed anchor when still valid; if missing or incompatible, report the problem instead of silently selecting a new base. Never restore or discard working changes from the record.

Changed specs require checking that implementation and acceptance still match. Material product or architecture changes return to specification work. Changed code invalidates affected checks and review results. Inspect the final code before trusting a saved completion claim; rerun affected checks when identity or evidence is uncertain.

An interrupted review is not a clean pass. Supply known consumed counts and finding attempts when continuing the review loop; retain limits and reset clean-pass credit when the reviewed state is uncertain. If counts cannot be recovered safely, stop and explain the uncertainty rather than inventing unused budget. A prior terminal stop stays stopped until the user resolves it or explicitly authorizes a new attempt; a repeated invocation alone does not erase an exhausted budget.
