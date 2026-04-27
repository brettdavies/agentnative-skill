#!/usr/bin/env bash
# P6a: SIGPIPE fix in main()
# Without this, piping to `head` panics with "broken pipe".
# Must be first thing in main().
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

main_rs="$SRC_DIR/main.rs"
if [[ ! -f "$main_rs" ]]; then
  emit_result "FAIL" "SIGPIPE fix" "No src/main.rs found"
fi

sigpipe=$(rg -c "SIGPIPE|SIG_DFL" "$main_rs" 2>/dev/null || echo 0)

if [[ "$sigpipe" -gt 0 ]]; then
  emit_result "PASS" "SIGPIPE fix" "SIGPIPE/SIG_DFL handling in main.rs"
else
  emit_result "FAIL" "SIGPIPE fix" "Missing SIGPIPE fix — pipe to head will panic"
fi
