---
name: btav-deliver
description: Implement one change from ready product and tech specs, verify acceptance, run bounded review, and hand back local changes. Use only when explicitly invoked.
disable-model-invocation: true
---

# Deliver a specified change

Invoked via `/btav-deliver` in Claude, `$btav-deliver` in Codex, or `/skill:btav-deliver` in Pi, with a spec directory. Repeating the invocation resumes the task after inspecting actual repository state.

Own the sequence from ready specs to verified local changes. Use the existing harness to execute it. This workflow authorizes its documented helper skills as stages; their report-and-stop rules end the stage, then control returns here. Read helpers from this skill's sibling directory and announce their use. Preserve their review, verification, and action boundaries.

## Establish the task

Read applicable repository instructions, both specs, and the relevant code. Require confirmed product decisions, a complete technical design, and observable acceptance criteria. Invoking delivery on supplied ready specs is the handoff; do not request redundant approval. Missing or materially incomplete specs go back through `btav-spec` before implementation. Do not silently create requirements.

Require a Git checkout and a valid review base. Read [Shared diff selection](../btav-review/references/diff-selection.md), resolve the anchor before implementation, and save its commit ID. Inventory committed task changes and staged, unstaged, and non-ignored untracked files. Preserve unrelated work. If existing work cannot be separated from the task, clarify the scope before editing; never stash, reset, or discard it to obtain a clean checkout.

Check that the technical design still fits the current repository. Explain stale assumptions and return material behavior or architecture departures to specification work. Small implementation adjustments within the agreed design can be recorded with their rationale.

Read [Progress and recovery](references/progress.md), then load or create the local task record when writes are permitted. If native plan mode prohibits implementation or logging, present the intended work and prerequisites in conversation; do not change modes or claim delivery started.

## Implement and verify

Discover setup, check commands, and required validation from repository instructions, manifests, and CI. Report missing prerequisites specifically. Do not invent a passing substitute for an unavailable check or turn this task into unrelated infrastructure work.

Implement the tech spec in verifiable units. For a bug, establish a failing reproduction before editing when practical; otherwise state the baseline gap. Run acceptance scenarios and required checks, adding focused tests where needed to establish the requested behavior. A test's existence does not establish that it ran or passed.

Keep a requirement-by-requirement acceptance record tied to the final code: check or reproduction, result, relevant version/diff, and limits. Use `passed`, `failed`, `incomplete`, or `not applicable` with a reason. Use direct runtime or UI evidence when the requirement depends on it; explain what unit or mocked checks leave unverified. Acceptance criteria must not be weakened simply to make checks pass.

Investigate and fix failures within scope. Stop with evidence when a material decision, unavailable environment, or an unverified mechanism prevents progress. Repeatedly running an unchanged failing check is not progress; after two unsuccessful attempts at the same defect without a supported next move, report the blocker.

## Review the cumulative change

Read and apply [btav-review-loop](../btav-review-loop/SKILL.md), supplying the original intent, ready specs, fixed anchor, explicit task scope, and current verification evidence. Keep unrelated work outside that explicit scope while including all task changes, including untracked additions. The shared diff-selection guide honors a caller's explicit scope.

Preserve the helper's fresh-reviewer requirement, six-pass cap, two-attempt finding limit, and stop conditions. Do not restart an exhausted or unsuccessful loop just to obtain approval. If fresh reviewers are unavailable, follow the helper's stop behavior; do not substitute self-review and report fresh validation.

After review fixes, refresh affected acceptance checks and required checks on the resulting code. Any further code edits invalidate affected verification and the prior review outcome; obtain current verification and review within the remaining loop budget, or stop with the gap. Approval cannot dismiss a confirmed failure.

## Handoff

Success requires satisfied acceptance criteria, passing required checks, and successful completion of the review loop with no unresolved actionable findings. Explain genuinely inapplicable verification; missing or failed evidence prevents verified success. Report review and verification separately.

Update local progress at stage boundaries and whenever stopping. Finish with the change summary, acceptance results, observed checks, review outcome, unresolved items, and next action. For a successful task, apply [btav-pr-body](../btav-pr-body/SKILL.md) to the same explicit task scope and available final evidence; include its draft as the PR-text portion of the handoff. Its standalone output format applies inside that portion.

Leave all changes local. Do not stage, commit, amend, push, create or modify PRs, merge, or deploy. Do not modify global harness settings or install skills as part of delivering a task.
