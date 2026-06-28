---
name: btav-debt
description: Harvest every `btav:` shortcut comment in the codebase into a debt ledger, so deliberate deferrals get tracked instead of rotting into "later means never". One row per marker, grouped by file, flagging any with no upgrade path. Read-only report.
disable-model-invocation: true
---

# Debt (deferred-shortcut ledger)

Invoked explicitly via `/btav-debt` in Claude, `$btav-debt` in Codex, or `/skill:btav-debt` in Pi. Do not auto-fire on adjacent phrasings.

A deliberate shortcut is marked with a `btav:` comment naming its ceiling and upgrade path. This skill collects those markers into one ledger so a deferral can't quietly become permanent.

The convention is:

```
# btav: <ceiling>, <upgrade path>
```

For example: `# btav: global lock, per-account locks if throughput matters`.

## Scan

Grep the repo for the comment marker, skipping `node_modules`, `.git`, and build output:

```
grep -rnE '(#|//) ?btav:' .
```

Add other comment prefixes (`--`, `;`, `/* */`) if your stack uses them. The `btav:` prefix keeps prose that merely mentions the convention out of the ledger — each grep hit is one ledger row.

## Output format

One row per marker, grouped by file:

```
<file>:<line>, <what was simplified>. ceiling: <the limit named>. upgrade: <the trigger to revisit>.
```

Pull the ceiling and the trigger straight from the comment (`btav: <ceiling>, <upgrade path>`). If the user wants an owner per row, add `git blame -L<line>,<line>`.

Flag the rot risk: any `btav:` comment that names no upgrade path or trigger gets a `no-trigger` tag — those are the ones that silently rot.

End with:

```
<N> markers, <M> with no trigger.
```

If nothing is found, output exactly one line and stop:

```
No btav: debt. Clean ledger.
```

## Boundaries

- **Reads and reports only — changes nothing.** To persist the ledger, the user must ask; only then write it to a file (e.g. `BTAV-DEBT.md`).
- One-shot. Don't run the build, typechecker, linter, or tests.

## Style rules

- One row per marker, grouped by file. No emojis. No "Generated with Claude" footers.

## Worked example

Given two markers in the tree — one with an upgrade path, one without:

```
src/queue.py:88, in-memory queue. ceiling: single process. upgrade: Redis when a second worker is added.
src/cache.ts:14, no expiry on cache entries. no-trigger
2 markers, 1 with no trigger.
```
