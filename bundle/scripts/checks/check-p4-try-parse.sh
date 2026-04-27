#!/usr/bin/env bash
# P4c: try_parse() instead of parse()
# Cli::parse() calls process::exit() on error, bypassing custom error handlers.
# Canonical: try_parse() — the standard clap method for fallible parsing.
# Non-canonical: from_arg_matches() — equally safe but more manual.
#
# PASS  — try_parse() in main.rs (canonical)
# WARN  — from_arg_matches() in main.rs (safe but non-canonical)
# FAIL  — neither (using bare parse())
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

main_rs="$SRC_DIR/main.rs"
if [[ ! -f "$main_rs" ]]; then
  emit_result "FAIL" "try_parse" "No src/main.rs found"
fi

# Tier 1: canonical try_parse()
try_parse=$(rg -c "try_parse" "$main_rs" 2>/dev/null || echo 0)
if [[ "$try_parse" -gt 0 ]]; then
  emit_result "PASS" "try_parse" "try_parse() in main.rs (canonical)"
fi

# Tier 2: non-canonical from_arg_matches() (safe but more manual)
from_arg=$(rg -c "from_arg_matches" "$main_rs" 2>/dev/null || echo 0)
if [[ "$from_arg" -gt 0 ]]; then
  emit_result "WARN" "try_parse" "from_arg_matches() used — migrate to try_parse() for simplicity"
fi

emit_result "FAIL" "try_parse" "Missing try_parse() — parse() bypasses custom error handlers"
