#!/usr/bin/env bash
# P6f: --timeout for network CLIs
# If a CLI makes HTTP requests, a hung request without a timeout is the
# #1 agent failure mode — the agent waits forever.
#
# PASS  — no network crates (not applicable)
# PASS  — timeout flag or configuration found
# FAIL  — network crates present without timeout support
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Detect network crates in Cargo.toml
network_crates=$(rg -c "reqwest|hyper|ureq|surf|isahc|attohttpc" "$REPO_PATH/Cargo.toml" 2>/dev/null || echo 0)

if [[ "$network_crates" -eq 0 ]]; then
  emit_result "PASS" "Network timeout" "No HTTP crates detected — not applicable"
fi

# Network crates present — check for timeout support
timeout_flag=$(rg -c 'timeout|Timeout|TIMEOUT' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$timeout_flag" -gt 0 ]]; then
  emit_result "PASS" "Network timeout" "--timeout or timeout configuration present"
else
  emit_result "FAIL" "Network timeout" "HTTP crates present but no --timeout flag — agents may hang forever"
fi
