# skills

btav's reusable AI coding workflows.

Works on Claude (`/skill-name`), Codex (`$skill-name`), and Pi (`/skill:skill-name`).

## Install

```bash
git clone <repo> skills
cd skills
./install.sh
```

Flags: `--target claude|codex|pi|all` (default `all`), `--force`, `--dry-run`, `-h`.

## Skills

- `btav-commit-message` — Draft a short Conventional Commit subject
- `btav-pr-description` — Draft a PR body
- `btav-hunk-walkthrough` — Walk a diff hunk-by-hunk
- `btav-code-review` — Short, code-heavy review
- `btav-investigate` — Root-cause analysis with ranked hypotheses and evidence
- `btav-improve-writing` — Rewrite prose to be simpler, preserve tone, and remove AI tells
- `btav-review-loop` — Review, fix, and re-review until clean
- `btav-how` — Explain how a subsystem works, anchored to `file:line`
- `btav-why` — Dig up why code is the way it is from git and PR history
- `btav-blast-radius` — Map what a change could break beyond the diff
- `btav-mode` — Session mode that routes tasks to the matching skill above

All are explicit-invocation only — they don't auto-fire on adjacent phrasings, `btav-mode` included. But once `btav-mode` is active, it routes a matching task to the right skill without you naming it.
