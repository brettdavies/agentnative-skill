#!/usr/bin/env bash
# Vendor agentnative-spec into spec/.
#
# Always vendors the latest v* tag found in the local spec checkout.
# Extracts files via `git show <tag>:<path>` so the user's spec working
# tree is not perturbed. The vendored tree ships as part of the skill
# bundle so consumers carry the canonical principle text alongside the
# skill metadata.
#
# Usage:
#   scripts/sync-spec.sh
#   SPEC_ROOT=/path/to/agentnative-spec scripts/sync-spec.sh
#
# Env vars:
#   SPEC_ROOT  Path to agentnative-spec checkout. Default: $HOME/dev/agentnative-spec
#
# Resync cadence: rerun after every new agentnative-spec tag. Run
# `git -C $SPEC_ROOT fetch --tags` first to pick up the new tag locally.
# Stale orphan files in spec/principles/ (e.g., from a spec rename) are
# accepted; `git status` surfaces them at commit time.
#
# Mirror of agentnative-cli/scripts/sync-spec.sh; only DEST_DIR differs.

set -euo pipefail

SPEC_ROOT="${SPEC_ROOT:-$HOME/dev/agentnative-spec}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$REPO_ROOT/spec"
DEST_PRINCIPLES="$DEST_DIR/principles"

if [[ ! -d "$SPEC_ROOT/.git" ]]; then
    echo "error: SPEC_ROOT is not a git repository: $SPEC_ROOT" >&2
    echo "       set SPEC_ROOT to your agentnative-spec checkout, or clone it to the default" >&2
    echo "       location: \$HOME/dev/agentnative-spec" >&2
    exit 1
fi

# Resolve the latest v* tag in the local spec checkout.
spec_tag="$(git -C "$SPEC_ROOT" tag --list 'v*' --sort='-version:refname' | head -n 1)"
if [[ -z "$spec_tag" ]]; then
    echo "error: no v* tags found in $SPEC_ROOT" >&2
    echo "       try \`git -C $SPEC_ROOT fetch --tags\` to pick up upstream tags" >&2
    exit 1
fi

resolved_sha="$(git -C "$SPEC_ROOT" rev-parse --short=7 "$spec_tag^{commit}")"
echo "vendoring $spec_tag ($resolved_sha) from $SPEC_ROOT"

# Verify the principles/ tree exists at the tag.
if ! git -C "$SPEC_ROOT" cat-file -e "$spec_tag:principles" 2>/dev/null; then
    echo "error: $spec_tag has no principles/ directory in $SPEC_ROOT" >&2
    exit 1
fi

mkdir -p "$DEST_PRINCIPLES"

# VERSION and CHANGELOG.md are top-level in the spec repo.
git -C "$SPEC_ROOT" show "$spec_tag:VERSION" >"$DEST_DIR/VERSION"
git -C "$SPEC_ROOT" show "$spec_tag:CHANGELOG.md" >"$DEST_DIR/CHANGELOG.md"

# Enumerate principle files at the tag and extract each one.
copied=0
while IFS= read -r path; do
    case "$path" in
        principles/p*-*.md)
            dest_name="${path#principles/}"
            git -C "$SPEC_ROOT" show "$spec_tag:$path" >"$DEST_PRINCIPLES/$dest_name"
            copied=$((copied + 1))
            ;;
    esac
done < <(git -C "$SPEC_ROOT" ls-tree --name-only "$spec_tag" principles/)

if [[ "$copied" -eq 0 ]]; then
    echo "error: no principles/p*-*.md files found at $spec_tag" >&2
    exit 1
fi

echo "wrote $copied principle file(s) to $DEST_PRINCIPLES"
echo "wrote VERSION + CHANGELOG.md to $DEST_DIR"
echo
echo "next: review \`git diff\` for unexpected changes, then commit."
