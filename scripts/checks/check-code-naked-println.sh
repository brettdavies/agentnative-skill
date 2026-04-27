#!/usr/bin/env bash
# Code quality: No naked println! outside main.rs
# All output should go through OutputConfig so --quiet and --output json work.
# main.rs is exempt for meta-commands (version, completions).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

violations=$(rg -c 'println!' --type rust "$SRC_DIR" --glob '!main.rs' 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$violations" -eq 0 ]]; then
  emit_result "PASS" "No naked println!" "println! confined to main.rs"
else
  files=$(rg -l 'println!' --type rust "$SRC_DIR" --glob '!main.rs' 2>/dev/null \
    | xargs -I{} basename {} | paste -sd, -)
  emit_result "FAIL" "No naked println!" "println! found outside main.rs ($violations occurrences): $files"
fi
