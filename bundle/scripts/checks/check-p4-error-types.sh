#!/usr/bin/env bash
# P4a: Structured error types
# Canonical: thiserror crate (standard derive, source chaining, Display for free).
# Non-canonical: manual Error impl with exit_code() method (works but more boilerplate).
#
# PASS  — thiserror in Cargo.toml (canonical)
# WARN  — manual Error impl with exit_code() method (non-canonical)
# FAIL  — neither
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Tier 1: canonical thiserror
thiserror=$(rg -c "thiserror" "$REPO_PATH/Cargo.toml" 2>/dev/null || echo 0)
if [[ "$thiserror" -gt 0 ]]; then
  emit_result "PASS" "Error types" "thiserror in Cargo.toml (canonical)"
fi

# Tier 2: manual Error impl with structured exit codes
manual_error=$(rg -c "fn exit_code|impl.*Display.*for.*Error|impl.*Error.*for" \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
if [[ "$manual_error" -gt 0 ]]; then
  emit_result "WARN" "Error types" "Manual Error impl — migrate to thiserror for standard derive pattern"
fi

emit_result "FAIL" "Error types" "No structured error types — add thiserror to Cargo.toml"
