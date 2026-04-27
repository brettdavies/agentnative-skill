#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Signal 1: Output format enum/flag
format_flag=$(rg -c "OutputFormat|ValueEnum.*Text.*Json|output.*json.*jsonl" --type rust "$SRC_DIR" 2>/dev/null | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

# Signal 2: serde_json dependency
serde_json=$(rg -c "serde_json" "$REPO_PATH/Cargo.toml" 2>/dev/null || echo 0)

if [[ "$format_flag" -gt 0 && "$serde_json" -gt 0 ]]; then
  emit_result "PASS" "Structured output" "OutputFormat enum + serde_json present"
elif [[ "$serde_json" -gt 0 ]]; then
  emit_result "WARN" "Structured output" "serde_json present but no OutputFormat enum found"
else
  emit_result "FAIL" "Structured output" "No structured output support (missing OutputFormat and serde_json)"
fi
