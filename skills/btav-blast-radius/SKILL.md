---
name: btav-blast-radius
description: Map what a change could break beyond the diff. Affected callers, contracts, and behaviors ranked by risk, each with an honest evidence level. Analysis only, applies nothing. Use only when explicitly invoked.
disable-model-invocation: true
---

# Blast radius

Invoked explicitly via `/btav-blast-radius` in Claude, `$btav-blast-radius` in Codex, or `/skill:btav-blast-radius` in Pi. Do not auto-fire on adjacent phrasings.

Trace the diff outward. Rank what could break. Say how sure you are. Stop.

Use `/btav-code-review` to judge the diff itself; use this to find what the diff can break *elsewhere* — the consumers and contracts the review doesn't look at.

## What to analyze

Pick the source of changes in this order, unless the user specifies otherwise:

1. **A specific PR** if the user named one (`gh pr diff <N>` for the diff, `gh pr view <N>` for the title/body).
2. **Current branch vs the default branch** if you're inside a git repo on a feature branch (`git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD`).
3. **Uncommitted working changes** otherwise (`git diff HEAD`).

If you're unsure which the user meant, ask in one short sentence before analyzing.

Before tracing, read the PR title and description (or the user's framing if it's a local diff). Authorial intent tells you which behavior changes were deliberate, so you can separate an intended contract change from an accidental break.

## How to trace

1. **Inventory the touched surfaces.** For each hunk, note anything something else could depend on: exported signatures, return shapes, error shapes, ordering or timing, config keys and defaults, env vars, CLI flags, persisted formats (schemas, cached blobs, wire formats), public endpoints. Hyrum's Law applies — consumers can depend on any observable behavior, not just the typed contract.
2. **Trace consumers.** Grep and read for callers, importers, subclasses, templates, configs, and tests that encode the old behavior. Follow a concrete call path for `traced` risks; when the trail stops earlier, use `read` or `assumed` and state what would confirm it.
3. **Mark the edge of view.** Consumers you can't see from this repo (other services, published packages, stored data written by old code) are findings, not omissions — list them under `Out of view`.

## Evidence levels

Tag every risk with the strongest level you actually earned:

- `traced` — you followed a concrete path from the change to the consumer and saw the dependency.
- `read` — you read the consumer code but didn't follow the full path.
- `assumed` — inferred from naming or convention; the entry must say what to check to confirm.

Running the code would raise confidence further, but that's out of scope here — the user can ask for it.

## Output format

````
## Change surface
- `path/to/file.ext:12` — <what changed that others can depend on>
- …

## Risks

### 1. <short name> (risk: high | medium | low, evidence: traced | read | assumed)
<1–3 sentences: the mechanism — what breaks, for whom, under what condition.>
- `path/to/consumer.ext:33` — <the dependency you found>

### 2. <short name> (risk: …, evidence: …)
…

## Out of view
- <consumer or system that can't be checked from this repo, and why it matters>, or "none"
````

## Rules

- **Rank risks by severity**, highest first. Cap at 7 — more means you're listing noise, prune.
- **Every `traced` or `read` risk cites at least one `file:line`.** An `assumed` risk states the check that would confirm it.
- **Risk and evidence are independent axes.** A high risk on `assumed` evidence is a legitimate entry — it says "check this first".
- **Don't read more than ~10 files** without finding signal. If nothing outside the diff depends on the changed surfaces, say so and stop.
- **Wrap every code reference in backticks** — paths, identifiers, flags, line numbers.

## What NOT to do

- Don't review the diff itself — no verdicts, no `issue:`/`suggestion:` comments. That's `/btav-code-review`.
- Don't flag risks internal to the diff (a bug in the new code is a review finding, not blast radius).
- Don't propose fixes. The output is a map, not a patch.
- Don't run the build, typechecker, linter, or tests. Reading and reasoning only.
- Don't pad. A change with no external consumers gets a short honest report.

## Style rules

- **No emojis. No "Generated with Claude" footers.**
- Mechanism over adjectives — say *what breaks and for whom*, not "this could be risky".
- Print the report and stop.

## Worked example

Input: a branch that changes `getUser()` to return `null` instead of throwing on a missing user, and renames the `DB_TIMEOUT` env var to `DATABASE_TIMEOUT_MS`.

Output:

````
## Change surface
- `src/api/users.ts:41` — `getUser()` now returns `null` on a missing user instead of throwing `NotFoundError`.
- `src/config.ts:12` — config key renamed `DB_TIMEOUT` → `DATABASE_TIMEOUT_MS`.

## Risks

### 1. Callers relying on the throw now proceed with `null` (risk: high, evidence: traced)
`renderProfile` wraps `getUser` in `try/catch` and treats catch as its 404 path; with the throw gone it dereferences `user.email` and crashes instead.
- `src/pages/profile.ts:27` — `catch (e) { return notFound() }` is the only missing-user handling; `user.email` is read unguarded at line 31.

### 2. Deployed environments still set the old env var (risk: high, evidence: read)
`config.ts` reads only the new name and falls back to `5000`, so every environment defining `DB_TIMEOUT` silently reverts to the default timeout.
- `infra/prod.env:7` — sets `DB_TIMEOUT=30000`; nothing sets `DATABASE_TIMEOUT_MS`.

### 3. Other `getUser` call sites may skip null handling (risk: medium, evidence: assumed)
Twelve call sites import `getUser`; one was traced (risk 1), the rest inferred from grep. Check each for a missing-`null` guard before trusting this is contained.

## Out of view
- The ops runbook and any CI secrets that reference `DB_TIMEOUT` aren't in this repo.
````
