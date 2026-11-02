# skills

btav's reusable AI coding workflows.

Works on Claude (`/skill-name`), Codex (`$skill-name`), and Pi (`/skill:skill-name`).

## Install

```bash
git clone <repo> skills
cd skills
./install.sh
```

Flags: `--target claude|codex|pi|all` (default `all`), `--force`, `--no-prune`, `--dry-run`, `-h`.

Install prunes stale `btav-*` symlinks by default; pass `--no-prune` to keep them.

`./uninstall.sh` removes every link this repo installed. Same `--target` and `--dry-run`
flags.

## Skills

- `btav-spec` — Develop a product spec with the user, then a connected technical design
- `btav-deliver` — Implement ready specs, verify acceptance, review, and hand back local changes
- `btav-commit-msg` — Draft a short Conventional Commit subject
- `btav-pr-body` — Draft a problem-first PR body with available verification evidence
- `btav-diff` — Walk a diff hunk-by-hunk
- `btav-review` — Summarize every changed file, then review code with clear locations, problems, and fixes
- `btav-investigate` — Root-cause analysis with ranked hypotheses and evidence
- `btav-unslop` — Rewrite prose to be simpler, preserve tone, and remove AI tells
- `btav-plain` — Check a document against the four ISO 24495-1 plain language principles
- `btav-review-loop` — Review, fix, and run focused checks, reporting review and verification separately
- `btav-how` — Explain how a subsystem works, anchored to `file:line`
- `btav-why` — Dig up why code is the way it is from git and PR history
- `btav-blast` — Map affected callers, contracts, and stale assumptions beyond the diff
- `btav-bro` — Restate the last message in plain language
- `btav-mode` — Session mode that routes tasks to the matching skill above

All are explicit-invocation only — they don't auto-fire on adjacent phrasings, `btav-mode` included.

## Specify and deliver

Use `btav-spec` for one feature or fix. Settle the product behaviors, invariants, and acceptance scenarios first, then develop the architecture and code shape. Specs default to `docs/specs/<change>/product.md` and `tech.md` in the target repository, unless the project has an established convention or you supply a location.

| Harness | Specify | Deliver or resume |
|---|---|---|
| Claude | `/btav-spec <request>` | `/btav-deliver <spec-directory>` |
| Codex | `$btav-spec <request>` | `$btav-deliver <spec-directory>` |
| Pi | `/skill:btav-spec <request>` | `/skill:btav-deliver <spec-directory>` |

`btav-deliver` requires ready product and tech specs, a Git checkout with a valid review base, and discoverable project checks. It implements the change, verifies acceptance and required checks, and uses `btav-review-loop` for fresh review and fixes. Fresh reviewers must be available for the normal review loop; missing capabilities or environment requirements are reported as gaps.

Specs are versioned project documents. Delivery progress and evidence stay in local Git metadata, resolved with `git rev-parse --git-path btav/<change>/progress.md`. Repeating delivery inspects the current repository and saved record before resuming; stale evidence is refreshed and exhausted loops do not silently restart. The record is recovery context, not an unattended runner.

Delivery finishes with local changes, separate review and verification results, and drafted PR text. You handle staging, commits, publishing, merging, and deployment. Native plan mode still controls permitted actions: specs can be drafted in conversation, but saving them and implementing code wait until writes are allowed. No skill changes harness modes automatically.

## `btav-mode`

Pass the task with the invocation so the mode can route it in the same turn:

- Claude: `/btav-mode <task>`
- Codex: `$btav-mode <task>`
- Pi: `/skill:btav-mode <task>`

For repo-wide behavior, load `btav-mode` through the repository's `AGENTS.md` or equivalent global instructions. Only rely on a bare invocation persisting across later turns when the runtime supports it.
