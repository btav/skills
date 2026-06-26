# skills

btav's reusable AI coding workflows.

Works on Claude (`/skill-name`), Codex (`$skill-name`), Gemini (`/skill-name`), and Pi (`/skill:skill-name`).

## Install

```bash
git clone <repo> skills
cd skills
./install.sh
```

Flags: `--target claude|codex|gemini|pi|all` (default `all`), `--force`, `--dry-run`, `-h`.

## Skills

- `btav-commit-message` — Draft a short Conventional Commit subject
- `btav-pr-description` — Draft a PR body
- `btav-hunk-walkthrough` — Walk a diff hunk-by-hunk
- `btav-code-review` — Short, code-heavy review
- `btav-investigate` — Root-cause analysis with ranked hypotheses and evidence
- `btav-improve-writing` — Rewrite prose to be simpler, preserve tone, and remove AI tells
- `btav-review-loop` — Review, fix, and re-review until clean

All are explicit-invocation only — they don't auto-fire on adjacent phrasings.
