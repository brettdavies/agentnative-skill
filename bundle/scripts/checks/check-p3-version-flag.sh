#!/usr/bin/env bash
# P3b: --version flag
# Agents need to know what version they're running for compatibility.
# clap provides this for free with #[command(version)] on the derive.
#
# PASS  — version attribute or #[command(version)] found
# FAIL  — no version support detected
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Check for clap version support:
# - #[command(version)] or #[command(version, ...)] in derive attributes
# - version = in Cli struct clap attributes
# - Version variant in Commands enum (subcommand)
# - CARGO_PKG_VERSION usage (manual version output)
version_support=$(rg -c 'command.*version|version\s*=|Version|CARGO_PKG_VERSION' \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$version_support" -gt 0 ]]; then
  emit_result "PASS" "Version flag" "--version or version subcommand present"
else
  emit_result "FAIL" "Version flag" "No --version support — add #[command(version)] to clap derive"
fi
