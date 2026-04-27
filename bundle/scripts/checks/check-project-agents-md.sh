#!/usr/bin/env bash
# Project: AGENTS.md at repo root
# Canonical: AGENTS.md (plural, agent-agnostic, Anthropic standard).
# Non-canonical: AGENT.md (singular), CLAUDE.md (tool-specific).
#
# CLAUDE.md serves a different purpose (Claude Code harness instructions)
# but some projects use it as a substitute for AGENTS.md. It should not
# replace AGENTS.md — the standard file is agent-agnostic.
#
# PASS  — AGENTS.md exists (canonical)
# WARN  — AGENT.md or CLAUDE.md exists without AGENTS.md (rename/add)
# FAIL  — none of the above
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Override _helpers.sh validation — AGENTS.md check doesn't need src/
if [[ -z "${1:-}" ]]; then
  echo "Usage: $(basename "$0") <repo-path>" >&2
  exit 2
fi
if [[ ! -d "$1" ]]; then
  echo "Error: '$1' is not a directory" >&2
  exit 2
fi
REPO_PATH="$1"

emit_result() {
  local status="$1" label="$2" evidence="$3"
  echo "${status}|${label}|${evidence}"
  case "$status" in
    PASS) exit 0 ;;
    WARN) exit 1 ;;
    FAIL) exit 2 ;;
    *) echo "BUG: unknown status '$status'" >&2; exit 2 ;;
  esac
}

# Tier 1: canonical AGENTS.md (plural)
if [[ -f "$REPO_PATH/AGENTS.md" ]]; then
  emit_result "PASS" "AGENTS.md" "AGENTS.md exists at repo root (canonical)"
fi

# Tier 2: non-canonical alternatives
if [[ -f "$REPO_PATH/AGENT.md" ]]; then
  emit_result "WARN" "AGENTS.md" "Found AGENT.md (singular) — rename to AGENTS.md"
fi
if [[ -f "$REPO_PATH/CLAUDE.md" ]]; then
  emit_result "WARN" "AGENTS.md" "Found CLAUDE.md but no AGENTS.md — add AGENTS.md for agent-agnostic docs"
fi

emit_result "FAIL" "AGENTS.md" "Missing AGENTS.md — agents need build/test/convention docs"
