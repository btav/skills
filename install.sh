#!/usr/bin/env bash
set -euo pipefail

force=0
dry_run=0
target=all

usage() {
  cat <<EOF
Usage: ./install.sh [--target claude|codex|all] [--force] [--dry-run]

Symlinks every directory under ./skills/ into Claude and/or Codex skills dirs.

  --target   Install target: claude, codex, or all. Defaults to all.
  --force    Back up real files/dirs at the destination (to .bak.<timestamp>)
             before linking. Existing symlinks are always replaced.
  --dry-run  Print actions without executing them.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) force=1 ;;
    --dry-run) dry_run=1 ;;
    --target)
      if [ "$#" -lt 2 ]; then
        echo "--target requires one of: claude, codex, all" >&2
        exit 2
      fi
      target="$2"
      shift
      ;;
    --target=*) target="${1#--target=}" ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

case "$target" in
  claude|codex|all) ;;
  *)
    echo "invalid --target: $target (expected claude, codex, or all)" >&2
    exit 2
    ;;
esac

repo_root=$(cd "$(dirname "$0")" && pwd)
src_dir="$repo_root/skills"
claude_dst_dir="$HOME/.claude/skills"
codex_dst_dir="${CODEX_HOME:-$HOME/.codex}/skills"

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

install_target() {
  local label="$1"
  local dst_dir="$2"
  local count=0
  local src name src_abs dst current backup

  echo "==> $label ($dst_dir)"
  run mkdir -p "$dst_dir"

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
}

case "$target" in
  claude)
    install_target "claude" "$claude_dst_dir"
    ;;
  codex)
    install_target "codex" "$codex_dst_dir"
    ;;
  all)
    install_target "claude" "$claude_dst_dir"
    install_target "codex" "$codex_dst_dir"
    ;;
esac
