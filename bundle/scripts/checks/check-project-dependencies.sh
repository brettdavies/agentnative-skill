#!/usr/bin/env bash
# Project: Required Cargo.toml dependencies for agent-native CLI
# All are hard requirements — no partial credit.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

cargo_toml="$REPO_PATH/Cargo.toml"
missing=()

# Required dependencies
rg -q 'clap.*derive' "$cargo_toml" 2>/dev/null || missing+=("clap(derive)")
rg -q 'serde_json' "$cargo_toml" 2>/dev/null || missing+=("serde_json")
rg -q 'thiserror' "$cargo_toml" 2>/dev/null || missing+=("thiserror")
rg -q 'libc' "$cargo_toml" 2>/dev/null || missing+=("libc")
rg -q 'clap_complete' "$cargo_toml" 2>/dev/null || missing+=("clap_complete")

if [[ ${#missing[@]} -eq 0 ]]; then
  emit_result "PASS" "Dependencies" "All required crates present in Cargo.toml"
else
  list=$(IFS=", "; echo "${missing[*]}")
  emit_result "FAIL" "Dependencies" "Missing required crates: $list"
fi
