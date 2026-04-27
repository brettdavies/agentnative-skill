#!/usr/bin/env bash
# P3: Progressive help discovery
# Requires all three tiers of clap help text:
#   - about: one-line summary (shown in parent's subcommand list)
#   - long_about: extended description (shown before flags in --help)
#   - after_help: usage examples (shown after flags — where agents look)
# FAIL if after_help or long_about is missing.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

after_help=$(rg -c "after_help|after_long_help" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
long_about=$(rg -c "long_about" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$after_help" -gt 0 && "$long_about" -gt 0 ]]; then
  emit_result "PASS" "Progressive help" "after_help ($after_help) + long_about ($long_about) present"
elif [[ "$after_help" -gt 0 ]]; then
  emit_result "FAIL" "Progressive help" "Has after_help but missing long_about for extended descriptions"
elif [[ "$long_about" -gt 0 ]]; then
  emit_result "FAIL" "Progressive help" "Has long_about but missing after_help with usage examples"
else
  emit_result "FAIL" "Progressive help" "No after_help or long_about — agents cannot discover usage examples"
fi
