#!/usr/bin/env bash
set -euo pipefail

force=0
dry_run=0
target=all

usage() {
  cat <<EOF
Usage: ./install.sh [--target claude|codex|gemini|all] [--force] [--dry-run]

Symlinks every directory under ./skills/ into Claude and/or Codex skills dirs,
or packages and installs them for Gemini.

  --target   Install target: claude, codex, gemini, or all. Defaults to all.
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
        echo "--target requires one of: claude, codex, gemini, or all" >&2
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
  gemini|claude|codex|all) ;;
  *)
    echo "invalid --target: $target (expected claude, codex, gemini, or all)" >&2
    exit 2
    ;;
esac

repo_root=$(cd "$(dirname "$0")" && pwd)
src_dir="$repo_root/skills"
claude_dst_dir="$HOME/.claude/skills"
codex_dst_dir="${CODEX_HOME:-$HOME/.codex}/skills"
temp_root=""

cleanup() {
  if [ "$dry_run" -ne 1 ] && [ -n "$temp_root" ]; then
    rm -rf "$temp_root"
  fi
}
trap cleanup EXIT

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

install_gemini_target() {
  local count=0
  local src src_abs name build_dir package_script gemini_root npm_root

  echo "==> gemini (packaging and installing)"

  if [ "$dry_run" -ne 1 ] && ! command -v gemini &>/dev/null; then
    echo "error: gemini CLI not found in PATH" >&2
    exit 1
  fi

  # Attempt to locate package_skill.cjs
  if command -v npm &>/dev/null; then
    npm_root=$(npm root -g 2>/dev/null) || npm_root=""
  else
    npm_root=""
  fi

  if [ -n "$npm_root" ]; then
    gemini_root="$npm_root/@google/gemini-cli"
  else
    gemini_root="/usr/local/lib/node_modules/@google/gemini-cli"
  fi
  package_script="$gemini_root/bundle/builtin/skill-creator/scripts/package_skill.cjs"

  if [ "$dry_run" -ne 1 ] && [ ! -f "$package_script" ]; then
    echo "error: could not find gemini package_skill.cjs at $package_script" >&2
    exit 1
  fi

  if [ "$dry_run" -eq 1 ]; then
    temp_root="/tmp/dry-run-gemini"
    echo "DRY: mktemp -d ($temp_root)"
  else
    temp_root=$(mktemp -d)
  fi

  for src in "$src_dir"/*/; do
    [ -d "$src" ] || continue
    src_abs="${src%/}"
    name=$(basename "$src_abs")
    echo "packaging $name..."

    build_dir="$temp_root/$name"
    run mkdir -p "$build_dir"

    # Copy essential Gemini skill files, excluding Claude-specific 'agents'
    run cp "$src_abs/SKILL.md" "$build_dir/"
    if [ -d "$src_abs/scripts" ]; then run cp -r "$src_abs/scripts" "$build_dir/"; fi
    if [ -d "$src_abs/references" ]; then run cp -r "$src_abs/references" "$build_dir/"; fi
    if [ -d "$src_abs/assets" ]; then run cp -r "$src_abs/assets" "$build_dir/"; fi

    if [ "$dry_run" -eq 1 ]; then
      echo "DRY: node $package_script $build_dir $temp_root"
      echo "DRY: gemini skills install $temp_root/$name.skill --scope user"
    else
      node "$package_script" "$build_dir" "$temp_root" > /dev/null
      gemini skills install "$temp_root/$name.skill" --scope user
    fi

    count=$((count + 1))
  done

  echo "Installed $count skills into Gemini"
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
  gemini)
    install_gemini_target
    ;;
  claude)
    install_target "claude" "$claude_dst_dir"
    ;;
  codex)
    install_target "codex" "$codex_dst_dir"
    ;;
  all)
    if [ "$dry_run" -eq 1 ] || command -v gemini &>/dev/null; then
      install_gemini_target
    else
      echo "==> gemini (skipped: CLI not in PATH)"
    fi
    install_target "claude" "$claude_dst_dir"
    install_target "codex" "$codex_dst_dir"
    ;;
esac
