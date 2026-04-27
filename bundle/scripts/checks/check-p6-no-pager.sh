#!/usr/bin/env bash
# P6e: No pager in headless environments
# If a CLI uses a pager (less, more, PAGER), it must have a --no-pager
# flag or respect PAGER="" to disable. A pager blocks headless execution
# indefinitely — the agent waits for input that never comes.
#
# PASS if no pager usage detected (not applicable).
# PASS if pager detected AND disable mechanism present.
# FAIL if pager detected WITHOUT disable mechanism.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Detect pager usage (spawning less/more, reading PAGER env, pager crate)
pager_usage=$(rg -c 'pager|::less|"less"|"more"|Command::new.*less|spawn.*pager' \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$pager_usage" -eq 0 ]]; then
  emit_result "PASS" "No pager blocking" "No pager usage detected — not applicable"
fi

# Pager exists — check for disable mechanism
disable=$(rg -c 'no.pager|no_pager|NO_PAGER|PAGER.*""' \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$disable" -gt 0 ]]; then
  emit_result "PASS" "No pager blocking" "Pager with --no-pager or PAGER disable mechanism"
else
  emit_result "FAIL" "No pager blocking" "Pager detected without disable mechanism — blocks headless execution"
fi
