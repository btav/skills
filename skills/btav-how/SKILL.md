---
name: btav-how
description: Explain how a feature or subsystem works with a structured walkthrough (Overview, Key concepts, How it works, Where things live, Gotchas), every claim anchored to file:line references. Use only when explicitly invoked.
disable-model-invocation: true
---

# How (code walkthrough)

Invoked explicitly via `/btav-how` in Claude, `$btav-how` in Codex, or `/skill:btav-how` in Pi. Do not auto-fire on adjacent phrasings.

Find the entrypoints. Trace the main flow. Explain with `file:line` receipts. Stop.

Use `btav-why` for the history behind a design; use this for how the code behaves today.

## Input

The user names a feature, subsystem, or behavior — "how does auth work?", "how does a request become a DB row?", "how is the cache invalidated?". If the target is ambiguous or missing, ask one short clarifying question before exploring.

## How to explore

1. **Locate the entrypoints.** Routes, CLI commands, event handlers, cron/queue consumers, exported APIs — wherever the behavior starts.
2. **Trace the primary flow end to end.** Follow the main path from entry to effect. Take branches only when they change the story the reader needs.
3. **Read for explanation, not coverage.** Read enough surrounding code to describe each step in behavioral terms. Don't scan more than ~15 files without signal — if the subsystem is bigger than that, explain the core flow and name what you left out.

If the named subsystem doesn't exist in the repo, say so in one line and stop.

## Output format

````
## Overview
<2–4 sentences: what it does, and the overall shape of how, each with a `file:line` citation>

## Key concepts
- **<Term>** — <one sentence> (`path/to/file.ext:12`)
- …

## How it works
1. <step in behavioral terms> (`path/to/file.ext:34`)
2. <next step> (`path/to/other.ext:8`)
…

## Where things live
- `src/auth/` — <what's here in half a sentence>
- …

## Gotchas
- <surprising behavior, trap, or non-obvious coupling> (`path/to/file.ext:99`)
- …, or "none found"
````

## Rules

- **Every claim is anchored.** Each concept, step, and gotcha cites at least one `file:line` (or a directory for `Where things live`). If you can't anchor it, you haven't verified it — either read the code or drop the claim.
- **Behavioral terms, not narration.** "Rejects expired tokens before the handler runs" beats "calls `verifyToken` inside the middleware chain".
- **Sized to the subject.** A small helper gets a short walkthrough; don't pad sections to fill the template. `Key concepts` and `Gotchas` can be 1–2 entries.
- **Say what you didn't trace.** If a step rests on code you only skimmed, mark it ("not fully traced") rather than smoothing over it.
- **Wrap every code reference in backticks** — paths, identifiers, flags, line numbers.

## What NOT to do

- Don't review. No verdicts, no suggestions, no `issue:` comments — route those to `btav-code-review`.
- Don't propose changes or fixes, even for gotchas. Describe; the reader decides.
- Don't run the code, build, or tests. Reading only.
- Don't explain language or framework basics — the reader is a developer. Explain *this repo's* wiring.
- Don't walk dead code. If two implementations exist, identify the live one and say how you know.

## Style rules

- **No emojis. No "Generated with Claude" footers.**
- Plain language, short sentences, receipts over adjectives.
- Print the walkthrough and stop.

## Worked example

Input: "How does rate limiting work in this API?"

Output:

````
## Overview
Rate limiting is a Redis-backed token bucket applied per API key in Express middleware (`src/middleware/rateLimit.ts:18`). Every request spends one token; buckets refill on a fixed interval, and exhausted buckets return `429` with a `Retry-After` header (`src/middleware/rateLimit.ts:27`, `src/middleware/rateLimit.ts:41`).

## Key concepts
- **Bucket key** — Redis key `rl:<apiKey>`, so limits are per key, not per IP (`src/middleware/rateLimit.ts:18`)
- **Refill interval** — buckets top up to `RL_BURST` every `RL_WINDOW_MS`, defaulting to 100 tokens / 60s (`src/config.ts:31`)

## How it works
1. `app.use(rateLimit)` registers the middleware for every `/api/*` route (`src/server.ts:44`)
2. The middleware runs an atomic Lua script that decrements the bucket and reads the remaining count in one round trip (`src/middleware/rateLimit.ts:27`)
3. A missing bucket is created full, so new API keys start with a complete burst allowance (`src/middleware/rateLimit.ts:33`)
4. On zero tokens the request short-circuits with `429` and `Retry-After` derived from the next refill (`src/middleware/rateLimit.ts:41`)
5. A `setInterval` refill loop tops up all live buckets each window; it runs in-process, not in Redis (`src/middleware/rateLimit.ts:55`)

## Where things live
- `src/middleware/rateLimit.ts` — middleware, Lua script, refill loop
- `src/config.ts` — `RL_BURST` / `RL_WINDOW_MS` env plumbing
- `test/rateLimit.test.ts` — bucket exhaustion and refill tests

## Gotchas
- The refill loop is per-process, so running N replicas refills buckets N times per window — the effective limit scales with replica count (`src/middleware/rateLimit.ts:55`)
- Requests without an API key share the single bucket `rl:anonymous` (`src/middleware/rateLimit.ts:20`)
````
