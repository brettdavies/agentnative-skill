#!/usr/bin/env bash
# Agent-native CLI compliance checker — orchestrator.
#
# Discovers and runs all check-*.sh scripts in scripts/checks/, parses their
# STATUS|LABEL|EVIDENCE output, and produces a grouped scorecard.
#
# Usage:
#   check-compliance.sh <repo-path>                  # Run all checks
#   check-compliance.sh <repo-path> --principle N    # Run only check-pN
#
# Exit codes:
#   0 = all PASS
#   1 = any WARN (no FAIL)
#   2 = any FAIL
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="$SCRIPT_DIR/checks"

# --- Argument parsing ---
REPO_PATH=""
PRINCIPLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --principle)
      PRINCIPLE="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Usage: $(basename "$0") <repo-path> [--principle N]" >&2
      exit 2
      ;;
    *)
      REPO_PATH="$1"
      shift
      ;;
  esac
done

if [[ -z "$REPO_PATH" ]]; then
  echo "Usage: $(basename "$0") <repo-path> [--principle N]" >&2
  exit 2
fi

if [[ ! -d "$REPO_PATH" ]]; then
  echo "Error: '$REPO_PATH' is not a directory" >&2
  exit 2
fi

# Require Cargo.toml (Rust projects only for now)
if [[ ! -f "$REPO_PATH/Cargo.toml" ]]; then
  echo "Error: No Cargo.toml found in '$REPO_PATH'" >&2
  echo "  This checker currently supports Rust projects only." >&2
  echo "  Non-Rust support can be added when needed." >&2
  exit 2
fi

# --- Group definitions (display order) ---
# Maps group prefix to display name. Checks are grouped by filename prefix.
declare -a GROUP_ORDER=("p1" "p2" "p3" "p4" "p5" "p6" "p7" "code" "project")
declare -A GROUP_NAMES=(
  [p1]="P1: Non-Interactive"
  [p2]="P2: Structured Output"
  [p3]="P3: Progressive Help"
  [p4]="P4: Actionable Errors"
  [p5]="P5: Safe Retries"
  [p6]="P6: Composable Structure"
  [p7]="P7: Bounded Responses"
  [code]="Code Quality"
  [project]="Project Structure"
)

# --- Discover checks ---
checks=()
if [[ -n "$PRINCIPLE" ]]; then
  # Single principle mode
  target="$CHECKS_DIR/check-p${PRINCIPLE}-"*.sh
  # shellcheck disable=SC2086
  for f in $target; do
    if [[ -f "$f" ]]; then
      checks+=("$f")
    else
      echo "Error: No check script found for principle $PRINCIPLE" >&2
      echo "  Expected: $CHECKS_DIR/check-p${PRINCIPLE}-*.sh" >&2
      exit 2
    fi
  done
else
  # All checks mode — glob for check-*.sh (excludes _helpers.sh by prefix convention)
  for f in "$CHECKS_DIR"/check-*.sh; do
    [[ -f "$f" ]] && checks+=("$f")
  done
fi

if [[ ${#checks[@]} -eq 0 ]]; then
  echo "Error: No check scripts found in $CHECKS_DIR" >&2
  exit 2
fi

# --- Extract group from check filename ---
# check-p1-foo.sh → p1, check-code-bar.sh → code, check-project-baz.sh → project
get_group() {
  local name
  name=$(basename "$1" .sh)
  name=${name#check-}  # strip "check-" prefix
  # Match p1-p7 first, then code, then project
  if [[ "$name" =~ ^p[1-7] ]]; then
    echo "${name:0:2}"
  elif [[ "$name" =~ ^code ]]; then
    echo "code"
  elif [[ "$name" =~ ^project ]]; then
    echo "project"
  else
    echo "other"
  fi
}

# --- Run checks and collect results ---
pass_count=0
warn_count=0
fail_count=0

# Store results keyed by group: group → array of formatted lines
declare -A GROUP_RESULTS

for check in "${checks[@]}"; do
  group=$(get_group "$check")

  # Run the check, capturing stdout and exit code
  output=""
  exit_code=0
  output=$("$check" "$REPO_PATH" 2>/dev/null) || exit_code=$?

  # Parse STATUS|LABEL|EVIDENCE
  if [[ -n "$output" ]]; then
    status=$(echo "$output" | cut -d'|' -f1)
    label=$(echo "$output" | cut -d'|' -f2)
    evidence=$(echo "$output" | cut -d'|' -f3-)
  else
    status="FAIL"
    label="$(basename "$check" .sh)"
    evidence="Check produced no output (exit $exit_code)"
  fi

  # Count results
  case "$status" in
    PASS) pass_count=$((pass_count + 1)) ;;
    WARN) warn_count=$((warn_count + 1)) ;;
    FAIL) fail_count=$((fail_count + 1)) ;;
  esac

  # Format and append to group
  line=$(printf "  %-4s  %-24s %s" "$status" "$label" "$evidence")
  GROUP_RESULTS[$group]="${GROUP_RESULTS[$group]:-}${line}"$'\n'
done

# --- Print grouped scorecard ---
repo_name=$(basename "$REPO_PATH")
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Agent-Native CLI Compliance — $repo_name"
echo "╚══════════════════════════════════════════════════════════╝"

for group in "${GROUP_ORDER[@]}"; do
  if [[ -n "${GROUP_RESULTS[$group]:-}" ]]; then
    echo ""
    echo "  ${GROUP_NAMES[$group]}"
    echo "  ──────────────────────────────────────────────────────"
    printf "%s" "${GROUP_RESULTS[$group]}"
  fi
done

# Print any ungrouped checks (future-proofing)
if [[ -n "${GROUP_RESULTS[other]:-}" ]]; then
  echo ""
  echo "  Other"
  echo "  ──────────────────────────────────────────────────────"
  printf "%s" "${GROUP_RESULTS[other]}"
fi

total=$((pass_count + warn_count + fail_count))
echo ""
echo "════════════════════════════════════════════════════════════"
printf "  Score: %d/%d PASS" "$pass_count" "$total"
[[ "$warn_count" -gt 0 ]] && printf ", %d WARN" "$warn_count"
[[ "$fail_count" -gt 0 ]] && printf ", %d FAIL" "$fail_count"
echo ""
echo ""

# --- Exit code ---
if [[ "$fail_count" -gt 0 ]]; then
  exit 2
elif [[ "$warn_count" -gt 0 ]]; then
  exit 1
else
  exit 0
fi
