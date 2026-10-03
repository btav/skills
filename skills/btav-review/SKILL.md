---
name: btav-review
description: Review a diff / branch / PR with clear code locations, plain explanations of problems, and suggested fixes shown in small diffs, using Conventional Comments prefixes and a final verdict line.
disable-model-invocation: true
---

# Code review (simple)

Invoked explicitly via `/btav-review` in Claude, `$btav-review` in Codex, or `/skill:btav-review` in Pi. Do not auto-fire on adjacent phrasings.

Short reviews that make each finding easy to understand: where it is, what goes wrong, and how to fix it. Show a small code diff alongside the explanation. Approve generously.

## What to review

Pick the source of changes in this order, unless the user specifies otherwise:

1. **A specific PR** if the user named one (`gh pr diff <N>` for the diff, `gh pr view <N>` for the title/body).
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch (`git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD`).
3. **Uncommitted working changes** otherwise (`git diff HEAD`, plus untracked files from `git ls-files --others --exclude-standard :/`).

If you're unsure which the user meant, ask in one short sentence before reviewing.

Before reading the diff, read the PR title and description (or the user's framing if it's a local diff). Authorial intent — what the PR claims to do — is what lets you distinguish intentional from accidental changes. Skim mechanical churn (cache-key bumps, lockfiles, regenerated snapshots) once and don't re-flag it.

Read the changed files (not just the hunks) when surrounding context matters for judging an issue. You don't need the whole repo — just enough to be sure a flagged issue is real. If the diff forks or mirrors an existing implementation (parallel bundler configs, host-config variants, sibling adapters), spot-check the canonical version before flagging anything as a "novel" bug or convention violation. Patterns shared with established code are not novel — flag the *delta*, not the inherited shape.

## What to look for

In rough priority order:

- **Bugs** — wrong logic, off-by-one, broken control flow, race conditions, null/undefined that will be dereferenced, wrong API endpoints, leaked credentials, data-loss risks.
- **Regressions** — behavior changes that look unintentional given the diff's stated purpose.
- **Security** — injection, auth bypass, unsafe deserialization, secrets in code.
- **Project conventions** — read applicable `AGENTS.md` and `CLAUDE.md` files (root and any in modified directories) and call out clear violations. Don't invent conventions the project doesn't actually have.
- **Clarity** — only when a small change makes the code obviously easier to read. Bias toward leaving working code alone.
- **Obvious over-engineering introduced by this diff** — only when a smaller replacement is locally provable. Prefer `suggestion:` unless the extra complexity causes a real bug, regression, or convention violation.
- **Reachability check** — before flagging a logic bug, follow at least one call path to confirm the bad input is actually reachable. If reaching the bug requires conditions you can't verify from the diff and surrounding files, downgrade to `question:` rather than `issue:`.

**Severity calibration.** Bugs in production data paths are blocking. Bugs in dev-only paths (debug channels, source maps, error reporters, dev-mode logging) are usually `issue (non-blocking):` unless they corrupt user data or mask security issues. Bugs in tests, fixtures, and tooling are usually `suggestion:`.

### Lenses (sharpen findings — never lower the bar)

A lens is a way of looking at the diff. It can help identify a concrete problem, but it never justifies a comment you wouldn't otherwise leave. If the only reason to flag something is "it violates law X", drop it.

- **YAGNI** — speculative abstractions, config knobs nobody sets, parameters with one caller, dead branches added "for later".
- **DRY (real)** — the same knowledge expressed in two places. Coincidental similarity doesn't count.
- **Law of Demeter** — `a.b.c.d` chains that reach through and depend on the internals of an unrelated object.
- **Hyrum's Law** — when the diff changes an exported signature, return shape, error shape, or ordering, check whether callers depend on the old behavior, even if the typed contract still compiles.
- **Premature Optimization** — micro-opts (manual unrolling, custom hash, hand-rolled cache) added off the hot path with no benchmark.
- **Broken Windows** — commented-out code, `// TODO(remove)`, dead imports, or half-finished work *introduced by this diff*. Pre-existing rot is out of scope.

## What NOT to flag

- Lint, typecheck, formatting, missing imports, broken tests — CI handles these.
- Pre-existing code outside the diff. (Exception: if the diff *touches* a line and the surrounding context reveals a serious bug introduced by these changes, flag it.)
- Missing tests or docs unless the project explicitly requires them.
- Stylistic preferences not grounded in a real readability or correctness gain.
- Over-engineering hunts that turn the review into a cleanup pass. Cap simplification comments to one or two high-signal items unless the complexity causes a correctness problem.
- Changes that are clearly intentional and on-purpose for the PR's goal, even if you'd have done them differently.

If you're not sure whether something is real, drop it. False positives are worse than missed nits.

## Output format

Use these six prefixes, in this severity order:

| Prefix | Meaning | Blocks merge? |
|---|---|---|
| `issue (blocking):` | Bug, regression, security/data-loss risk, or clear convention violation that must be fixed before merge | Yes |
| `issue (non-blocking):` | Real problem but small enough that the PR can ship and a follow-up handles it | No |
| `suggestion:` | A clearer / safer / more idiomatic way to write the same code | No |
| `question:` | You don't understand intent — ask the author | No |
| `nitpick:` | Naming, micro-style. Author free to ignore | No |
| `praise:` | Something done well worth a quick callout. Use sparingly | No |

### Shape of every comment

````
<prefix> <one-line summary>

<file>:<line> · <function, component, or module>

Problem: <what goes wrong and its concrete consequence>
Fix: <the smallest supported change>

```diff
- <old code>
+ <suggested code>
```
````

Use verified line numbers from the version being reviewed, pointing to the relevant changed code. Include the enclosing function, component, or module when it helps locate the code; omit it when redundant or unavailable.

The reader should understand each finding without decoding the diff. The summary names the defect; `Problem:` gives the triggering condition and consequence for bugs, or the specific reading difficulty for clarity suggestions; `Fix:` gives the change plus anything the diff can't show, such as why the replacement is safe. Keep each to one short sentence, and don't restate one in another.

Show only the code needed to understand the change. Match the surrounding behavior and conventions; do not invent fallback values, APIs, or replacement code without evidence. If the problem is confirmed but an exact patch is not supported, describe the fix in words and omit the diff.

`issue` and `suggestion` comments always include `Problem:` and `Fix:`. For `nitpick:`, `question:`, and `praise:`, keep the summary and location and add only what the reader needs: a one-line diff, a brief question, or a sentence.

### Order

1. Group by severity, blocking first. Within a group, order by file.
2. End with a single verdict line:
   - `Verdict: approve` — no blocking issues. This is the default whenever everything is `suggestion:` / `question:` / `nitpick:` / `praise:` / non-blocking.
   - `Verdict: request changes` — at least one `issue (blocking):`. Reserved for things that genuinely can't merge as-is.

### When there's nothing to flag

Output exactly one line:

```
Verdict: approve — no issues found.
```

Don't pad. Don't list files you checked. Don't add a footer.

## Style rules

- **Use plain, concrete language.** Avoid jargon, design-law names, and vague claims such as "cleaner," "more robust," or "bad practice." Keep technical names when they identify the actual code.
- **No emojis. No "Generated with Claude" footers.** This is inline output, not a posted comment.
- **Approve generously** — treat blocking severity as a real bar. Reserve `request changes` for diffs that actually shouldn't merge.
- **Don't run** the build, typechecker, linter, or tests. Don't post anywhere. Print the review and stop.

## Worked example

Input: a TypeScript PR accidentally switches the production user fetch to a staging URL; the surrounding module already imports the environment-specific `API_BASE_URL`. It also adds a search hook that lets an older response overwrite newer results (the codebase has no request-cancellation pattern), and filters inactive users out of search without explaining that behavior change.

Output:

````
issue (blocking): hardcoded staging URL

src/api/users.ts:42 · fetchUsers()

Problem: Production builds request users from staging.
Fix: Use `API_BASE_URL`, which this module already imports for its other requests.

```diff
- fetch('https://staging.api.example.com/users')
+ fetch(`${API_BASE_URL}/users`)
```

issue (non-blocking): older search results can overwrite newer ones

src/hooks/useUserSearch.ts:31 · useUserSearch()

Problem: When two searches overlap, the slower response sets `results` last, so the list can show matches for the previous query.
Fix: Ignore responses whose query no longer matches the input.

question: confirm whether search should hide inactive users

src/search/users.ts:27 · searchUsers()

The new filter removes inactive users from every search result; is that intended?

Verdict: request changes
````
