#!/usr/bin/env bash
# P1b: Headless auth (device-code / no-browser flow)
# If a CLI has authentication, agents cannot open browsers for OAuth.
#
# Canonical flag: --no-browser (describes the constraint, not the mechanism).
#
# PASS  — no auth detected (not applicable)
# PASS  — --no-browser flag present (canonical)
# WARN  — non-canonical alternative (--device-code, --remote, --headless)
# WARN  — auth delegated to subprocess (passthrough/Command spawning auth)
# FAIL  — auth present, no headless flow, no delegation
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Detect auth-related code (OAuth, login, token management)
auth_patterns=$(rg -c "oauth|OAuth|auth.*login|login.*auth|token.*store|credential|authenticate" \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)

if [[ "$auth_patterns" -eq 0 ]]; then
  emit_result "PASS" "Headless auth" "No auth detected — not applicable"
fi

# Tier 1: canonical --no-browser flag
canonical=$(rg -c "no.browser|no_browser" --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
if [[ "$canonical" -gt 0 ]]; then
  emit_result "PASS" "Headless auth" "Canonical --no-browser flag present"
fi

# Tier 2: non-canonical headless alternatives
alt=$(rg -c "device.code|DeviceCode|device_authorization|headless" \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
if [[ "$alt" -gt 0 ]]; then
  emit_result "WARN" "Headless auth" "Non-canonical headless auth — rename to --no-browser"
fi

# Tier 3: auth delegated to subprocess (passthrough/Command spawning auth)
delegated=$(rg -c 'passthrough.*auth|auth.*passthrough|Command::new.*auth|spawn.*"auth"' \
  --type rust "$SRC_DIR" 2>/dev/null \
  | cut -d: -f2 | paste -sd+ - | bc 2>/dev/null || echo 0)
if [[ "$delegated" -gt 0 ]]; then
  emit_result "WARN" "Headless auth" "Auth delegated to subprocess — expose --no-browser or document external auth"
fi

emit_result "FAIL" "Headless auth" "Auth detected but no headless flow — agents cannot open browsers"
