#!/usr/bin/env bash
# Shared plumbing for install.sh and uninstall.sh.
#
# Both scripts must agree on the destination directories forever, so the paths,
# the flag parsing, and the symlink removal loop live here rather than being
# duplicated and drifting apart.

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src_dir="$repo_root/skills"
claude_dst_dir="$HOME/.claude/skills"
codex_dst_dir="${CODEX_HOME:-$HOME/.codex}/skills"
pi_dst_dir="$HOME/.pi/agent/skills"

force=0
dry_run=0
prune=1
target=all

require_src_dir() {
  if [ ! -d "$src_dir" ]; then
    echo "no skills/ directory at $src_dir" >&2
    exit 1
  fi
}

# parse_args <usage-fn> "$@"
#
# Accepts the flags common to both scripts. --force and --no-prune are only
# meaningful to install.sh, but parsing them here keeps one arg loop.
parse_args() {
  local usage_fn="$1"
  shift

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force) force=1 ;;
      --dry-run) dry_run=1 ;;
      --no-prune) prune=0 ;;
      --target)
        if [ "$#" -lt 2 ]; then
          echo "--target requires one of: claude, codex, pi, or all" >&2
          exit 2
        fi
        target="$2"
        shift
        ;;
      --target=*) target="${1#--target=}" ;;
      -h|--help)
        "$usage_fn"
        exit 0
        ;;
      *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
  done

  case "$target" in
    claude|codex|pi|all) ;;
    *)
      echo "invalid --target: $target (expected claude, codex, pi, or all)" >&2
      exit 2
      ;;
  esac
}

run() {
  if [ "$dry_run" -eq 1 ]; then
    echo "DRY: $*"
  else
    "$@"
  fi
}

# for_each_target <fn>
#
# Calls fn <label> <dst_dir> for every destination the --target flag selected.
for_each_target() {
  local fn="$1"

  case "$target" in
    claude) "$fn" "claude" "$claude_dst_dir" ;;
    codex)  "$fn" "codex" "$codex_dst_dir" ;;
    pi)     "$fn" "pi" "$pi_dst_dir" ;;
    all)
      "$fn" "claude" "$claude_dst_dir"
      "$fn" "codex" "$codex_dst_dir"
      "$fn" "pi" "$pi_dst_dir"
      ;;
  esac
}

# sweep_target <dst_dir> <mode>
#
# Removes symlinks this repo is responsible for. Sets `swept` to the count.
#
#   prune  broken links, plus live btav-* links whose skill no longer exists
#          in skills/ (a renamed or deleted skill)
#   all    the above, plus every link matching a skill currently in skills/
#
# Only ever removes symlinks, and only the link itself -- real directories at
# the destination (skills installed by other means) are left alone, and the
# link target is never touched.
sweep_target() {
  local dst_dir="$1"
  local mode="$2"
  local entry name reason link_target

  swept=0
  [ -d "$dst_dir" ] || return 0

  for entry in "$dst_dir"/*; do
    # Skips the literal glob when the directory is empty, and skips real
    # files and directories. Everything past here is a symlink.
    [ -L "$entry" ] || continue

    name=$(basename "$entry")
    reason=""
    link_target=$(readlink "$entry")

    case "$link_target" in
      "$src_dir"/*) ;;
      *) continue ;;
    esac

    if [ ! -e "$entry" ]; then
      # -e follows the link, so this is false exactly for broken links.
      reason="broken -> $(readlink "$entry")"
    elif [ "$mode" = "all" ] && [ -d "$src_dir/$name" ]; then
      reason="installed by this repo"
    elif [ "${name#btav-}" != "$name" ] && [ ! -d "$src_dir/$name" ]; then
      reason="no longer in skills/"
    else
      continue
    fi

    echo "remove $name ($reason)"
    run rm "$entry"
    swept=$((swept + 1))
  done
}
