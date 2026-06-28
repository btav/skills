---
name: btav-audit
description: Whole-repo audit for over-engineering. Scans the entire codebase rather than a single diff and returns a ranked list of what to delete, simplify, or replace with stdlib/native equivalents. One-shot report, applies nothing.
disable-model-invocation: true
---

# Audit (whole-repo over-engineering)

Invoked explicitly via `/btav-audit` in Claude, `$btav-audit` in Codex, or `/skill:btav-audit` in Pi. Do not auto-fire on adjacent phrasings.

Whole-tree over-engineering pass. Use `/btav-code-review` for normal diff review; use this for repository-wide deletion and simplification opportunities. Scan the codebase and rank findings biggest cut first.

## What to scan

The whole repository tree, skipping `node_modules`, `.git`, vendored code, and build output. Read enough of each candidate to be sure the cut is safe before listing it.

## Hunt

- Dependencies the standard library or platform already ships.
- Single-implementation interfaces and abstract base classes.
- Factories with one product; wrappers that only delegate.
- Files exporting one thing through a layer of indirection.
- Dead flags, config nobody sets, unreachable branches.
- Hand-rolled reimplementations of stdlib functions.

## Output format

One line per finding, ranked biggest cut first:

```
<tag> <what to cut>. <replacement>. [path]
```

Tags:

- `delete:` dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, a layer with one caller.
- `shrink:` same logic, fewer lines. Show the shorter form.

End with:

```
net: -<N> lines, -<M> deps possible.
```

If there is nothing to cut, output exactly one line and stop:

```
Lean already. Ship.
```

## Boundaries

- **Scope is over-engineering and complexity only.** Correctness bugs, security holes, and performance are out of scope — route those to a normal review pass.
- **List findings, apply nothing.** Don't edit files, stage, commit, or push.

## Style rules

- One line per finding, ranked. No paragraphs, no hedging.
- **No emojis. No "Generated with Claude" footers.**
- **Don't run** the build, typechecker, linter, or tests. Print the findings and stop.

## Worked example

Output:

```
delete: src/legacy/PaymentAdapterV1.ts — superseded by V2, no remaining callers. Nothing replaces it. [src/legacy/PaymentAdapterV1.ts]
native: left-pad dependency for one call. String.prototype.padStart, 0 deps. [src/format.ts:14]
yagni: StorageBackend interface with one implementation (S3Storage). Inline it until a second backend exists. [src/storage/index.ts]
shrink: hand-rolled groupBy reduce. Object.groupBy(items, fn), 1 line. [src/util/group.ts:8-22]
net: -210 lines, -1 dep possible.
```
