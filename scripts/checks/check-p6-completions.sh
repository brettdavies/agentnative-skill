#!/usr/bin/env bash
# P6d: Shell completions via clap_complete
# Agents and humans both benefit from shell completions.
# Required as a Cargo dependency.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

clap_complete=$(rg -c "clap_complete" "$REPO_PATH/Cargo.toml" 2>/dev/null || echo 0)

if [[ "$clap_complete" -gt 0 ]]; then
  emit_result "PASS" "Shell completions" "clap_complete in Cargo.toml"
else
  emit_result "FAIL" "Shell completions" "Missing clap_complete dependency"
fi
