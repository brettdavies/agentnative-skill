#!/usr/bin/env bash
# P6b: TTY detection
# Canonical: std::io::IsTerminal (stable since Rust 1.70, stdlib).
# Non-canonical: is-terminal crate or deprecated atty crate.
#
# PASS  — std::io::IsTerminal in source (canonical)
# WARN  — is-terminal or atty crate (works but use stdlib)
# FAIL  — no TTY detection
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Tier 1: canonical std::io::IsTerminal (trait import or method call)
stdlib_terminal=$(rg -c "std::io::IsTerminal|use std::io::IsTerminal|\.is_terminal\(\)" \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
if [[ "$stdlib_terminal" -gt 0 ]]; then
  emit_result "PASS" "TTY detection" "std::io::IsTerminal (canonical, stdlib)"
fi

# Tier 2: non-canonical is-terminal crate or deprecated atty
crate_terminal=$(rg -c "is.terminal|IsTerminal" "$REPO_PATH/Cargo.toml" 2>/dev/null || echo 0)
atty_crate=$(rg -c "atty" "$REPO_PATH/Cargo.toml" 2>/dev/null || echo 0)
if [[ $((crate_terminal + atty_crate)) -gt 0 ]]; then
  emit_result "WARN" "TTY detection" "Using crate for TTY detection — migrate to std::io::IsTerminal (Rust 1.70+)"
fi

emit_result "FAIL" "TTY detection" "No TTY detection — use std::io::IsTerminal"
