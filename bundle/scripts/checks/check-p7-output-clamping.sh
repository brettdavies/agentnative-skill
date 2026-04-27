#!/usr/bin/env bash
# P7b: Output clamping for bounded responses
# List endpoints must have --limit/--max-results AND .clamp() on values.
# Prevents unbounded API responses from flooding agent context.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

limit_flag=$(rg -c 'long.*=.*"limit"|long.*=.*"max-results"|max.results.*Option' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
clamp_usage=$(rg -c '\.clamp\(' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$limit_flag" -gt 0 && "$clamp_usage" -gt 0 ]]; then
  emit_result "PASS" "Output clamping" "--limit/--max-results with .clamp() present"
elif [[ "$limit_flag" -gt 0 ]]; then
  emit_result "FAIL" "Output clamping" "Has limit flag but missing .clamp() on values"
elif [[ "$clamp_usage" -gt 0 ]]; then
  emit_result "FAIL" "Output clamping" "Has .clamp() but missing --limit/--max-results flag"
else
  emit_result "FAIL" "Output clamping" "No output clamping — add --limit/--max-results with .clamp()"
fi
