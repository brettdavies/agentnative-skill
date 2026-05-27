# Releasing `agentnative-skill`

Operational runbook. Rationale lives in [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md).

```text
feature branch (feat/*, fix/*, chore/*, docs/*) → PR to dev (squash merge)
                                                → cherry-pick non-docs commits to release/<slug>
                                                → PR release/* to main (squash merge)
                                                → tag v* on main → GitHub Release
```

Direct commits to `dev` or `main` are not permitted: every change has a PR number in its squash commit message.

## Branches

| Branch                                 | Role                                                    | Lifetime                                    | Protection                           |
| -------------------------------------- | ------------------------------------------------------- | ------------------------------------------- | ------------------------------------ |
| `main`                                 | Released bundle. Only release-merged commits.           | Forever.                                    | `.github/rulesets/protect-main.json` |
| `dev`                                  | Integration. All feature PRs land here. Default branch. | Forever. Never delete.                      | `.github/rulesets/protect-dev.json`  |
| `feat/*`, `fix/*`, `chore/*`, `docs/*` | Feature work.                                           | One PR's worth. Auto-deleted on merge.      | None. Squash into `dev` freely.      |
| `release/*`                            | Head of a `release/* → main` PR.                        | One release's worth. Auto-deleted on merge. | None.                                |

→ Rationale: [`RELEASES-RATIONALE.md` § Branching model](./RELEASES-RATIONALE.md#branching-model).

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
  user-facing release notes; `CHANGELOG.md` entries derive from it directly. See [§ PR body](#pr-body).
- **PR body prose scrub**: see [§ Prose scrubbing](#prose-scrubbing).

## PR body

Every PR (feature, fix, docs, release) uses `.github/pull_request_template.md` verbatim.

- **No explainer prose anywhere in the body.** User-facing substance only.
- **Summary describes the net diff only** — what merged `main` looks like vs the base branch. Not commit history,
  intermediate state, or cherry-pick mechanics.
- **Zero verification artifacts in the body.** No triple-diff stats, leak-check output ("`guard-main-docs` runs clean"),
  patch-id cherry-check counts, pre-push gate results, CI status, or prose-scrub findings. Anomalies get fixed before
  push, not audit-trailed.
- **Changelog** subsections (`### Added` / `### Changed` / `### Fixed` / `### Removed` / `### Security`): 1-5 bullets
  each, delete empty subsections, each bullet starts with a verb.
- A PR with no user-facing impact (pure refactor, test-only, CI-only) leaves `## Changelog` empty or omits it.

→ Rationale: [`RELEASES-RATIONALE.md` § PR body conventions](./RELEASES-RATIONALE.md#pr-body-conventions).

## Releasing dev to main

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only.
`guard-main-docs.yml` blocks any `added` or `modified` files under those paths from reaching `main`.

**Branch naming**: `release/v<X.Y.Z>` (preferred) or `release/<date>-<slug>`. Keep the slug short and descriptive.

```bash
# 1. Cut release/* from main, NOT dev.
git fetch origin
git checkout -b release/v<X.Y.Z> origin/main

# 2. List the dev commits not yet on main.
git log --oneline dev --not origin/main

# 3. Cherry-pick non-docs commits onto release/v<X.Y.Z>. Docs commits stay on dev.
git cherry-pick <sha1> <sha2> ...

# 4. Triple-diff verification.
git diff origin/main..HEAD --stat                                              # A: ship surface
git diff HEAD..origin/dev --name-only | grep -v '^docs/' || echo "(none)"      # B: no missed picks
git diff origin/dev..origin/main --stat | tail -5                              # C: phantom-commits sanity

# Re-confirm no guarded paths leaked.
git diff origin/main..HEAD --name-only \
  | grep -E '^(docs/plans|docs/brainstorms|docs/ideation|docs/reviews|docs/solutions|\.context)' \
  && echo "LEAKED — reset and redo" || echo "(clean)"

# Patch-id cherry check (noisy in squash-merge workflow; triage per-line).
git cherry HEAD origin/dev | grep '^+' || echo "(none)"

# 5. Bump VERSION on the release branch.
echo '<X.Y.Z>' > VERSION

# 6. Re-vendor the spec if a new tag has shipped upstream.
scripts/sync-spec.sh
git add spec/ && git commit -m "chore(spec): re-vendor spec to <version>" || true

# 7. Generate CHANGELOG entries from PR bodies.
scripts/generate-changelog.sh
# (the script extracts <X.Y.Z> from the branch name release/v<X.Y.Z>)

# 8. Scrub CHANGELOG.md via Vale + LanguageTool + unslop. See § Prose scrubbing.
#    Fix findings on upstream PR bodies, never by hand-editing CHANGELOG.md.

# 9. Commit the version bump and generated changelog.
git add VERSION CHANGELOG.md
git commit -m "chore(release): v<X.Y.Z>"

# 10. Push and open the PR. Scrub body in /tmp/ first.
git push -u origin release/v<X.Y.Z>
gh pr create --base main --head release/v<X.Y.Z> \
  --title "release: v<X.Y.Z> — <one-line summary>" --body-file /tmp/body.md
```

When the PR merges:

1. The squash commit lands on `main` with the PR body as its message.
2. `release/v<X.Y.Z>` is auto-deleted.
3. Tag the new `main` HEAD:

   ```bash
   git checkout main && git pull
   git tag -a v<X.Y.Z> -m "v<X.Y.Z>"
   git push origin v<X.Y.Z>
   ```

4. Create the GitHub Release using the generated CHANGELOG section:

   ```bash
   gh release create v<X.Y.Z> --title "v<X.Y.Z>" \
     --notes "$(awk '/^## \[<X.Y.Z>\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md)"
   ```

Consumers detect the new release on their next `bin/check-update` run; nothing else to do here.

`dev` keeps moving forward. Never reset or rebase `dev` after a release: it is forever.

→ Rationale + triple-diff false-positive triage:
[`RELEASES-RATIONALE.md` § Triple-diff verification](./RELEASES-RATIONALE.md#triple-diff-verification). CHANGELOG
mechanics: [`RELEASES-RATIONALE.md` § CHANGELOG generation](./RELEASES-RATIONALE.md#changelog-generation). Spec
re-vendoring: [`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline).

### After publish — sync `dev` with the release

Once the release tag is published, backport the release-bookkeeping files from `main` to `dev`:

```bash
./scripts/sync-dev-after-release.sh v<X.Y.Z>
git push origin dev
```

The script overwrites `VERSION` with the released number and copies `CHANGELOG.md` verbatim from `origin/main`, then
commits the result directly to `dev` as one signed commit (no PR). Without this step `dev`'s `VERSION` and
`CHANGELOG.md` stay frozen at the pre-release state, and future feature branches inherit the wrong baseline.

The backport is idempotent: re-running on a `dev` already in sync exits 0 with no commit.

→ Rationale:
[`RELEASES-RATIONALE.md` § Why backport `main` → `dev` after publish](./RELEASES-RATIONALE.md#why-backport-main--dev-after-publish).

## Version bump procedure

The version bump and CHANGELOG generation both happen on the `release/v<X.Y.Z>` branch (steps 5-7 of the cherry-pick
flow above). There is no separate version-bump PR to `dev`. Picking the version is the only manual decision:

- **Patch**: doc updates, internal cleanups, non-substantive template edits, vendoring a patch-level spec bump.
- **Minor**: new templates, new reference docs, new bundle files (backward-compatible additions), vendoring a
  minor-level spec bump that adds requirements without tightening existing tiers.
- **Major**: breaking changes to the bundle's contract (renaming `SKILL.md` frontmatter fields, restructuring directory
  layout in ways that break existing skill installations, moving content between subdirectories and the producer-ops
  root, or vendoring a major-level spec bump).

→ Rationale: [`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline) (skill
version is independent of spec version).

## Prose scrubbing

Three release-flow artifacts live outside any automated prose check and need a manual scrub before they ship:

- PR bodies (`gh pr create` / `gh pr edit` send body text directly to GitHub).
- `CHANGELOG.md` (a generated artifact built from upstream PR bodies).
- Release-PR bodies (composed after `CHANGELOG.md` has been generated).

The canonical Vale + LanguageTool rule packs and orchestrator behaviour live in the spec repo at
[`~/dev/agentnative-spec/docs/architecture/voice-enforcement.md`](https://github.com/brettdavies/agentnative/blob/dev/docs/architecture/voice-enforcement.md).
Until those packs are vendored into this repo via a `scripts/sync-spec.sh` extension (a deferred follow-up), the scrub
commands point at the spec checkout directly.

```bash
# 1. Save the artifact to /tmp/.
gh pr view <num> --json body --jq .body > /tmp/body.md         # for PR body edits
# cp CHANGELOG.md /tmp/body.md                                 # for changelog scrub

# 2. Vale (against the spec's rule packs).
vale --no-global --config ~/dev/agentnative-spec/.vale.ini --output=line --minAlertLevel=error /tmp/body.md

# 3. LanguageTool grammar check via lt_check (~/dotfiles/config/shell/languagetool.sh).
#    Skips cleanly if LT is unreachable. Inspect: `lt_rules`, `lt_info`. See
#    ~/dev/agentnative-spec/CONTRIBUTING.md § Voice enforcement for the
#    install-vs-required nuance.
lt_check /tmp/body.md

# 4. unslop (em-dash density and AI-unique structural patterns).
~/.claude/skills/unslop/scripts/score.py /tmp/body.md

# 5. Apply fixes per finding. Re-run until 0 blocking and unslop score is 0.

# 6. Apply the cleaned version.
gh pr edit <num> --body-file /tmp/body.md     # for PR body edits
# scripts/generate-changelog.sh                # for CHANGELOG.md (re-runs the PR-body fetch from GitHub)
```

For a `CHANGELOG.md` finding, fix the upstream PR body and regenerate. Hand-editing `CHANGELOG.md` directly produces
drift the next regeneration overwrites.

→ Rationale + which artifacts need this:
[`RELEASES-RATIONALE.md` § Prose scrubbing scope](./RELEASES-RATIONALE.md#prose-scrubbing-scope).

## Branch protection

Three rulesets are committed under `.github/rulesets/` and applied to the repo via the GitHub API:

- **`protect-main.json`**: required signatures, linear history, squash-only merges via PR with CODEOWNERS review,
  required status checks (`markdownlint`, `shellcheck`, `guard-docs / check-forbidden-docs`), creation/deletion blocked,
  non-fast-forward blocked.
- **`protect-dev.json`**: required signatures, deletion blocked, non-fast-forward blocked. PR-only norm is enforced by
  convention.
- **`protect-tags.json`**: `v*` tags. Deletion, force-push (re-tag), and updates all blocked. Tags are immutable
  historical anchors for released versions.

### Apply

All three rulesets are already installed on this repo. Re-runnable for new repos or after a ruleset reset:

```bash
gh api repos/brettdavies/agentnative-skill/rulesets -X POST --input .github/rulesets/protect-main.json
gh api repos/brettdavies/agentnative-skill/rulesets -X POST --input .github/rulesets/protect-dev.json
gh api repos/brettdavies/agentnative-skill/rulesets -X POST --input .github/rulesets/protect-tags.json
```

Verify installed rulesets:

```bash
gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[] | "\(.id)\t\(.name)\t\(.target)"'
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

### Status-check contexts (verified)

| Check              | Source                                         | Context (verified)                  |
| ------------------ | ---------------------------------------------- | ----------------------------------- |
| `markdownlint`     | inline job, `name: markdownlint`               | `markdownlint`                      |
| `shellcheck`       | inline job, `name: shellcheck`                 | `shellcheck`                        |
| `guard-docs / ...` | reusable workflow caller, job key `guard-docs` | `guard-docs / check-forbidden-docs` |

Confirm post-CI with:

```bash
gh api repos/brettdavies/agentnative-skill/commits/<sha>/check-runs --jq '.check_runs[].name'
```

→ Rationale (inline vs reusable, three-ruleset shape):
[`RELEASES-RATIONALE.md` § Branch protection](./RELEASES-RATIONALE.md#branch-protection).

## Related docs

- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md) (release flow rationale, CHANGELOG pipeline, branch-protection
  pitfalls)
- [`AGENTS.md`](./AGENTS.md) (repo layout, lint commands, what agents must not do)
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) (how to propose changes)
- [`.github/pull_request_template.md`](.github/pull_request_template.md) (PR body structure with changelog sections)
- [`.github/rulesets/README.md`](.github/rulesets/README.md) (ruleset apply + verify procedure)
- [`CHANGELOG.md`](./CHANGELOG.md) (released versions and their notes)
