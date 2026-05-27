#!/usr/bin/env bash
# Vendor the cross-channel prose source-of-truth shipped on agentnative-spec.
#
# Parallel sync vehicle to scripts/sync-spec.sh, decoupled because the brand
# narrative (BRAND.md) and the contract artifacts (principles/, VERSION,
# CHANGELOG.md) release on different cadences. sync-spec.sh covers the
# contract anc lints against; this script covers the universal voice anchor
# that PRODUCT.md inherits from.
#
# Vendored manifest (paths at spec main HEAD, mirrored verbatim into this
# repo at the same paths):
#
#   BRAND.md                                            (universal voice SoT)
#
# BRAND.md only, by design. The skill repo does not run prose-check today
# (no .vale.ini, no styles/ tree), so the broader prose-tooling stack the
# spec ships (Vale rule packs, vocabulary, prose-check.sh orchestrator,
# generate-pack-readme.mjs) is omitted here. When the skill activates Vale,
# extend the vendored manifest below to mirror the site's
# scripts/sync-prose-tooling.sh: add styles/brand/*.yml + README.md,
# styles/config/vocabularies/brand/{accept,reject}.txt, scripts/prose-check.sh,
# and scripts/generate-pack-readme.mjs to required_paths and the extract block.
#
# Tracks `main` HEAD by design: the prose-tooling stack (BRAND.md and,
# once expanded, Vale packs / vocabularies / prose-check.sh) iterates
# faster than the principle contract and does not need release-tag
# ceremony. Tag-pinning is reserved for the principle contract via
# `sync-spec.sh`. Resolves the current commit on `main`, preferring the
# remote repository, and falls back to a local checkout if the remote is
# unreachable. Extracts files via `git show <sha>:<path>` so neither
# checkout's working tree is perturbed.
#
# Usage:
#   scripts/sync-prose-tooling.sh
#   SPEC_ROOT=/path/to/agentnative-spec scripts/sync-prose-tooling.sh
#   SPEC_REMOTE_URL=git@github.com:brettdavies/agentnative.git scripts/sync-prose-tooling.sh
#
# Env vars (shared with sync-spec.sh):
#   SPEC_REMOTE_URL  Remote URL to query first.
#                    Default: https://github.com/brettdavies/agentnative.git
#   SPEC_ROOT        Local checkout to fall back to when the remote is
#                    unreachable. Default: $HOME/dev/agentnative-spec
#
# Resync cadence: rerun whenever the spec's `main` advances with changes
# under the vendored manifest (today: BRAND.md). Tracks `main` HEAD by
# design; tag-pinning is for the principle contract via `sync-spec.sh`.
# Spec's `repository_dispatch:spec-release` event fires on tag publish; a
# consumer-side handler that auto-PRs the resync is tracked as deferred
# follow-up alongside the same handler for sync-spec.sh.
#
# Idempotent at a fixed upstream sha: re-running with no upstream change
# produces no `git diff`.

set -euo pipefail

SPEC_REMOTE_URL="${SPEC_REMOTE_URL:-https://github.com/brettdavies/agentnative.git}"
SPEC_ROOT="${SPEC_ROOT:-$HOME/dev/agentnative-spec}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Cleanup hook for the temp clone (set only after mktemp succeeds).
tmp_root=""
cleanup() {
    if [[ -n "$tmp_root" && -d "$tmp_root" ]]; then
        rm -rf "$tmp_root"
    fi
}
trap cleanup EXIT

# === Remote-first resolution ===========================================
spec_source=""
spec_ref=""
resolved_sha=""

echo "querying $SPEC_REMOTE_URL for main HEAD..."
remote_sha="$(git ls-remote "$SPEC_REMOTE_URL" 'refs/heads/main' 2>/dev/null | awk '{print $1}')"

if [[ -n "$remote_sha" ]]; then
    tmp_root="$(mktemp -d -t agentnative-prose-XXXXXX)"
    if git clone --depth 1 --branch main --quiet \
            "$SPEC_REMOTE_URL" "$tmp_root" 2>/dev/null; then
        spec_source="$tmp_root"
        spec_ref="main"
        resolved_sha="$(git -C "$spec_source" rev-parse --short=7 main)"
        echo "pulling from main @ $resolved_sha (remote $SPEC_REMOTE_URL)"
    fi
fi

# === Local fallback ====================================================
if [[ -z "$spec_source" ]]; then
    if [[ ! -d "$SPEC_ROOT/.git" ]]; then
        echo "error: remote unreachable and SPEC_ROOT is not a git repository: $SPEC_ROOT" >&2
        echo "       remote: $SPEC_REMOTE_URL" >&2
        echo "       set SPEC_ROOT to your agentnative-spec checkout, or check network access." >&2
        exit 1
    fi
    echo "warning: remote query failed; falling back to local $SPEC_ROOT" >&2

    spec_source="$SPEC_ROOT"
    if ! git -C "$spec_source" rev-parse --verify --quiet main >/dev/null; then
        echo "error: no local main branch found in $SPEC_ROOT" >&2
        echo "       try \`git -C $SPEC_ROOT fetch origin main:main\` to track upstream" >&2
        exit 1
    fi
    spec_ref="main"
    resolved_sha="$(git -C "$spec_source" rev-parse --short=7 main)"
    echo "pulling from main @ $resolved_sha (local $spec_source)"
fi

# === Verify expected paths exist at main ===============================
required_paths=(
    "BRAND.md"
)
for path in "${required_paths[@]}"; do
    if ! git -C "$spec_source" cat-file -e "$spec_ref:$path" 2>/dev/null; then
        echo "error: main @ $resolved_sha is missing required path: $path" >&2
        echo "       (BRAND.md may not have landed on main yet)" >&2
        exit 1
    fi
done

# === Extract: top-level singletons =====================================
git -C "$spec_source" show "$spec_ref:BRAND.md" >"$REPO_ROOT/BRAND.md"

# === Report ============================================================
echo "wrote BRAND.md to repo root (pulled from main @ $resolved_sha)"
echo
echo "next: review \`git diff\` for unexpected changes, then commit."
