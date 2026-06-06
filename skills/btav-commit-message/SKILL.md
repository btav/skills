---
name: btav-commit-message
description: Generate one short Conventional Commit subject from the current changes. Use only when explicitly invoked via /btav-commit-message in Claude or $btav-commit-message in Codex.
---

# Commit message (short)

Invoke explicitly via `/btav-commit-message` in Claude or `$btav-commit-message` in Codex. Do not auto-fire on adjacent phrasing.

Generate one concise Conventional Commit subject and stop.

## What to summarize

Use a change set named by the user when provided. Otherwise:

1. Inspect `git status --short`.
2. If staged changes exist, summarize only `git diff --cached`.
3. If nothing is staged, summarize all uncommitted tracked changes and inspect relevant untracked files.

Read only enough surrounding code to identify the dominant behavioral intent. Treat supporting tests, documentation, generated files, and lockfile changes as secondary to the behavior they support.

If there are no changes, output exactly:

```text
No changes found.
```

## Output format

Output exactly one plain-text line:

```text
<type>[!]: <description>
```

Examples:

```text
feat: add account deletion
fix: handle missing user email
refactor!: remove legacy auth adapter
```

## Types

Choose the single type that best represents the dominant intent:

- `feat` — add a user-facing capability
- `fix` — correct a bug
- `docs` — change documentation only
- `style` — change formatting without changing behavior
- `refactor` — restructure code without adding a feature or fixing a bug
- `perf` — improve performance
- `test` — add or update tests only
- `build` — change build tooling, dependencies, or package metadata
- `ci` — change CI/CD configuration
- `chore` — perform maintenance that fits no more specific type
- `revert` — revert an earlier change

Append `!` to the type only when the change clearly breaks compatibility.

## Rules

- Keep the complete line at 72 characters or fewer.
- Do not include a scope, body, footer, code fence, preamble, or trailing commentary.
- Write the description in lowercase imperative form.
- Omit the trailing period.
- Describe behavior or intent, not filenames or mechanical edits.
- Prefer specific verbs such as `add`, `fix`, `remove`, `prevent`, or `simplify`.
- Do not invent motivation that the changes do not establish.
- Never stage files, create a commit, browse documentation, or run tests.
