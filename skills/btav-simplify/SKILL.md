---
name: btav-simplify
description: Over-engineering review of a diff / branch / PR. Finds what to delete — reinvented stdlib, needless dependencies, speculative abstractions, dead flexibility. One line per finding with a net line-count, complementing correctness-focused review.
disable-model-invocation: true
---

# Simplify (over-engineering review)

Invoked explicitly via `/btav-simplify` in Claude, `$btav-simplify` in Codex, or `/skill:btav-simplify` in Pi. Do not auto-fire on adjacent phrasings.

Review the change for unnecessary complexity only. One line per finding: where it is, what to cut, what replaces it. The diff's best outcome is getting shorter.

## What to review

Pick the source of changes in this order, unless the user specifies otherwise:

1. **A specific PR** if the user named one (`gh pr diff <N>` to fetch).
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch (`git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD`).
3. **Uncommitted working changes** otherwise (`git diff HEAD`).

If you're unsure which the user meant, ask in one short sentence before reviewing.

Read enough of the changed files to be sure a cut is safe — that the "simpler" replacement actually preserves behavior. If the diff mirrors an existing pattern in the repo, spot-check the canonical version before calling shared structure over-engineered; flag the *delta*, not the inherited shape.

## Output format

One line per finding:

```
L<line>: <tag> <what>. <replacement>.
```

Use `<file>:L<line>: ...` when the diff spans multiple files.

Tags:

- `delete:` dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, a layer with one caller.
- `shrink:` same logic, fewer lines. Show the shorter form.

End with the only metric that matters:

```
net: -<N> lines possible.
```

If there is nothing to cut, output exactly one line and stop:

```
Lean already. Ship.
```

## Boundaries

- **Scope is over-engineering and complexity only.** Correctness bugs, security holes, and performance are out of scope — route those to `/btav-code-review`, not here.
- A single smoke test or `assert`-based self-check is the minimum that proves the code runs, not bloat. Never flag it for deletion.
- **List findings, apply nothing.** Don't edit files, stage, commit, or push.

## Style rules

- One line per finding. No paragraphs, no hedging ("have you considered…").
- **No emojis. No "Generated with Claude" footers.** This is inline output.
- **Don't run** the build, typechecker, linter, or tests. Print the findings and stop.

## Worked example

Input: a small diff that adds an email-validation helper and a date-format dependency.

Output:

```
L12-38: stdlib: 27-line EmailValidator class. "@" in the string is enough — real validation is the confirmation mail.
L4: native: moment.js imported for one format call. Intl.DateTimeFormat, 0 deps.
L52-71: delete: retry wrapper around an idempotent local call. Nothing replaces it.
L30-44: shrink: manual loop builds a dict. dict(zip(keys, values)), 1 line.
net: -58 lines possible.
```
