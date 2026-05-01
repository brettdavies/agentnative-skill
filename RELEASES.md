# Releasing `agentnative-skill`

Every change reaches `main` via this pipeline. Direct commits to `dev` or `main` are not permitted — every change has a
PR number in its squash commit message, which keeps the history scannable, attributable, and changelog-ready.

```text
feature branch (feat/*, fix/*, chore/*, docs/*) → PR to dev (squash merge)
                                                → cherry-pick non-docs commits to release/<slug>
                                                → PR release/* to main (squash merge)
                                                → tag v* on main → GitHub Release
```

This is the canonical brettdavies release pattern with `release/*` cherry-pick branches. Plans live on `dev` forever and
`guard-main-docs.yml` blocks any `added` or `modified` engineering-doc files in PRs targeting `main`. The release-branch
cherry-pick handles this cleanly: docs commits stay on `dev`, only feature/fix/chore commits go onto `release/*`.

## Branches

| Branch                                 | Role                                                    | Lifetime                                    | Protection                           |
| -------------------------------------- | ------------------------------------------------------- | ------------------------------------------- | ------------------------------------ |
| `main`                                 | Released bundle. Only release-merged commits.           | Forever.                                    | `.github/rulesets/protect-main.json` |
| `dev`                                  | Integration. All feature PRs land here. Default branch. | Forever. Never delete.                      | `.github/rulesets/protect-dev.json`  |
| `feat/*`, `fix/*`, `chore/*`, `docs/*` | Feature work.                                           | One PR's worth. Auto-deleted on merge.      | None — squash into `dev` freely.     |
| `release/*`                            | Head of a `release/* → main` PR.                        | One release's worth. Auto-deleted on merge. | None.                                |

`dev` is a **forever branch**. Never delete it locally or remotely, even after a `release/* → main` merge. The next
release cycle reuses the same `dev`. The repo's `delete_branch_on_merge: true` setting doesn't touch `dev` because `dev`
is never the head of a PR — using a short-lived `release/*` head is what keeps the setting compatible with a forever
integration branch.

## Daily development (feature → dev)

```bash
git checkout dev && git pull
git checkout -b feat/short-description
# ... work ...
git push -u origin feat/short-description
gh pr create --base dev --title "feat(scope): what changed"
# CI passes → squash-merge (PR_BODY becomes the dev commit message)
```

- **Commit style**: [Conventional Commits](https://www.conventionalcommits.org/).
- **PR body**: follow `.github/pull_request_template.md`. The `## Changelog` section is the source of truth for
  user-facing release notes — `CHANGELOG.md` entries derive from it directly.

## Releasing dev to main

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only.
`guard-main-docs.yml` blocks any `added` or `modified` files under those paths from reaching `main`. Branching from
`dev` and deleting docs on the way produces `add/add` merge conflicts whenever `dev` and `main` have diverged (the norm
after the first squash merge). The cherry-pick pattern avoids this.

**Branch naming**: `release/v<X.Y.Z>` (preferred) or `release/<date>-<slug>`. Keep the slug short and descriptive.

```bash
# 1. Cut release/* from main, NOT dev. Branching from dev causes add/add
#    conflicts when dev and main have divergent histories.
git fetch origin
git checkout -b release/v<X.Y.Z> origin/main

# 2. List the dev commits not yet on main:
git log --oneline dev --not origin/main

# 3. Cherry-pick non-docs commits onto release/v<X.Y.Z>. Docs commits
#    (anything that touched only docs/plans/, docs/solutions/,
#    docs/brainstorms/, or docs/reviews/) stay on dev.
git cherry-pick <sha1> <sha2> ...

# 4. Triple-diff verification — belt-and-suspenders sweep that catches both
#    directions of drift before the release tag goes out:
#
#    A. main → release  (what users will see; the intended ship surface)
#    B. release → dev   (should be empty for non-doc paths until the
#                        bump/CHANGELOG commits land, and even then should
#                        only list those release-prep files — anything else
#                        is a missed cherry-pick)
#    C. dev → main      (sanity: phantom commits dev "appears ahead" on
#                        because cherry-pick rewrites SHAs post-squash)
git diff origin/main..HEAD --stat                                                # A
git diff HEAD..origin/dev --name-only | grep -v '^docs/' || echo "(none)"        # B
git diff origin/dev..origin/main --stat | tail -5                                # C
#
# Re-confirm no guarded paths leaked (this caught the original miss class):
git diff origin/main..HEAD --name-only \
  | grep -E '^(docs/plans|docs/brainstorms|docs/ideation|docs/reviews|docs/solutions|\.context)' \
  && echo "LEAKED — reset and redo" || echo "(clean — no guarded paths)"
#
# Patch-id cherry check — catches commits on dev that have NO patch-id
# equivalent on release. The file-level diff in B misses this class when
# the same content happens to land via a different commit.
#
# IMPORTANT: in a squash-merge workflow this output is noisy. Every '+'
# line needs human triage — it does NOT auto-block the release. Expected
# sources of '+' lines that are NOT real misses:
#
#   1. Historical commits squash-merged in prior releases. The squash
#      commit on main has a different patch-id than the dev commits it
#      consolidates, so old commits show as '+' forever. Anything older
#      than the previous release tag is almost always this.
#   2. Cherry-picks where conflict resolution stripped guarded paths
#      (docs/plans, docs/brainstorms, etc.) or otherwise altered the
#      tree. Same source-code intent, different patch-id.
#   3. Intentionally skipped commits — docs-only commits, release-prep
#      backports, revert-and-redo prep steps.
#
# A real miss looks like: a recent feat/fix/chore commit on dev whose
# *file content* is not yet on main. To triage a '+' line:
#
#   git show <sha> --stat                       # what did it touch?
#   git diff origin/main..HEAD -- <those-files> # already on release?
#
# If every touched file is guarded (docs/plans/, docs/brainstorms/, etc.)
# OR the content is already on main via a prior squash, it's a false
# positive — no action. Otherwise cherry-pick the commit and re-run the
# triple-diff.
git cherry HEAD origin/dev | grep '^+' || echo "(none — release is patch-equivalent through dev)"
#
# If B lists any non-docs path you didn't expect, fetch dev, identify the
# commit (`git log dev --not origin/main`), cherry-pick it, re-run the
# triple-diff. Missed cherry-picks have shipped to main on this and sibling
# repos before — this step is the cheap way to catch them.

# 5. Bump VERSION on the release branch.
echo '<X.Y.Z>' > VERSION

# 6. Generate CHANGELOG entries from PR bodies. NEVER hand-edit CHANGELOG.md —
#    the script is authoritative. It reads cliff.toml + each cherry-picked PR's
#    ## Changelog section and prepends a versioned [<X.Y.Z>] entry.
scripts/generate-changelog.sh
# (the script extracts <X.Y.Z> from the branch name release/v<X.Y.Z>)

# 7. Commit the version bump and generated changelog.
git add VERSION CHANGELOG.md
git commit -m "chore(release): v<X.Y.Z>"

# 8. Push and open the PR:
git push -u origin release/v<X.Y.Z>
gh pr create --base main --head release/v<X.Y.Z> --title "release: v<X.Y.Z> — <one-line summary>"
```

When the PR merges:

1. The squash commit lands on `main` with the PR body as its message.
2. `release/v<X.Y.Z>` is auto-deleted.
3. Tag the new `main` HEAD: `git checkout main && git pull && git tag -a v<X.Y.Z> -m "v<X.Y.Z>" && git push origin
   v<X.Y.Z>`.
4. Create the GitHub Release using the generated CHANGELOG section:

   ```bash
   gh release create v<X.Y.Z> --title "v<X.Y.Z>" \
     --notes "$(awk '/^## \[<X.Y.Z>\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md)"
   ```

Consumers detect the new release on their next `bin/check-update` run; nothing else to do here.

`dev` keeps moving forward. Never reset or rebase `dev` after a release — it is forever.

### CHANGELOG is generated, never hand-written

`scripts/generate-changelog.sh` (with `cliff.toml`) is the only sanctioned way to update `CHANGELOG.md`. The script:

- Runs `git-cliff` to prepend a versioned entry for commits since the last tag.
- Walks each squash-merged PR's body, extracts the `## Changelog` section's `### Added` / `### Changed` / `### Fixed` /
  `### Documentation` subsections, and replaces the auto-generated bullets with the curated PR-body content (with author
  and PR-link attribution).

If a PR's `## Changelog` section is empty, that PR's entry is omitted from the changelog (the convention in
[`.github/pull_request_template.md`](.github/pull_request_template.md): empty section = no user-facing change). To fix a
wrong CHANGELOG entry, fix the input — edit the squash-merged PR body, then re-run the script. Do **not** edit
`CHANGELOG.md` directly.

`scripts/generate-changelog.sh --check` verifies that `CHANGELOG.md` has a versioned section (not just `[Unreleased]`) —
wire this into the release-branch CI if/when one is added.

### Why branch from main, not dev

Branching from `dev` and then `gio trash`-ing the guarded paths seems simpler but produces `add/add` merge conflicts
whenever `dev` and `main` have diverged. The file appears as "added" on both sides with different content. Always branch
from `origin/main` and cherry-pick onto it.

## Spec re-vendoring

The bundle vendors a snapshot of [`agentnative-spec`](https://github.com/brettdavies/agentnative) under `spec/`. When
the spec ships a new tag (e.g., `v0.3.0`), this skill re-vendors via `scripts/sync-spec.sh` on the `release/v<X.Y.Z>`
branch — same commit as the version bump, message `chore(spec): re-vendor spec to <version>`. The script auto-resolves
the latest upstream tag from the remote, so no manual version selection is needed. Without re-vendoring, the bundle
ships stale spec content while consumers see the new version on `anc.dev`.

## Version bump procedure

The version bump and CHANGELOG generation both happen on the `release/v<X.Y.Z>` branch (steps 5–6 of the cherry-pick
flow above). There is no separate version-bump PR to `dev`. Picking the version is the only manual decision:

- **Patch** — doc updates, internal cleanups, non-substantive template edits, vendoring a patch-level spec bump.
- **Minor** — new templates, new reference docs, new bundle files (backward-compatible additions), vendoring a
  minor-level spec bump that adds requirements without tightening existing tiers.
- **Major** — breaking changes to the bundle's contract: renaming `SKILL.md` frontmatter fields, restructuring directory
  layout in ways that break existing skill installations, moving content between `` and the producer-ops root, or
  vendoring a major-level spec bump (renamed/removed principles or tightened MUSTs that would regress existing
  consumers).

The skill's version is independent of the spec it vendors. A spec bump that doesn't affect the skill's surface (e.g.,
prose-only edits) can ship as a patch even when the spec went minor. Use the SemVer guidance above against the *skill's*
observable behaviour, not the spec's.

## PRs and changelog generation

Every PR **must** follow `.github/pull_request_template.md`. The template's `## Changelog` section has these
subsections:

- `### Added` — new user-visible features or capabilities (new principles, new checks, new templates).
- `### Changed` — changes to existing behavior (e.g., a check's pass/fail criteria tightens).
- `### Fixed` — bug fixes (e.g., a check produces false positives).
- `### Removed` — removed features or APIs.
- `### Security` — security-relevant changes (e.g., a script that ran on user machines now refuses an unsafe path).

A PR that lands with an empty or missing `## Changelog` section silently drops its user-facing notes from the next
release. If a PR truly has no user-facing impact (pure refactor, test-only, CI-only), leave the section empty — the PR
still appears in git history.

## Branch protection

Three rulesets are committed under `.github/rulesets/` and applied to the repo via the GitHub API:

- **`protect-main.json`** — required signatures, linear history, squash-only merges via PR with CODEOWNERS review,
  required status checks (`markdownlint`, `shellcheck`, `guard-docs / check-forbidden-docs`), creation/deletion blocked,
  non-fast-forward blocked.
- **`protect-dev.json`** — required signatures, deletion blocked, non-fast-forward blocked. No PR-requirement at the
  ruleset level; the PR-only norm is enforced by convention.
- **`protect-tags.json`** — `v*` tags: deletion, force-push (re-tag), and updates all blocked. Tags are immutable
  historical anchors for released versions.

### Apply (post-public-flip)

The repo ships **PRIVATE** through the bootstrap window. GitHub's free tier does not allow rulesets on private repos.
After visibility flips to public from the agentnative-site session:

```bash
gh api repos/brettdavies/agentnative-skill/rulesets -X POST --input .github/rulesets/protect-main.json
gh api repos/brettdavies/agentnative-skill/rulesets -X POST --input .github/rulesets/protect-dev.json
gh api repos/brettdavies/agentnative-skill/rulesets -X POST --input .github/rulesets/protect-tags.json
```

See [`.github/rulesets/README.md`](.github/rulesets/README.md) for verification + negative tests.

### Updating a ruleset

Edit the JSON locally, then sync to the remote (replacement, not patch):

```bash
# Find the ruleset id
gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[] | "\(.id)\t\(.name)"'

# Replace by id
gh api -X PUT repos/brettdavies/agentnative-skill/rulesets/<id> --input .github/rulesets/protect-main.json
```

### Status-check context pitfall

`required_status_checks[].context` strings must match exactly what GitHub publishes for each check. For this repo:

| Check              | Source                                         | Context (verified)                  |
| ------------------ | ---------------------------------------------- | ----------------------------------- |
| `markdownlint`     | inline job, `name: markdownlint`               | `markdownlint`                      |
| `shellcheck`       | inline job, `name: shellcheck`                 | `shellcheck`                        |
| `guard-docs / ...` | reusable workflow caller, job key `guard-docs` | `guard-docs / check-forbidden-docs` |

Confirm post-CI with:

```bash
gh api repos/brettdavies/agentnative-skill/commits/<sha>/check-runs --jq '.check_runs[].name'
```

## Related docs

- [`AGENTS.md`](./AGENTS.md) — repo layout, lint commands, what agents must not do.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to propose changes.
- [`.github/pull_request_template.md`](.github/pull_request_template.md) — PR body structure with changelog sections.
- [`.github/rulesets/README.md`](.github/rulesets/README.md) — ruleset apply + verify procedure.
- [`CHANGELOG.md`](./CHANGELOG.md) — released versions and their notes.
