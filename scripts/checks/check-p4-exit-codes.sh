#!/usr/bin/env bash
# P4b: Named exit code constants
# Requires named exit codes (EXIT_* constants or exit_code() method),
# not magic numbers scattered in match arms.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Check for named constants (EXIT_SUCCESS, EXIT_AUTH, etc.) or exit_code() method
named_codes=$(rg -c "EXIT_[A-Z]|fn exit_code|exit_code\(\)" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$named_codes" -gt 0 ]]; then
  emit_result "PASS" "Exit codes" "Named exit code constants or exit_code() method found"
else
  emit_result "FAIL" "Exit codes" "No named exit codes — use EXIT_* constants or exit_code() method"
fi
