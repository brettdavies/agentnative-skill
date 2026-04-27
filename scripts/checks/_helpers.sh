#!/usr/bin/env bash
# Shared helpers for agent-native-cli compliance checks.
# Source this file — do not execute directly.

set -euo pipefail

emit_result() {
  local status="$1" label="$2" evidence="$3"
  echo "${status}|${label}|${evidence}"
  case "$status" in
    PASS) exit 0 ;;
    WARN) exit 1 ;;
    FAIL) exit 2 ;;
    *) echo "BUG: unknown status '$status'" >&2; exit 2 ;;
  esac
}

validate_repo_path() {
  if [[ -z "${1:-}" ]]; then
    echo "Usage: $(basename "$0") <repo-path>" >&2
    exit 2
  fi
  if [[ ! -d "$1" ]]; then
    echo "Error: '$1' is not a directory" >&2
    exit 2
  fi
  if [[ ! -d "$1/src" ]]; then
    echo "Error: '$1/src' not found — is this a Rust project?" >&2
    exit 2
  fi
}

validate_repo_path "${1:-}"
REPO_PATH="$1"
SRC_DIR="$REPO_PATH/src"
