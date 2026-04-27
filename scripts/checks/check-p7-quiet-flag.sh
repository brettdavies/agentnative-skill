#!/usr/bin/env bash
# P7a: --quiet flag definition
# Required for agents to suppress non-essential output.
# Searches for the flag definition, not propagation sites.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

quiet_def=$(rg -c 'long.*=.*"quiet"|short.*q.*quiet|pub\s+quiet.*bool' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$quiet_def" -gt 0 ]]; then
  emit_result "PASS" "Quiet flag" "--quiet flag defined"
else
  emit_result "FAIL" "Quiet flag" "Missing --quiet flag definition"
fi
