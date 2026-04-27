# Releasing `agentnative-skill`

Every change reaches `main` via this pipeline. Direct commits to `dev` or `main` are not permitted — every change has a
PR number in its squash commit message, which keeps the history scannable, attributable, and changelog-ready.

```text
feature branch (feat/*, fix/*, chore/*, docs/*) → PR to dev (squash merge)
                                                → PR dev → main (squash merge)
                                                → tag v* on main → site pins to commit SHA
```

This is the **lightweight** variant of the brettdavies release pattern. It omits `release/*` cherry-pick branches
because:

1. The repo is content + scripts, not compiled artifacts. There is no crates.io publish, no Homebrew dispatch, no
   cross-platform build to gate.
2. The release scope is small enough that "everything currently on dev" is almost always what we want to ship.
3. `guard-main-docs.yml` keeps engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`)
   off `main` mechanically — we don't need a cherry-pick step to filter them out.

If those assumptions stop holding (e.g., we start shipping a binary, or we need to hold back specific dev commits from a
release), upgrade to the full `release/*` cherry-pick pattern from the canonical
[`~/.claude/skills/github-repo-setup/references/RELEASES.md`](../../.claude/skills/github-repo-setup/references/RELEASES.md).

## Branches

| Branch                                 | Role                                                    | Lifetime                               | Protection                           |
| -------------------------------------- | ------------------------------------------------------- | -------------------------------------- | ------------------------------------ |
| `main`                                 | Released bundle. Only commits ready to ship.            | Forever.                               | `.github/rulesets/protect-main.json` |
| `dev`                                  | Integration. All feature PRs land here. Default branch. | Forever. Never delete.                 | `.github/rulesets/protect-dev.json`  |
| `feat/*`, `fix/*`, `chore/*`, `docs/*` | Feature work.                                           | One PR's worth. Auto-deleted on merge. | None — squash into `dev` freely.     |

`dev` is a **forever branch**. Never delete it locally or remotely, even after a `dev → main` merge. The repo's
`delete_branch_on_merge: true` setting doesn't touch `dev` because `dev` is the base, not the head, of the release-time
PR.

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

`dev` accumulates feature, fix, and docs commits. To cut a release, open one PR from `dev` to `main`:

```bash
git checkout dev && git pull

# Sanity: list what's on dev not yet on main.
git log --oneline dev --not origin/main

# Open the release PR. Title: a short summary of the version, not "Merge dev to main".
gh pr create --base main --head dev --title "release: v<X.Y.Z> — <one-line summary>"
```

**`guard-main-docs` runs on every PR with base `main`.** If any commit on `dev` added or modified a file under
`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, or `docs/reviews/`, the check fails and the PR is blocked. Two
ways to handle this:

- **Preferred**: keep all engineering docs deletions or unchanged at PR time. Plans should land on `dev` and stay there
  for posterity; they don't need to ship.
- **Override**: if a doc legitimately needs to ship to `main` (e.g., user-facing under `docs/`), add an exception in the
  reusable workflow at `brettdavies/.github`, not here.

When the PR merges:

1. The squash commit lands on `main` with the PR body as its message.
2. Tag `v<X.Y.Z>` on the new `main` HEAD: `git checkout main && git pull && git tag -a v<X.Y.Z> -m "v<X.Y.Z>" && git
   push origin v<X.Y.Z>`.
3. The site at `anc.dev/install` re-pins via its own PR (separate repo, separate session).

`dev` keeps moving forward. Don't reset or rebase `dev` after a release — it is forever.

## Version bump procedure

Before opening the `dev → main` release PR:

1. Decide the new version per SemVer. **Patch** = doc updates, internal cleanups, non-substantive script tweaks.
   **Minor** = new principles, new checks, new templates, new bundle files (backward-compatible additions). **Major** =
   breaking changes to the bundle's contract — renaming `SKILL.md` frontmatter fields, changing exit codes of
   `check-compliance.sh`, restructuring directory layout in ways that break existing skill installations.
2. Bump `VERSION` (single line, `<X.Y.Z>\n`, no metadata).
3. Add a section to `CHANGELOG.md` under `## [Unreleased]` (if present) with the new version + date, populated from the
   `## Changelog` sections of every PR squash-merged into `dev` since the last release.
4. Commit the bump on a `chore/release-vX.Y.Z` branch off `dev`, PR it into `dev`, then open the `dev → main` PR.

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
  historical anchors that the site's `install.json` pins to.

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
- [`.github/pull_request_template.md`](.github/pull_request_template.md) — PR body structure with changelog sections.
- [`.github/rulesets/README.md`](.github/rulesets/README.md) — ruleset apply + verify procedure.
- [`CHANGELOG.md`](./CHANGELOG.md) — released versions and their notes.
