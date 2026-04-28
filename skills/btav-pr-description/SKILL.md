---
name: btav-pr-description
description: Draft a PR body using a fixed three-section template — Description / Why / Changes — with Conventional-Commits prefixes per file.
---

# PR description (simple)

Invoked explicitly via `/btav-pr-description` in Claude or `$btav-pr-description` in Codex. Do not auto-fire on adjacent phrasings.

Three fixed sections. Brief. Semantic. Stop.

## What to summarize

Pick the source of changes in this order, unless the user specifies otherwise:

1. **A specific PR** if the user named one (`gh pr diff <N>` for the diff, `gh pr view <N>` for any existing title/body).
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch (`git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD`, plus `git log` over the same range for commit messages — they often state the *why*).
3. **Uncommitted working changes** otherwise (`git diff HEAD`).

If unsure which the user meant, ask in one short sentence before drafting.

Read the changed files when the diff alone doesn't make the behavior change obvious. Don't read the whole repo — just enough to describe each file's change in one sentence.

## Output format

Print the three sections wrapped in a single fenced ` ```markdown ` code block, and nothing else. Wrapping the whole PR body in one fence keeps the terminal from rendering the `###` headings and `-` bullets as styled output — the user sees the raw markdown verbatim and can copy-paste it directly into the GitHub PR body.

Section titles use `###`, the changes list uses `-` bullets, and any file path, function name, identifier, line number, or other code reference is wrapped in backticks so it renders as inline code on GitHub.

````
```markdown
### Description
<1–2 sentences, plain language, what this PR does>

### Why
<1–2 sentences on motivation / problem solved>

### Changes
- (prefix) `path/to/file.ext` — <one sentence recap of the change>
- (prefix) `path/to/other.ext` — <one sentence recap>
```
````

No preamble, no trailing commentary, no second fence — just the one ` ```markdown ` block.

## Rules for Changes

- **Lead with a semantic prefix** in parentheses (see list below) — e.g. `(fix)`, `(refactor)`, `(test)`. Exactly one prefix per bullet; if a file genuinely spans two categories, split into two bullets.
- **Curate, don't catalogue.** The diff already lists every file — your job is to give the reviewer the *context* they need to understand the PR, not re-list it. Include the bullets that explain intent; drop the ones that are just mechanical fallout from a change already listed.
- **Group repeated changes** instead of listing each file. If N files received the same edit (renamed import after a move, prop signature update, type rename, formatter sweep), summarize as one bullet that names the change and the count, e.g. `(refactor) updates imports in 14 call sites after moving `utils/date.ts` → `lib/date.ts``. Name 1–2 representative paths only if it genuinely helps the reviewer; otherwise skip the paths and let the diff speak.
- One bullet per meaningfully-changed file *or* per group of identically-changed files. Group trivial co-changes on one line (e.g. `package.json` + `package-lock.json`, a component and its snapshot).
- **Semantic** recap: describe the *behavior change*, not the mechanical edit. Prefer "validates email before submit" over "added `validateEmail()` call in `handleSubmit`".
- One sentence per bullet. No sub-bullets.
- Skip pure formatting / whitespace / regenerated lockfile churn unless it's the point of the PR. Skip purely mechanical fallout (import path updates after a rename, type-only renames in consumers) unless the consumer change is itself interesting.
- **Wrap every code reference in backticks** — file paths, function/class/variable names, type names, env vars, CLI flags, commands, line numbers (e.g. `Profile.tsx:42`), anything that is literally code or a code identifier. This applies in Description and Why too, not just Changes.

### Semantic prefixes

Pick exactly one — the dominant intent of that file's change:

- `(feat)` — new user-facing feature or capability
- `(fix)` — bug fix
- `(docs)` — documentation only (READMEs, comments, skill prompts, etc.)
- `(style)` — formatting, whitespace, missing semicolons; no behavior change
- `(refactor)` — internal restructuring; no behavior change and no bug fix
- `(perf)` — performance improvement
- `(test)` — adding or updating tests
- `(build)` — build system, bundler, package manifests, lockfiles
- `(ci)` — CI/CD config (GitHub Actions, pipelines, release workflows)
- `(chore)` — routine maintenance that doesn't fit elsewhere (deps bump, renames, dead-code removal)
- `(revert)` — reverts a prior commit

## Rules for Description and Why

- Plain prose. No bullets, no nested headers, no code blocks.
- 1–2 sentences each. If you need three, you're rambling — cut.
- Inline code references still get backticks (file paths, function/class names, identifiers, flags) — same rule as Changes.
- **Description** is *what* the PR does, in user-facing or behavioral terms.
- **Why** is *why* — the problem, user need, incident, or follow-up that motivated it. Don't restate Description in different words. If the diff alone doesn't reveal the why and the commit messages / PR title don't either, write one short honest sentence ("follow-up to remove dead code after the X migration") rather than inventing motivation.

## Style rules

- **No emojis.** No "Generated with Claude" footer. No preamble ("Here is your PR description:") and no trailing commentary.
- Print the three sections and stop.
- Don't run the build, typechecker, linter, or tests.
- Don't post to GitHub. Don't run `gh pr edit` or `gh pr create` unless the user explicitly asks.

## Worked example

Input: a small TypeScript branch that fixes an API base URL leak, adds an email guard, and renames a hook variable.

Output:

````
```markdown
### Description
Fix a hardcoded staging URL leaking into production builds and harden the profile page against users with no email on file.

### Why
A prod incident last week traced back to the staging URL shipping in the production bundle; the `user.email` crash surfaced in the same triage and was cheap to fix in the same PR.

### Changes
- (fix) `src/api/users.ts` — routes user fetches through `API_BASE_URL` instead of a hardcoded staging host.
- (fix) `src/components/Profile.tsx` — guards against `user.email` being undefined before lowercasing.
- (refactor) `src/hooks/useUser.ts` — renames `data` to `user` for readability at call sites.
```
````

## Worked example — grouping

Input: a branch that moves `utils/date.ts` to `lib/date.ts`, updates the 23 files that imported it, and adds a unit test for one previously-untested helper.

Output (note the import updates are a single grouped bullet — not 23 lines):

````
```markdown
### Description
Relocate the date utilities into `lib/` to match the new module layout and add a missing test for `formatRelative`.

### Why
The `lib/` reorg is winding down; `utils/date.ts` was the last util still living under `utils/`. The test was a gap surfaced by the move.

### Changes
- (refactor) `lib/date.ts` — moved from `utils/date.ts`; no behavior change.
- (refactor) updates imports in 23 call sites to point at the new path.
- (test) `lib/date.test.ts` — adds coverage for `formatRelative` across DST boundaries.
```
````
