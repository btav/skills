---
name: btav-code-review
description: Short, code-heavy review of a diff / branch / PR using Conventional Comments prefixes (issue / suggestion / question / nitpick / praise) with a final verdict line.
---

# Code review (simple)

Invoked explicitly via `/btav-code-review` in Claude or `$btav-code-review` in Codex. Do not auto-fire on adjacent phrasings.

Short, code-heavy reviews. Show the change, don't describe it. Approve generously.

## What to review

Pick the source of changes in this order, unless the user specifies otherwise:

Before reading the diff, read the PR title and description (or the user's framing if it's a local diff). Authorial intent — what the PR claims to do — is what lets you distinguish intentional from accidental changes. Skim mechanical churn (cache-key bumps, lockfiles, regenerated snapshots) once and don't re-flag it.

1. **A specific PR** if the user named one (`gh pr diff <N>` to fetch).
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch (`git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD`).
3. **Uncommitted working changes** otherwise (`git diff HEAD`).

If you're unsure which the user meant, ask in one short sentence before reviewing.

Read the changed files (not just the hunks) when surrounding context matters for judging an issue. You don't need the whole repo — just enough to be sure a flagged issue is real. If the diff forks or mirrors an existing implementation (parallel bundler configs, host-config variants, sibling adapters), spot-check the canonical version before flagging anything as a "novel" bug or convention violation. Patterns shared with established code are not novel — flag the *delta*, not the inherited shape.

## What to look for

In rough priority order:

- **Bugs** — wrong logic, off-by-one, broken control flow, race conditions, null/undefined that will be dereferenced, wrong API endpoints, leaked credentials, data-loss risks.
- **Regressions** — behavior changes that look unintentional given the diff's stated purpose.
- **Security** — injection, auth bypass, unsafe deserialization, secrets in code.
- **Project conventions** — read `CLAUDE.md` (root and any in modified directories) and call out clear violations. Don't invent conventions the project doesn't actually have.
- **Clarity** — only when a small change makes the code obviously easier to read. Bias toward leaving working code alone.
- **Reachability check** — before flagging a logic bug, follow at least one call path to confirm the bad input is actually reachable. If reaching the bug requires conditions you can't verify from the diff and surrounding files, downgrade to `question:` rather than `issue:`.

**Severity calibration.** Bugs in production data paths are blocking. Bugs in dev-only paths (debug channels, source maps, error reporters, dev-mode logging) are usually `issue (non-blocking):` unless they corrupt user data or mask security issues. Bugs in tests, fixtures, and tooling are usually `suggestion:`.

### Lenses (sharpen findings — never lower the bar)

A lens is a way of looking at the diff. It can sharpen a `why:` line, but it never justifies a comment you wouldn't otherwise leave. If the only reason to flag something is "it violates law X", drop it.

- **YAGNI** — speculative abstractions, config knobs nobody sets, parameters with one caller, dead branches added "for later".
- **DRY (real)** — the same knowledge expressed in two places. Coincidental similarity doesn't count.
- **Law of Demeter** — `a.b.c.d` chains that reach through and depend on the internals of an unrelated object.
- **Hyrum's Law** — when the diff changes an exported signature, return shape, error shape, or ordering, flag consumer-impact risk even if the typed contract still compiles.
- **Premature Optimization** — micro-opts (manual unrolling, custom hash, hand-rolled cache) added off the hot path with no benchmark.
- **Broken Windows** — commented-out code, `// TODO(remove)`, dead imports, or half-finished work *introduced by this diff*. Pre-existing rot is out of scope.

## What NOT to flag

- Lint, typecheck, formatting, missing imports, broken tests — CI handles these.
- Pre-existing code outside the diff. (Exception: if the diff *touches* a line and the surrounding context reveals a serious bug introduced by these changes, flag it.)
- Missing tests or docs unless the project explicitly requires them.
- Stylistic preferences not grounded in a real readability or correctness gain.
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
<file>:<line>
```diff
- <old code>
+ <suggested code>
```
````

Optional single `why:` line under the snippet — capped at one sentence. If you can't say it in one sentence, it's probably two comments. A `why:` may name a lens (`why: YAGNI — this branch is unreachable`) only when the name actually sharpens the point. Never as filler.

For `question:` and `praise:`, the diff block is optional — sometimes the snippet is just the relevant `+` lines with no replacement.

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

- **Show code, don't describe it.** If you can express the point as a `-`/`+` snippet, do that instead of writing a paragraph. The snippet is the comment.
- **One sentence max** per `why:` line. Often you don't need one — the diff speaks for itself.
- **No emojis. No "Generated with Claude" footers.** This is inline output, not a posted comment.
- **Approve generously** — treat blocking severity as a real bar. Reserve `request changes` for diffs that actually shouldn't merge.
- **Don't run** the build, typechecker, linter, or tests. Don't post anywhere. Print the review and stop.

## Worked example

Input: a small TypeScript PR touching three files, with one real bug, one swallowed error, one minor smell, one bad name.

Output:

````
issue (blocking): wrong endpoint — returns staging data in production
src/api/users.ts:42
```diff
- fetch('https://staging.api.example.com/users')
+ fetch(`${API_BASE_URL}/users`)
```
why: hardcoded staging URL will leak to prod builds.

issue (non-blocking): swallowed error hides retry exhaustion
src/api/users.ts:58
```diff
- } catch (e) { return null }
+ } catch (e) { logger.warn('user fetch failed', e); return null }
```

suggestion: guard against missing email
src/components/Profile.tsx:14
```diff
- user.email.toLowerCase()
+ user.email?.toLowerCase()
```

nitpick: `data` is vague
src/hooks/useUser.ts:7
```diff
- const data = await getUser()
+ const user = await getUser()
```

Verdict: request changes
````
