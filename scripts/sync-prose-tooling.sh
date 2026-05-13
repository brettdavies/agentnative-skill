#!/usr/bin/env bash
# Vendor the cross-channel prose source-of-truth shipped on agentnative-spec.
#
# Parallel sync vehicle to scripts/sync-spec.sh, decoupled because the brand
# narrative (BRAND.md) and the contract artifacts (principles/, VERSION,
# CHANGELOG.md) release on different cadences. sync-spec.sh covers the
# contract anc lints against; this script covers the universal voice anchor
# that PRODUCT.md inherits from.
#
# Vendored manifest (paths at the spec tag, mirrored verbatim into this
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
# Resolves the latest v* tag of agentnative-spec, preferring the remote
# repository, and falls back to a local checkout if the remote is
# unreachable. Extracts files via `git show <tag>:<path>` so neither
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
# Resync cadence: rerun after the spec ships a tag that touches BRAND.md
# (or, once the manifest expands, any other vendored prose-tooling path).
# Spec's `repository_dispatch:spec-release` event fires on tag publish; a
# consumer-side handler that auto-PRs the resync is tracked as deferred
# follow-up alongside the same handler for sync-spec.sh.
#
# Idempotent at a fixed spec tag: re-running produces no `git diff`.

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
spec_tag=""

echo "querying $SPEC_REMOTE_URL for latest v* tag..."
remote_tag="$(git ls-remote --tags --sort='-version:refname' \
    "$SPEC_REMOTE_URL" 'refs/tags/v*' 2>/dev/null \
    | awk '{print $2}' \
    | sed 's|refs/tags/||' \
    | grep -v '\^{}$' \
    | head -n 1 || true)"

if [[ -n "$remote_tag" ]]; then
    tmp_root="$(mktemp -d -t agentnative-prose-XXXXXX)"
    if git clone --depth 1 --branch "$remote_tag" --quiet \
            "$SPEC_REMOTE_URL" "$tmp_root" 2>/dev/null; then
        spec_source="$tmp_root"
        spec_tag="$remote_tag"
        resolved_sha="$(git -C "$spec_source" rev-parse --short=7 "$spec_tag^{commit}")"
        echo "vendoring $spec_tag ($resolved_sha) from remote $SPEC_REMOTE_URL"
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
    spec_tag="$(git -C "$spec_source" tag --list 'v*' --sort='-version:refname' | head -n 1)"
    if [[ -z "$spec_tag" ]]; then
        echo "error: no v* tags found in $SPEC_ROOT" >&2
        echo "       try \`git -C $SPEC_ROOT fetch --tags\` to pick up upstream tags" >&2
        exit 1
    fi
    resolved_sha="$(git -C "$spec_source" rev-parse --short=7 "$spec_tag^{commit}")"
    echo "vendoring $spec_tag ($resolved_sha) from local $spec_source"
fi

# === Verify expected paths exist at the tag ===========================
required_paths=(
    "BRAND.md"
)
for path in "${required_paths[@]}"; do
    if ! git -C "$spec_source" cat-file -e "$spec_tag:$path" 2>/dev/null; then
        echo "error: $spec_tag is missing required path: $path" >&2
        echo "       (BRAND.md may not have shipped at this tag)" >&2
        exit 1
    fi
done

# === Extract: top-level singletons =====================================
git -C "$spec_source" show "$spec_tag:BRAND.md" >"$REPO_ROOT/BRAND.md"

# === Report ============================================================
echo "wrote BRAND.md to repo root"
echo
echo "next: review \`git diff\` for unexpected changes, then commit."
