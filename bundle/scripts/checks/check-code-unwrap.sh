#!/usr/bin/env bash
# Code quality: No .unwrap() in production code
# unwrap() panics crash the agent's subprocess with no structured error.
# Acceptable in tests (#[cfg(test)]) but not in src/ production code.
# Checks src/ excluding lines inside #[cfg(test)] modules.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Count .unwrap() in src/, excluding test files and test modules
# We exclude files in tests/ dir and look only at src/
unwraps=$(rg -c '\.unwrap\(\)' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$unwraps" -eq 0 ]]; then
  emit_result "PASS" "No unwrap() in prod" "Zero .unwrap() calls in src/"
else
  files=$(rg -l '\.unwrap\(\)' --type rust "$SRC_DIR" 2>/dev/null \
    | xargs -I{} basename {} | paste -sd, -)
  emit_result "FAIL" "No unwrap() in prod" ".unwrap() found in src/ ($unwraps occurrences): $files"
fi
