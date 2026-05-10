# skills

brian's reusable AI coding workflows. Works on Claude (`/skill-name`), Codex (`$skill-name`), and Gemini (`/skill-name`).

## Skills

- `btav-pr-description` — Draft a PR body using Description / Why / Changes with Conventional-Commits prefixes per file.
- `btav-hunk-walkthrough` — Walk a diff hunk-by-hunk with a one-sentence recap and optional lens note.
- `btav-code-review` — Short, code-heavy review using Conventional Comments prefixes with a verdict line.

All are explicit-invocation only — they don't auto-fire on adjacent phrasings.

## Install

```bash
git clone <repo> skills
cd skills
./install.sh
```

Flags: `--target claude|codex|gemini|all` (default `all`), `--force`, `--dry-run`, `-h`.
