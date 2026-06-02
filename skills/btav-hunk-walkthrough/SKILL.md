---
name: btav-hunk-walkthrough
description: Walk a diff hunk-by-hunk with a one-sentence behavior recap per hunk and an optional lens note (YAGNI / DRY / Hyrum / Demeter / premature opt / broken windows).
disable-model-invocation: true
---

# Hunk walkthrough

Invoked explicitly via `/btav-hunk-walkthrough` in Claude, `$btav-hunk-walkthrough` in Codex, or `/skill:btav-hunk-walkthrough` in Pi. Do not auto-fire on adjacent phrasings.

Walk the diff hunk-by-hunk. Show, then explain in one breath. Flag a lens only when it sharpens the read.

## What to walk through

Pick the source of changes in this order, unless the user specifies otherwise:

Before reading the diff, read the PR title and description (or the user's framing if it's a local diff). Authorial intent — what the PR claims to do — is what lets you describe each hunk in behavioral terms instead of just narrating the textual edit.

1. **A specific PR** if the user named one (`gh pr diff <N>` to fetch, `gh pr view <N>` for the title/body).
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch (`git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD`).
3. **Uncommitted working changes** otherwise (`git diff HEAD`).

If you're unsure which the user meant, ask in one short sentence before walking.

Read the changed files (not just the hunks) when surrounding context matters for explaining a hunk's behavior — e.g. when a hunk's effect depends on an unchanged caller, type, or schema. You don't need the whole repo, just enough to describe the hunk in behavioral terms.

Skim mechanical churn (lockfiles, regenerated snapshots, formatter sweeps, identical import-path updates after a rename) and **group it into a single entry** rather than walking each hunk. The reviewer needs to know it happened, not see it ten times.

## Output format

Each hunk renders as:

````
### `path/to/file.ext` — `@@ -42,5 +42,8 @@`

```diff
@@ -42,5 +42,8 @@ function foo() {
- old line
+ new line
```

#### Change
<one or two plain sentences on what this hunk does in behavioral terms.>

#### Note
<optional, only when a lens applies — leads with the lens name.>

---

### `path/to/next-file.ext` — `@@ -10,3 +10,3 @@`
…
````

Rules:

- **One entry per hunk**, in the order the diff presents them: group by file (in the order files appear in the diff), then top-down by line number within each file.
- **Separate each hunk entry with a horizontal rule (`---`) on its own line.** The rule goes *between* entries — no leading rule before the first hunk, no trailing rule after the last.
- **Always leave a blank line between the closing ``` of the diff block and the `#### Change` heading**, and between `#### Change` and a following `#### Note`. The breathing room is the point.
- **`#### Change` is mandatory.** Describe the *behavior change*, not the textual edit. Prefer "routes user fetches through `API_BASE_URL` instead of a hardcoded staging host" over "replaced string literal with template literal in `fetch()` call".
- **`#### Note` is optional and capped at one sentence**, leading with the lens name (e.g. `Hyrum — callers that depend on the old return shape will break.`). At most one note per hunk; if two lenses apply, pick the one that sharpens the read most. No note is the common case.
- **Wrap every code reference in backticks** — file paths, function/class/variable names, type names, env vars, CLI flags, line numbers (e.g. `Profile.tsx:42`).
- **Group mechanical churn** into a single entry with no `@@` header: e.g. `### Mechanical: import path updates` followed by a `#### Change` section that names the count and the cause. Don't walk each one.
- **Skip pure formatting / whitespace hunks** entirely unless reformatting is the point of the PR.

## Lens notes

Six lenses, used here as **observations** rather than verdicts — they help the human reviewer decide where to look harder, nothing more.

- **YAGNI** — speculative abstraction, config knob with no caller, parameter added "for later", branch that can't be reached today.
- **DRY (real)** — the same knowledge now expressed in two places. Coincidental similarity doesn't count.
- **Law of Demeter** — `a.b.c.d` chains that reach through and depend on the internals of an unrelated object.
- **Hyrum's Law** — exported signature, return shape, error shape, ordering, or timing changed in a way that consumers may silently depend on, even if the typed contract still compiles.
- **Premature optimization** — micro-opt (manual unrolling, custom hash, hand-rolled cache) added off the hot path with no benchmark.
- **Broken windows** — commented-out code, `// TODO(remove)`, dead imports, or half-finished work *introduced by this hunk*. Pre-existing rot is out of scope.

Rules for notes:

- **Only when the lens genuinely sharpens the read.** If removing the note would not change what the reviewer pays attention to, drop it.
- **Phrase as observation, not verdict.** "Hyrum — `getUser()` now returns `null` instead of throwing; existing `try/catch` callers will silently get `null`." Not "issue: breaks callers."
- **Never as filler.** Most hunks have no note. That's correct.
- **One note per hunk, maximum.**

## What NOT to do

- **Don't deliver a verdict.** No `Verdict: approve` line, no overall summary at the end. The reviewer is the one with the verdict; you're handing them a clean read.
- **Don't issue prefixed comments** (`issue (blocking):`, `suggestion:`, `nitpick:`, etc.). Notes here lead with a lens name, not a severity prefix.
- **Don't pad.** If the diff already speaks for itself, the `#### Change` body is one short sentence — sometimes just the verb plus the object. Don't restate what the `+`/`-` lines already show.
- **Don't run the build, typechecker, linter, or tests.** Don't post anywhere. Print the walkthrough and stop.
- **Don't walk pure formatting, whitespace, or generated-file hunks** unless reformatting is the PR's actual purpose. Skip them or roll them into one mechanical-churn entry.

## Style rules

- **No emojis.** No "Generated with Claude" footer. No preamble ("Here's the walkthrough:"). No trailing summary. Print the entries and stop.
- **Show code, then describe it.** The diff block carries the change; the `#### Change` body carries the *intent*. One sentence is usually enough; two is the cap.
- **Backtick every code reference** — paths, identifiers, flags, line numbers.

## Worked example

Input: a small TypeScript PR — fixes a hardcoded staging URL, hardens a profile component, renames a hook variable, and updates 14 import paths after a util move.

Output:

````
### `src/api/users.ts` — `@@ -40,7 +40,7 @@`

```diff
@@ -40,7 +40,7 @@ export async function getUser(id: string) {
-  const res = await fetch('https://staging.api.example.com/users/' + id)
+  const res = await fetch(`${API_BASE_URL}/users/${id}`)
   if (!res.ok) return null
   return res.json()
 }
```

#### Change
Routes user fetches through `API_BASE_URL` instead of a hardcoded staging host, so prod builds hit prod.

---

### `src/api/users.ts` — `@@ -55,3 +55,7 @@`

```diff
@@ -55,3 +55,7 @@ export async function getUser(id: string) {
+export async function getUserOrThrow(id: string) {
+  const u = await getUser(id)
+  if (!u) throw new Error(`user ${id} not found`)
+  return u
+}
```

#### Change
Adds a throwing variant of `getUser` for callers that want to bail rather than handle `null`.

#### Note
YAGNI — no caller in this diff uses `getUserOrThrow`; worth confirming a follow-up PR needs it.

---

### `src/components/Profile.tsx` — `@@ -12,3 +12,3 @@`

```diff
@@ -12,3 +12,3 @@ export function Profile({ user }: Props) {
-  return <span>{user.email.toLowerCase()}</span>
+  return <span>{user.email?.toLowerCase()}</span>
 }
```

#### Change
Guards against `user.email` being undefined before lowercasing, so users with no email on file no longer crash the profile page.

---

### `src/hooks/useUser.ts` — `@@ -5,3 +5,3 @@`

```diff
@@ -5,3 +5,3 @@ export function useUser(id: string) {
-  const data = await getUser(id)
-  return data
+  const user = await getUser(id)
+  return user
 }
```

#### Change
Renames `data` to `user` so call sites read as `const user = useUser(id)` instead of `const user = useUser(id).data`-style ambiguity.

---

### Mechanical: import path updates

#### Change
14 call sites updated to import from `lib/date` after the move from `utils/date`. No behavior change.
````
