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

- `btav-commit-msg` — Draft a short Conventional Commit subject
- `btav-pr-body` — Draft a PR body
- `btav-diff` — Walk a diff hunk-by-hunk
- `btav-review` — Short, code-heavy review
- `btav-investigate` — Root-cause analysis with ranked hypotheses and evidence
- `btav-unslop` — Rewrite prose to be simpler, preserve tone, and remove AI tells
- `btav-review-loop` — Review, fix, and re-review until clean
- `btav-how` — Explain how a subsystem works, anchored to `file:line`
- `btav-why` — Dig up why code is the way it is from git and PR history
- `btav-blast` — Map what a change could break beyond the diff
- `btav-arena` — Spawn N parallel attempts, pick a base, graft in the best of the rest
- `btav-bro` — Restate the last message in plain language
- `btav-mode` — Session mode that routes tasks to the matching skill above

All are explicit-invocation only — they don't auto-fire on adjacent phrasings, `btav-mode` included.

## `btav-mode`

Pass the task with the invocation so the mode can route it in the same turn:

- Claude: `/btav-mode <task>`
- Codex: `$btav-mode <task>`
- Pi: `/skill:btav-mode <task>`

For repo-wide behavior, load `btav-mode` through the repository's `AGENTS.md` or equivalent global instructions. Only rely on a bare invocation persisting across later turns when the runtime supports it.
