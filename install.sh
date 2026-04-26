#!/usr/bin/env bash
set -euo pipefail

force=0
dry_run=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --dry-run) dry_run=1 ;;
    -h|--help)
      cat <<EOF
Usage: ./install.sh [--force] [--dry-run]

Symlinks every directory under ./skills/ into ~/.claude/skills/.

  --force    Back up real files/dirs at the destination (to .bak.<timestamp>)
             before linking. Existing symlinks are always replaced.
  --dry-run  Print actions without executing them.
EOF
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

repo_root=$(cd "$(dirname "$0")" && pwd)
src_dir="$repo_root/skills"
dst_dir="$HOME/.claude/skills"

if [ ! -d "$src_dir" ]; then
  echo "no skills/ directory at $src_dir" >&2
  exit 1
fi

run() {
  if [ "$dry_run" -eq 1 ]; then
    echo "DRY: $*"
  else
    "$@"
  fi
}

run mkdir -p "$dst_dir"

count=0
for src in "$src_dir"/*/; do
  [ -d "$src" ] || continue
  name=$(basename "$src")
  src_abs="${src%/}"
  dst="$dst_dir/$name"

  if [ -L "$dst" ]; then
    current=$(readlink "$dst")
    if [ "$current" = "$src_abs" ]; then
      echo "ok    $name (already linked)"
      count=$((count + 1))
      continue
    fi
    echo "relink $name (was -> $current)"
    run ln -sfn "$src_abs" "$dst"
  elif [ -e "$dst" ]; then
    if [ "$force" -eq 1 ]; then
      backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
      echo "backup $name -> $(basename "$backup")"
      run mv "$dst" "$backup"
      run ln -s "$src_abs" "$dst"
    else
      echo "skip  $name (real file/dir at $dst; rerun with --force to back up)"
      continue
    fi
  else
    echo "link  $name"
    run ln -s "$src_abs" "$dst"
  fi
  count=$((count + 1))
done

echo "Installed $count skills into $dst_dir"
