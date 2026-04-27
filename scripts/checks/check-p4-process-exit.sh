#!/usr/bin/env bash
# P4d: No process::exit() outside main.rs
# Library code calling process::exit() skips destructors and error formatting.
# Only main.rs may call process::exit() or return ExitCode.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Search all .rs files except main.rs for process::exit
violations=$(rg -c "process::exit" --type rust "$SRC_DIR" --glob '!main.rs' 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$violations" -eq 0 ]]; then
  emit_result "PASS" "No process::exit leaks" "process::exit() confined to main.rs"
else
  files=$(rg -l "process::exit" --type rust "$SRC_DIR" --glob '!main.rs' 2>/dev/null \
    | xargs -I{} basename {} | paste -sd, -)
  emit_result "FAIL" "No process::exit leaks" "process::exit() found outside main.rs: $files"
fi
