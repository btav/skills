#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

usage() {
  cat <<EOF
Usage: ./uninstall.sh [--target claude|codex|pi|all] [--dry-run]

Removes the symlinks install.sh created from Claude, Codex, and/or Pi skills dirs.
Also clears broken links and btav-* links whose skill is no longer in ./skills/.
Real files and directories at the destination are never touched.

  --target   Target: claude, codex, pi, or all. Defaults to all.
  --dry-run  Print actions without executing them.
EOF
}

parse_args usage "$@"
require_src_dir

uninstall_target() {
  local label="$1"
  local dst_dir="$2"

  echo "==> $label ($dst_dir)"
  sweep_target "$dst_dir" all
  echo "Removed $swept links from $dst_dir"
}

for_each_target uninstall_target
