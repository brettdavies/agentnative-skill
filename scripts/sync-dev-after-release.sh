#!/usr/bin/env bash
# Backport release artifacts from main to dev after a release tag publishes.
#
# Pulls two files from main and lands them as a single signed commit on dev:
#   - VERSION — overwritten with the released version (plain text, no leading "v").
#   - CHANGELOG.md — copied verbatim from origin/main. Main is fully
#     authoritative for CHANGELOG; dev never edits it directly.
#
# Run AFTER:
#   1. The release/v* -> main PR has merged.
#   2. `git tag -a vX.Y.Z` has been pushed to origin.
#   3. The GitHub Release has been created.
#
# Usage:
#   ./scripts/sync-dev-after-release.sh v0.2.0
#
# Idempotent: safe to re-run. If dev already matches main on these two
# files, the script exits 0 with no commit.
#
# Mirror of ~/dev/agentnative-cli/scripts/sync-dev-after-release.sh; this
# variant drops the Cargo.toml/Cargo.lock steps because the skill bundle
# is markdown-only (single plain-text VERSION file).

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 vX.Y.Z" >&2
    exit 64
fi

VERSION="$1"
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "error: version must match vMAJOR.MINOR.PATCH (got: $VERSION)" >&2
    exit 64
fi
VERSION_NO_V="${VERSION#v}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree not clean -- commit or stash first" >&2
    git status --short >&2
    exit 65
fi

git fetch origin --tags --quiet

# Verify the release tag exists locally.
if ! git rev-parse --verify --quiet "refs/tags/$VERSION" >/dev/null; then
    echo "error: tag $VERSION not found locally -- run 'git fetch origin --tags' or verify the release published" >&2
    exit 66
fi

# Verify main is at or past the tag (i.e. release/* actually merged).
TAG_SHA="$(git rev-parse "$VERSION")"
if ! git merge-base --is-ancestor "$TAG_SHA" origin/main; then
    echo "error: tag $VERSION is not reachable from origin/main -- wait for release/v* to merge" >&2
    exit 66
fi

git switch dev
git pull --ff-only origin dev

# VERSION is plain text; overwrite with the released version (no leading "v").
printf '%s\n' "$VERSION_NO_V" > VERSION

# CHANGELOG.md from main (authoritative).
git checkout origin/main -- CHANGELOG.md

if git diff --quiet VERSION CHANGELOG.md; then
    echo "no changes -- dev already in sync with $VERSION"
    exit 0
fi

git add VERSION CHANGELOG.md
git commit -m "chore(release): backport $VERSION artifacts to dev

Brings dev's release-bookkeeping current with the $VERSION release on
main: VERSION bumped to ${VERSION_NO_V} and CHANGELOG.md copied verbatim
from origin/main."

echo "committed; push with: git push origin dev"
