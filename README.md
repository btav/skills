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

- `btav-pr-description` — Draft a PR body
- `btav-hunk-walkthrough` — Walk a diff hunk-by-hunk
- `btav-code-review` — Short, code-heavy review

All are explicit-invocation only — they don't auto-fire on adjacent phrasings.
