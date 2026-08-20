#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

usage() {
  cat <<EOF
Usage: ./install.sh [--target claude|codex|pi|all] [--force] [--no-prune] [--dry-run]

Symlinks every directory under ./skills/ into Claude, Codex, and/or Pi skills dirs.

  --target    Install target: claude, codex, pi, or all. Defaults to all.
  --force     Back up real files/dirs at the destination (to .bak.<timestamp>)
              before linking. Existing symlinks are always replaced.
  --no-prune  Keep stale links. By default, install first removes broken links
              and btav-* links whose skill is no longer in ./skills/, so renamed
              and deleted skills clean themselves up.
  --dry-run   Print actions without executing them.
EOF
}

parse_args usage "$@"
require_src_dir

install_target() {
  local label="$1"
  local dst_dir="$2"
  local count=0
  local pruned=0
  local src name src_abs dst current backup

  echo "==> $label ($dst_dir)"
  run mkdir -p "$dst_dir"

  if [ "$prune" -eq 1 ]; then
    sweep_target "$dst_dir" prune
    pruned=$swept
  fi

  for src in "$src_dir"/*/; do
    [ -d "$src" ] || continue
    name=$(basename "$src")
    src_abs="${src%/}"
    dst="$dst_dir/$name"

    if [ -L "$dst" ]; then
      current=$(readlink "$dst")
      if [ "$current" = "$src_abs" ]; then
        echo "ok     $name (already linked)"
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
        echo "skip   $name (real file/dir at $dst; rerun with --force to back up)"
        continue
      fi
    else
      echo "link   $name"
      run ln -s "$src_abs" "$dst"
    fi
    count=$((count + 1))
  done

  if [ "$pruned" -gt 0 ]; then
    echo "Pruned $pruned, installed $count skills into $dst_dir"
  else
    echo "Installed $count skills into $dst_dir"
  fi
}

for_each_target install_target
