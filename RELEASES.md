# Releasing `agentnative-skill`

Operational runbook. Rationale lives in [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md). Pre-cut go/no-go checklist
lives in [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md); post-tag verification in
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md).

```text
feature branch (feat/*, fix/*, chore/*, docs/*) → PR to dev (squash merge)
                                                → release/v<version> cut from main, dev's tree overlaid
                                                → PR release/* to main (squash merge)
                                                → tag v* on main → GitHub Release
```

Direct commits to `dev` or `main` are not permitted: every change has a PR number in its squash commit message.

## Branches

| Branch                                 | Role                                                   | Lifetime                                    | Protection                           |
| -------------------------------------- | ------------------------------------------------------ | ------------------------------------------- | ------------------------------------ |
| `main`                                 | Released bundle. Only release-merged commits. Default. | Forever.                                    | `.github/rulesets/protect-main.json` |
| `dev`                                  | Integration. All feature PRs land here.                | Forever. Never delete.                      | `.github/rulesets/protect-dev.json`  |
| `feat/*`, `fix/*`, `chore/*`, `docs/*` | Feature work.                                          | One PR's worth. Auto-deleted on merge.      | None. Squash into `dev` freely.      |
| `release/*`                            | Head of a `release/* → main` PR.                       | One release's worth. Auto-deleted on merge. | None.                                |

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

### Dev-direct exception

Two categories of change commit directly to `dev` without going through the feature-branch + PR flow:

- **Engineering docs**: `docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`. These live on `dev`
  only; `guard-main-docs.yml` blocks them from reaching `main`, and the release recipe strips them from the release
  branch before the commit.
- **Prose-tooling vendoring vehicle**: `scripts/sync-prose-tooling.sh`. The script vendors `BRAND.md` from
  `agentnative-spec` and is a producer-side dev convenience, not part of the shipped bundle. The workflow guard's
  `extra_paths` list keeps it off `main`, and `scripts/release/guarded-paths.sh` reads that list so the release recipe
  strips it too. `BRAND.md` itself still ships to `main` (consumers read it), but the script that vendors it does not.

Everything else (consumer-facing markdown like `README`, `AGENTS`, `CONTRIBUTING`, `CHANGELOG`, the skill bundle content
under `SKILL.md` / `getting-started.md` / `spec/` / `references/` / `templates/`, and any in-repo runbook) goes through
the standard feature-branch + PR flow.

## PR body

Every PR (feature, fix, docs, release) uses `.github/pull_request_template.md` verbatim.

- **No explainer prose anywhere in the body.** User-facing substance only.
- **Summary describes the net diff only**: what merged `main` looks like vs the base branch. Not commit history,
  intermediate state, or release-branch mechanics.
- **Zero verification artifacts in the body.** No diff stats, leak-check output ("`guard-main-docs` runs clean"),
  patch-id cherry-check counts, pre-push gate results, CI status, or prose-scrub findings. Anomalies get fixed before
  push, not audit-trailed.
- **Changelog** subsections (`### Added` / `### Changed` / `### Fixed` / `### Removed` / `### Security`): 1-5 bullets
  each, delete empty subsections, each bullet starts with a verb.
- A PR with no user-facing impact (pure refactor, test-only, CI-only) leaves `## Changelog` empty or omits it.

→ Rationale: [`RELEASES-RATIONALE.md` § PR body conventions](./RELEASES-RATIONALE.md#pr-body-conventions).

## Releasing dev to main

Before cutting a release branch, walk [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md) end-to-end. Any unchecked item
holds the release.

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only.
`guard-main-docs.yml` blocks them from reaching `main`, and `guard-release-branch.yml` rejects any PR to `main` whose
head isn't `release/*`.

**Branch naming**: `release/v<version>` or `release/v<version>-<slug>`. `generate-changelog.py` extracts the version
from the branch name, so the `v<version>` prefix is required.

`main` and `dev` share only an ancient merge-base: every release squash-merges into `main`, so the two branches diverge
in history even as their content converges. Reconciling that with a merge, or a branch cut from `dev`, produces
`add/add` and rename/delete conflicts that are artifacts of the lineage, not of the content shipping. The release branch
is therefore built as a **clean descendant of `main`** with `dev`'s tree overlaid on top, asserting the desired
end-state directly:

```bash
# 0. Nothing on main that dev never received (security PRs, hotfixes, config). Exits 1 while drift exists.
scripts/release/drift.sh

# 1. Branch from main, NOT dev.
git fetch origin
git checkout -B release/v<version> origin/main

# 2. Overlay dev's entire tracked tree onto the main base. `checkout -- .` writes dev's
#    paths but does not delete files that exist on main and are absent on dev, so remove
#    those next (the 'D' rows are main-only files dev deleted).
git checkout origin/dev -- .
git diff --name-status origin/main origin/dev | grep '^D'
trash <each main-only file listed above>

# 3. Strip the paths guard-main-docs forbids on main. The set resolves from the workflow;
#    never restate it inline, because every hand-kept copy drifted from what CI enforces.
GUARDED="$(scripts/release/guarded-paths.sh)"
git ls-files | grep -E "$GUARDED" | xargs -r trash
git add -A                                                      # stages adds, mods, AND deletions

# 4. Bump VERSION (plain text, no leading "v"), re-vendor the spec if a new upstream tag
#    has shipped, then build the changelog from the PRs merged into dev since the previous
#    release. The overlay commit carries no per-PR history, so the section is built from
#    dev's PRs, not from this branch's commits.
echo '<version>' > VERSION
scripts/sync-spec.sh
scripts/generate-changelog.py --from-dev-prs
git add -A

# 5. Verify before committing.
#    A: staged tree equals dev's minus the version files and the stripped guarded paths.
#       spec/ rows are expected only when step 4 re-vendored the spec. Anything else
#       printed here is a mistake.
git diff --cached --name-only origin/dev | grep -Ev "$GUARDED" \
  | grep -Ev '^(VERSION|CHANGELOG\.md)$' \
  && echo "unexpected delta above; investigate" || echo "(clean: only intended deltas)"
#    B: no guarded path in the release tree.
git diff --cached --name-only origin/main | grep -E "$GUARDED" \
  && echo "LEAKED a guarded path: reset and redo" || echo "(no guarded paths)"
#    D: what this release ADDS to main. The leak check screens against the registered
#       set, so it is blind to a category nobody registered yet. Every docs/ entry and
#       every added markdown file needs a reason to ship, or it needs registering in the
#       workflow's extra_paths and removing from the branch.
git diff --cached --diff-filter=A --name-only origin/main | grep -E '(^docs/|\.md$)' | grep -Ev "$GUARDED" || echo "(none unguarded)"

# 6. Scrub CHANGELOG.md via Vale + LanguageTool + unslop (see § Prose scrubbing). Fix
#    findings on upstream PR bodies and re-run step 4's generator, never by hand-editing
#    CHANGELOG.md. Then commit the overlay as one commit sitting directly on top of main
#    and walk the "Release mechanics sanity" items in RELEASES-PREFLIGHT.md against it.
git commit -m "chore(release): v<version>"

# 7. Push and open the PR. Scrub body in /tmp/ first.
git push -u origin release/v<version>
gh pr create --base main --head release/v<version> \
  --title "release: v<version>: <one-line summary>" --body-file /tmp/body.md
```

The result is a single commit whose diff against `main` is the release, with `main` as an ancestor, so the PR merges
with zero conflicts. Auto-delete removes `release/v<version>` from the remote on merge. `dev` is untouched: never reset
or rebase `dev` after a release, it is forever.

→ Rationale (why overlay, not merge; why cut from `main`):
[`RELEASES-RATIONALE.md` § Branching model](./RELEASES-RATIONALE.md#branching-model). CHANGELOG mechanics:
[`RELEASES-RATIONALE.md` § CHANGELOG generation](./RELEASES-RATIONALE.md#changelog-generation). Spec re-vendoring:
[`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline).

### Exception: cherry-pick

The overlay is the release construction for this repo. Cherry-picking the dev squash-commits onto the `origin/main`
base is kept only as a fallback for a cut that cannot overlay for a stated reason (record it under
[Project specifics](#project-specifics)); the per-PR changelog is not such a reason, since `--from-dev-prs` builds it
from `dev` either way. When cherry-picking, run the triple-diff verification:

```bash
# 2. List the dev commits not yet on main.
git log --oneline dev --not origin/main

# 3. Cherry-pick the ones to ship. Docs commits stay on dev.
git cherry-pick <sha1> <sha2> ...

# 4. Triple-diff verification.
GUARDED="$(scripts/release/guarded-paths.sh)"

git diff origin/main..HEAD --stat                                              # A: ship surface
git diff HEAD..origin/dev --name-only | grep -Ev "$GUARDED" || echo "(none)"   # B: no missed picks
git diff origin/dev..origin/main --stat | tail -5                              # C: phantom-commits sanity

# Re-confirm no guarded paths leaked.
git diff origin/main..HEAD --name-only \
  | grep -E "$GUARDED" \
  && echo "LEAKED: reset and redo" || echo "(clean)"

# D: what this release ADDS to main (see step 5 above for why).
git diff origin/main..HEAD --diff-filter=A --name-only | grep -E '(^docs/|\.md$)' | grep -Ev "$GUARDED" || echo "(none unguarded)"

# Patch-id cherry check (noisy in squash-merge workflow; triage per-line).
git cherry HEAD origin/dev | grep '^+' || echo "(none)"
```

Cherry-picks of PRs that touched guarded paths hit modify/delete or rename/delete conflicts, since those paths live on
`dev` but are blocked from `main`; resolve them per the next section. Steps 4 to 7 of the overlay recipe then apply
unchanged.

→ Triple-diff false-positive triage:
[`RELEASES-RATIONALE.md` § Triple-diff verification](./RELEASES-RATIONALE.md#triple-diff-verification).

### Cherry-pick conflicts on guarded paths

Cherry-picks of feature PRs that touched a guarded path (`docs/plans/`, `docs/brainstorms/`, `docs/reviews/`,
`docs/solutions/`, `.context/`, `scripts/sync-prose-tooling.sh`) will hit modify/delete conflicts on the release
branch. Those paths exist on `dev` but are blocked from `main` by `guard-main-docs.yml`, so the cherry-pick sees them
as "deleted in HEAD, modified in `<commit>`". A PR that renames such a file also produces rename/delete conflicts on
the same paths.

Resolution (the standard `git rm` is denied by repo policy; use the plumbing form):

```bash
# 1. Mark every unmerged guarded path as deleted in the index.
git update-index --remove $(git diff --name-only --diff-filter=U)

# 2. Trash the orphan worktree files left by the rename target side.
trash docs/plans/<leftover-paths>.md

# 3. Continue the cherry-pick.
git cherry-pick --continue --no-edit
```

Repeat per conflicting commit. After all picks land, run `git ls-files | grep -E "$(scripts/release/guarded-paths.sh)"`.
If anything remains, drop it with the same two-step pattern and commit as `chore(release): drop stray guarded paths
from cherry-pick rename detection` before the leak check.

## Tagging and publishing

When the `release/v<version> → main` PR merges:

1. The squash commit lands on `main` with the PR body as its message.
2. `release/v<version>` is auto-deleted.
3. Tag the new `main` HEAD. Always use annotated tags (`-a -m`):

   ```bash
   git checkout main && git pull
   git tag -a v<version> -m "v<version>"
   git push origin v<version>
   ```

4. Create the GitHub Release from the generated CHANGELOG section. There is no `release.yml` in this repo; the tag push
   triggers nothing, and the Release is created by hand. Extract by version, never by position, and hand the notes
   over as a file:

   ```bash
   awk '/^## \[<version>\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md > /tmp/release-notes-v<version>.md
   gh release create v<version> --title "v<version>" --notes-file /tmp/release-notes-v<version>.md
   trash /tmp/release-notes-v<version>.md
   ```

Consumers detect the new release on their next `bin/check-update` run; nothing else to do here. Then walk
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md).

### After publish: sync `dev` with the release

Once the GitHub Release is published, bring the release bookkeeping (`VERSION`, `CHANGELOG.md`) back to `dev` so the
integration branch starts from the released baseline:

```bash
scripts/sync-dev-after-release.sh v<version>
```

The script writes the released version into `VERSION`, copies `CHANGELOG.md` verbatim from `origin/main`, cuts a
`chore/sync-dev-after-v<version>` branch off `dev`, and opens a PR against `dev`; merge it once CI is green. Never merge
`main` into `dev` or push to `dev` directly: the squash-merged histories share no recent ancestry, so the merge
conflicts on every file both sides touched, and a direct push bypasses `dev`'s required checks. Without this step
`dev`'s `VERSION` and `CHANGELOG.md` stay frozen at the pre-release state, and future feature branches inherit the
wrong baseline.

The backport is idempotent: re-running on a `dev` already in sync exits 0 without creating a branch or PR.

→ Rationale:
[`RELEASES-RATIONALE.md` § Why backport `main` → `dev` after publish](./RELEASES-RATIONALE.md#why-backport-main--dev-after-publish).

### After publish: bump consumer submodule pins

This skill is consumed as a git submodule by `brettdavies/agent-skills` (and any future skill aggregator). Consumers
only see the new release when the parent repo bumps its submodule pin. Without an explicit reminder this step lapses;
the pin has drifted three minor versions before being noticed during an unrelated audit.

For each consumer repo that vendors this skill as a submodule:

```bash
cd <consumer-repo>
git submodule update --remote agentnative
git add agentnative
git commit -m "chore(agentnative): bump submodule to v<version>"
git push
```

Known consumers:

- `brettdavies/agent-skills` (the personal skill bundle that powers `~/.claude/skills/`).

The pin bump is a single-commit edit; no PR required when the consumer repo's branch policy allows single-commit edits
direct to its integration branch. Verify with `git submodule status agentnative` in the consumer; the SHA should match
this skill's `v<version>` tag.

## Rollback

The bundle has no deploy or registry surface. Consumers `git clone --depth 1` the default branch and `bin/check-update`
compares their local `VERSION` against `main`, so the surface users consume is `main` at its head. That surface only
moves forward through a PR, which makes a rollback a forward fix rather than a re-point:

1. Land the `fix/*` or `revert` PR on `dev` through the normal flow.
2. Cut a patch release (`release/v<version>` with the next patch number) per
   [§ Releasing dev to main](#releasing-dev-to-main), tag it, and create its GitHub Release.

Do not delete or re-tag the bad release: tags are immutable anchors (`protect-tags.json`) and `bin/check-update` reads
`VERSION` on `main`, not the Release list. A consumer that needs the last-good bundle before the patch ships can pin
its checkout to the previous tag; that identifier is recorded before every release as a
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md) gate.

→ Rationale: [`RELEASES-RATIONALE.md` § Rollback](./RELEASES-RATIONALE.md#rollback).

## Version bump procedure

The version bump and CHANGELOG generation both happen on the `release/v<version>` branch (step 4 of the overlay recipe
above). There is no separate version-bump PR to `dev`. Picking the version is the only manual decision:

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
# scripts/generate-changelog.py --from-dev-prs  # for CHANGELOG.md (re-fetches the PR bodies from GitHub)
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
  convention plus `guard-release-branch` on the `main` side.
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

### Status-check contexts

| Check                    | Source                                               | Context                                     | Required by `protect-main.json` |
| ------------------------ | ---------------------------------------------------- | ------------------------------------------- | ------------------------------- |
| `markdownlint`           | inline job, `name: markdownlint`                     | `markdownlint`                              | yes                             |
| `shellcheck`             | inline job, `name: shellcheck`                       | `shellcheck`                                | yes                             |
| `guard-docs / ...`       | reusable workflow caller, job key `guard-docs`       | `guard-docs / check-forbidden-docs`         | yes                             |
| `guard-release / ...`    | reusable workflow caller, job key `guard-release`    | `guard-release / check-release-branch-name` | no                              |
| `guard-provenance / ...` | reusable workflow caller, job key `guard-provenance` | `guard-provenance / check-provenance`       | no                              |

The first three contexts are verified against a live run. Confirm all five post-CI with:

```bash
gh api repos/brettdavies/agentnative-skill/commits/<sha>/check-runs --jq '.check_runs[].name'
```

→ Rationale (inline vs reusable, three-ruleset shape):
[`RELEASES-RATIONALE.md` § Branch protection](./RELEASES-RATIONALE.md#branch-protection).

## Project specifics

- **Version carrier**: `VERSION` (plain text `X.Y.Z`, no leading `v`). `bin/check-update` reads it on consumer
  machines and compares against `main`.
- **Distribution channel**: `git clone --depth 1 https://github.com/brettdavies/agentnative-skill` (default branch
  `main`) and the `brettdavies/agent-skills` submodule pin. No package registry, no binaries, no `release.yml`.
- **Spec re-vendor**: `scripts/sync-spec.sh` on the release branch (step 4) when `agentnative-spec` has shipped a new
  `v*` tag since the last release. The vendored version lives in `spec/VERSION`.
- **Release tooling**: `scripts/release/drift.sh`, `scripts/release/guarded-paths.sh`, `scripts/generate-changelog.py`
  (with `cliff.toml`), and `scripts/sync-dev-after-release.sh` are verbatim copies from the `github-repo-setup` skill;
  refresh by copy, never edit in place. The skill's preflight and postflight orchestrators are not vendored: the bundle
  has no build, smoke, or pipeline surface for them to drive, so the checklists run by hand.
- **Required secrets**: none. `gh` auth is enough for the changelog generator and the backport script.

## Related docs

- [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md) (pre-flight checklist; gates the cut of `release/v<version>`)
- [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md) (post-tag verification; runs after the tag push)
- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md) (release flow rationale, CHANGELOG pipeline, branch-protection
  pitfalls)
- [`AGENTS.md`](./AGENTS.md) (repo layout, lint commands, what agents must not do)
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) (how to propose changes)
- [`.github/pull_request_template.md`](.github/pull_request_template.md) (PR body structure with changelog sections)
- [`.github/rulesets/README.md`](.github/rulesets/README.md) (ruleset apply + verify procedure)
- [`CHANGELOG.md`](./CHANGELOG.md) (released versions and their notes)
