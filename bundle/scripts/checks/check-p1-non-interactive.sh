#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Check for interactive prompt libraries/patterns
interactive_matches=$(rg -c "dialoguer|inquirer|read_line" --type rust "$SRC_DIR" 2>/dev/null | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$interactive_matches" -eq 0 ]]; then
  emit_result "PASS" "Non-interactive" "No interactive prompts found in source"
fi

# Interactive prompts found — check for --no-interactive guard
guard_matches=$(rg -c "no.interactive" --type rust "$SRC_DIR" 2>/dev/null | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$guard_matches" -gt 0 ]]; then
  emit_result "PASS" "Non-interactive" "Interactive prompts gated by --no-interactive flag"
else
  emit_result "FAIL" "Non-interactive" "Interactive prompts found without --no-interactive guard"
fi
