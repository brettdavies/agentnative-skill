#!/usr/bin/env bash
# P5: Safe retries — --dry-run required
# Every CLI must support --dry-run so agents can preview the effect of
# any command before committing to it. No exceptions based on
# perceived destructiveness.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

dry_run=$(rg -c 'dry.run|dry_run' --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$dry_run" -gt 0 ]]; then
  emit_result "PASS" "Safe retries (--dry-run)" "--dry-run flag found"
else
  emit_result "FAIL" "Safe retries (--dry-run)" "Missing --dry-run flag"
fi
