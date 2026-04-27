#!/usr/bin/env bash
# Code quality: Env var overrides on agentic flags
# All agentic flags (output, quiet, no-interactive, timeout) must have
# env = "TOOL_*" attributes so agents can set them via environment.
# Boolean env vars must use FalseyValueParser so TOOL_QUIET=0 disables.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Check for env attribute on flags (env = "...")
env_attrs=$(rg -c 'env\s*=\s*"' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

# Check for FalseyValueParser on boolean flags
falsey=$(rg -c 'FalseyValueParser' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$env_attrs" -gt 0 && "$falsey" -gt 0 ]]; then
  emit_result "PASS" "Env flag overrides" "env attributes ($env_attrs) + FalseyValueParser present"
elif [[ "$env_attrs" -gt 0 ]]; then
  emit_result "FAIL" "Env flag overrides" "Has env attrs but missing FalseyValueParser for boolean flags"
else
  emit_result "FAIL" "Env flag overrides" "No env = \"...\" attributes on flags — agents need env var overrides"
fi
