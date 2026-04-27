#!/usr/bin/env bash
# P6c: NO_COLOR environment variable support
# https://no-color.org/ — independent of TTY detection.
# When NO_COLOR is set, all ANSI color output must be suppressed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

no_color=$(rg -c "NO_COLOR" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$no_color" -gt 0 ]]; then
  emit_result "PASS" "NO_COLOR support" "NO_COLOR env var checked in source"
else
  emit_result "FAIL" "NO_COLOR support" "Missing NO_COLOR check — see no-color.org"
fi
