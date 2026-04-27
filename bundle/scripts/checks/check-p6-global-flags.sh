#!/usr/bin/env bash
# P6g: Global flags on agentic modifiers
# When a CLI uses subcommands, the four agentic flags (output, quiet,
# no-interactive, timeout) must have global = true so they propagate
# to all subcommands. Without this, agents must discover per-subcommand
# which flags are accepted.
#
# PASS  — no subcommands (not applicable) or global = true present
# FAIL  — subcommands exist but no global = true found
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Check if the CLI uses subcommands
subcommands=$(rg -c "Subcommand|subcommand" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$subcommands" -eq 0 ]]; then
  emit_result "PASS" "Global flags" "No subcommands — not applicable"
fi

# Subcommands exist — check for global = true on flags
global_flags=$(rg -c "global\s*=\s*true" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$global_flags" -ge 2 ]]; then
  emit_result "PASS" "Global flags" "global = true on $global_flags flag(s)"
elif [[ "$global_flags" -eq 1 ]]; then
  emit_result "WARN" "Global flags" "Only 1 global flag — agentic flags (output, quiet, no-interactive, timeout) should all be global"
else
  emit_result "FAIL" "Global flags" "Subcommands present but no global = true — agentic flags won't propagate"
fi
