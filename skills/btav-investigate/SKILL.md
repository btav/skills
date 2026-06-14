---
name: btav-investigate
description: Given a symptom (error, stack trace, failing test, unexpected behavior), trace relevant code paths and produce a structured root-cause analysis with ranked hypotheses and evidence.
disable-model-invocation: true
---

# Investigate

Invoked explicitly via `/btav-investigate` in Claude, `$btav-investigate` in Codex, or `/skill:btav-investigate` in Pi. Do not auto-fire on adjacent phrasings.

Trace the problem. Rank hypotheses. Show evidence. Stop before fixing.

## Input

The user provides a **symptom** — one or more of:

- An error message or stack trace
- A failing test name or output
- A description of unexpected behavior ("X returns Y instead of Z")
- A regression ("this worked before commit abc123")

If the symptom is ambiguous or missing, ask one short clarifying question before investigating.

## How to investigate

1. **Reproduce the path.** Starting from the symptom (error site, test assertion, user-facing behavior), read the relevant source files and trace the execution path backward. Follow imports, callers, and data flow — not just the crash site.

2. **Scope aggressively.** Read only what the evidence trail demands. Don't scan the whole repo. If a path dead-ends (code is unreachable, unrelated to the symptom), abandon it and say so.

3. **Collect evidence.** Every claim in your output must reference a specific `file:line` or concrete observation (e.g. "the env var is unset in the test harness"). No hand-waving.

4. **Generate hypotheses.** Rank by likelihood given the evidence you found. You're allowed to have one hypothesis. You're allowed to be wrong — but flag your confidence honestly.

5. **Stop before fixing.** Don't write patches, don't run tests, don't refactor. The user decides what to do with your analysis.

## Output format

````
## Symptom
<1–2 sentences restating the problem in precise terms>

## Evidence trail
- `path/to/file.ext:42` — <what you observed and why it matters>
- `path/to/other.ext:17` — <what you observed>
- …

## Hypotheses

### 1. <short name> (confidence: high | medium | low)
<2–3 sentences explaining the mechanism — how this cause produces the observed symptom.>

Evidence for:
- <bullet referencing a trail entry above>

Evidence against / unknown:
- <bullet, or "none">

### 2. <short name> (confidence: …)
…

## Suggested next steps
- <1–3 bullets: what to check, test, or instrument to confirm/eliminate hypotheses>
````

## Rules

- **Evidence trail is mandatory.** No hypothesis without at least one `file:line` or concrete observation supporting it. If you can't find evidence, say "I couldn't trace this further because…" and stop.
- **Rank hypotheses by likelihood**, most likely first. One hypothesis is fine — don't invent alternatives for symmetry.
- **Confidence is honest.** `high` = the evidence strongly supports this and you'd bet on it. `medium` = plausible but you'd want to verify one thing. `low` = possible but speculative.
- **Cap at 3 hypotheses.** If you have more, you haven't scoped enough — re-read the evidence and prune.
- **Don't read more than ~10 files** without finding signal. If the trail goes cold, report what you found and what you'd need (logs, runtime state, repro steps) to continue.
- **Wrap every code reference in backticks** — file paths, function names, variables, line numbers.
- **"Suggested next steps" are verification actions**, not fixes. "Add a log at `X:42` to confirm `user` is null at that point" — not "add a null check."

## What NOT to do

- Don't write patches or suggest code changes. The output is *analysis*, not *fix*.
- Don't run the code, tests, build, or linter. You're reading and reasoning only.
- Don't speculate beyond what the code shows. If the bug requires runtime state you can't see (env vars, DB contents, race timing), say so in "Evidence against / unknown."
- Don't pad. If the root cause is obvious from a 2-entry evidence trail and one hypothesis, that's a valid (short) output.
- Don't blame external dependencies without evidence. "Maybe it's a bug in React" is not a hypothesis unless you can point at a known issue.

## Style rules

- **No emojis.** No preamble. No "Generated with Claude" footer.
- **Show paths, not prose.** The evidence trail is the spine — hypotheses just connect the dots.
- **One mechanism per hypothesis.** If you're describing two different failure modes, they're two hypotheses.
- **Plain language in hypotheses.** The reader is a developer who knows the codebase — don't over-explain language features. Do explain non-obvious interactions between components.

## Worked example

Input: "Our `/api/users/:id` endpoint returns 500 in production but works locally. Started after last Friday's deploy."

Output:

````
## Symptom
`GET /api/users/:id` returns HTTP 500 in production. Works locally. Regressed after the deploy on 2024-01-12.

## Evidence trail
- `src/api/users.ts:38` — `getUser()` calls `db.query()` with `{ timeout: config.DB_TIMEOUT }`.
- `src/config.ts:12` — `DB_TIMEOUT` reads from `process.env.DB_TIMEOUT`, falls back to `5000`.
- `infra/prod.env:7` — `DB_TIMEOUT=5s` (string, not a number).
- `src/db/client.ts:55` — `query()` passes `timeout` directly to the pg driver, which expects milliseconds as a number. A string value causes it to throw `TypeError: timeout.toFixed is not a function`.
- `git log --oneline -5` — commit `a3f9c12` (Friday) added `DB_TIMEOUT` to `prod.env` for the first time.

## Hypotheses

### 1. `DB_TIMEOUT` is a string in prod env, pg driver expects a number (confidence: high)
`prod.env` sets `DB_TIMEOUT=5s`. `config.ts:12` reads it raw with no `parseInt`. The pg driver at `db/client.ts:55` calls `.toFixed()` on the timeout value, which throws on a string. Locally this works because the env var is unset and the fallback `5000` is numeric.

Evidence for:
- `prod.env:7` contains `5s` (string with unit suffix)
- `config.ts:12` has no numeric coercion
- `db/client.ts:55` uses the value in a numeric context

Evidence against / unknown:
- Haven't confirmed the exact error message in prod logs matches `TypeError: timeout.toFixed is not a function`

## Suggested next steps
- Check prod error logs for the exact exception at `db/client.ts:55` to confirm it's the `.toFixed` TypeError.
- If confirmed, decide whether to fix in `config.ts` (parse to int) or `prod.env` (remove the `s` suffix). Either works.
````
