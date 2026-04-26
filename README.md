# claude-skills

brian's claude skills

## What's in here

| Skill | Invoke | What it does |
|---|---|---|
| `btav-pr-description` | `/btav-pr-description` | Draft a PR body using a fixed three-section template — Description / Why / Changes — with Conventional-Commits prefixes per file. |
| `btav-hunk-walkthrough` | `/btav-hunk-walkthrough` | Walk a diff hunk-by-hunk with a one-sentence behavior recap per hunk and an optional lens note (YAGNI / DRY / Hyrum / Demeter / premature opt / broken windows). |
| `btav-code-review` | `/btav-code-review` | Short, code-heavy review of a diff / branch / PR using Conventional Comments prefixes (issue / suggestion / question / nitpick / praise) with a final verdict line. |

All are **explicit-invocation only** — they do not auto-fire on adjacent phrasings. Type the slash command.

## Install

```bash
git clone <repo>
cd claude-skills
./install.sh
```

### What `install.sh` does

- Creates `~/.claude/skills/` if missing.
- For each directory under `./skills/`, creates a symlink at `~/.claude/skills/<name>` → the absolute path of the source in this repo.
- Idempotent: re-running prints `ok` for already-linked skills and skips them.
- Replaces *symlinks* that point elsewhere automatically (`relink`).
- Refuses to overwrite *real* files/dirs at the destination unless `--force` is passed.

### Flags

- `--force` — back up a real file or dir at the destination to `<name>.bak.<timestamp>` before linking.
- `--dry-run` — print actions prefixed `DRY:` without executing them.
- `-h` / `--help` — print usage and exit.

### Why symlinks

Editing a `SKILL.md` in this repo is reflected immediately in `~/.claude/skills/<name>/` — no reinstall needed. `git pull` is enough to update.

## Uninstall

```bash
rm ~/.claude/skills/btav-pr-description
rm ~/.claude/skills/btav-hunk-walkthrough
rm ~/.claude/skills/btav-code-review
```

Removing a symlink does not touch the source in this repo.

## Adding a new skill

1. Create `skills/<your-skill-name>/SKILL.md` with frontmatter (`name`, `description`).
2. Run `./install.sh` again — it picks up the new directory and links it.
