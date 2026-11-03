<!-- Canonical version: 2026.11.03 (generic) -->
<!-- canonical: version-scheme semver -->
# Releasing `agentnative-skill`

Operational runbook. Rationale lives in [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md). Pre-cut go/no-go checklist
lives in [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md); post-tag verification in
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md).

```text
feature branch → PR to dev (squash merge)
              → dev's tree overlaid onto a release/* branch cut from main
              → PR to main (squash merge)
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
- **PR body**: follow `.github/pull_request_template.md`. See [§ PR body](#pr-body).

### Dev-direct exception

Paths that live only on `dev` and never ship to `main` can be committed directly to `dev` without a feature branch or
PR. The `guard-main-docs` workflow blocks them from `main` PRs regardless. The exception applies to:

- Engineering docs: `docs/brainstorms/`, `docs/ideation/`, `docs/plans/`, `docs/research/`, `docs/reviews/`,
  `docs/solutions/`, and anything under `.context/`.
- `scripts/sync-prose-tooling.sh`, registered through `extra_paths`. It vendors `BRAND.md` from `agentnative-spec` and
  is a producer-side dev convenience, not part of the shipped bundle. `BRAND.md` itself ships to `main`; the script that
  vendors it does not.

`scripts/release/guarded-paths.sh` prints the authoritative set, resolved from the workflow. Run it rather than trusting
this list, which is a reading aid. A path that stays off `main` but is not in the reusable workflow's base list is
registered through the caller's `extra_paths` input in `.github/workflows/guard-main-docs.yml`; entries are globs (`**/`
any depth, `*` and `?` within a segment, a trailing `/` guards the subtree).

The standard feature → PR → squash-merge flow remains required for everything else, including consumer-facing markdown
(README, AGENTS, CONTRIBUTING, CHANGELOG, in-repo runbooks) and the skill bundle content under `SKILL.md`,
`getting-started.md`, `spec/`, `references/`, and `templates/`.

## PR body

Every PR (feature, fix, docs, release) uses `.github/pull_request_template.md` verbatim. Six required sections, in
template order, no inventions: `## Summary`, `## Changelog`, `## Type of Change`, `## Related Issues/Stories`,
`## Testing`, `## Files Modified`. The template's other sections (`## Key Features`, `## Benefits`,
`## Breaking Changes`, `## Deployment Notes`, `## Screenshots/Recordings`, `## Checklist`, `## Additional Context`) are
optional: fill `## Breaking Changes` on a major, delete the rest when they do not apply.

- **No explainer prose anywhere in the body.** User-facing substance only.
- **Summary describes the net diff only**: what merged `main` looks like vs the base branch. Not commit history,
  intermediate state, or release-branch mechanics.
- **Zero verification artifacts in the body.** No triple-diff stats, leak-check output, patch-id cherry-check counts,
  pre-push gate results, CI status, or prose-scrub findings. Anomalies get fixed before push, not audit-trailed.
- **Changelog** subsections (`### Breaking changes` / `### Added` / `### Changed` / `### Deprecated` / `### Fixed` /
  `### Documentation`, the six headings of [§ Versioning](#versioning)): 1-5 bullets each, delete empty subsections,
  each bullet starts with a verb. A `## Changelog` heading left standing with no bullets under it says the PR ships
  nothing user-facing, and `generate-changelog.py` adds nothing for it, whatever the PR title says.
- **Type of Change**: one checkbox. Prefer `feat`/`fix` over `chore` for any user-observable change.
- **Related Issues/Stories**: four labels (`Story:` / `Issue:` / `Architecture:` / `Related PRs:`). All four required
  even when empty (`- None.` / `n/a`).
- **Files Modified**: four sub-headers (`Modified` / `Created` / `Renamed` / `Deleted`). All four required even when
  empty.
- **No AI attribution** in commits or PR bodies.
- **No hard line wraps**: one logical line per paragraph or bullet.

→ Rationale: [`RELEASES-RATIONALE.md` § PR body conventions](./RELEASES-RATIONALE.md#pr-body-conventions).

## Versioning

The marked lines below are github-repo-setup's SemVer section of `references/versioning.md`, which the drift check
compares, and line 2 declares the scheme.

<!-- canonical:begin versioning-semver -->

This repo follows [SemVer 2.0.0](https://semver.org/). Its version comes from its changelog: every PR files each
user-facing change under one of the six headings below, and a release takes the highest bump any of its PRs calls for.
The rules cover only the surfaces § What the contract is names.

### What the contract is

<!-- canonical:repo-begin contract -->

The bundle's contract is what hosts, `anc skill install`, and agents running an installed copy rely on:

- **Install layout:** `git clone --depth 1` of `main` puts `SKILL.md` at the clone root, with `getting-started.md`,
  `references/`, `templates/`, `spec/`, `bin/check-update`, and `VERSION` beside it. `anc skill install <host>` clones
  into the host's skills directory as `agent-native-cli` and reads a root `SKILL.md` as an install.
- **Skill identity:** the `name: agent-native-cli` field of `SKILL.md`'s frontmatter, which hosts find the skill by and
  which names the install directory.
- **File paths:** `getting-started.md` and the file names in `references/` and `templates/`, which a project's own
  instructions can point an agent at inside an installed copy.
- **Update check:** `bin/check-update`'s path; its output, one `UPGRADE_AVAILABLE <old> <new>` line or nothing; its exit
  code, 0 in every case; its `AGENTNATIVE_SKILL_DIR`, `AGENTNATIVE_SKILL_REMOTE_URL`, and `AGENTNATIVE_SKILL_STATE_DIR`
  overrides; and the `update-snoozed` (`<version> <level> <epoch>`) and `disabled` files an agent writes under
  `$HOME/.cache/agent-native-cli/`, as [`references/update-check.md`](./references/update-check.md) describes.
- **Version file:** `VERSION`, one SemVer line at the root, which `bin/check-update` compares with `main`'s copy.
- **Vendored spec:** `spec/`, holding the `agentnative-spec` release `spec/VERSION` names, and its principles and their
  MUSTs. A re-vendor that renames or removes a principle, or tightens a MUST existing consumers meet, is a break; one
  that adds requirements without tightening an existing tier is an addition; prose-only edits are neither, whatever
  level the spec release itself took.

The wording, order, and examples in `SKILL.md`'s body, `getting-started.md`, and `references/` are not contract. Neither
are the `description` field's wording while it keeps the skill findable for the tasks it covers, the code inside
`templates/`, which a project copies once and then owns, `bin/check-update`'s cache file and its TTLs, or any
producer-side file (`scripts/`, `docs/`, `.github/`, the `RELEASES*.md` runbooks, `cliff.toml`).

<!-- canonical:repo-end -->

### The six headings

| Heading            | Holds                                                                   | Bump  |
| ------------------ | ----------------------------------------------------------------------- | ----- |
| `Breaking changes` | a contract surface removed, renamed, or retyped, or its meaning changed | major |
| `Added`            | a new contract surface                                                  | minor |
| `Changed`          | a visible change outside the contract                                   | patch |
| `Deprecated`       | a contract surface marked for removal                                   | minor |
| `Fixed`            | behavior brought back to the documented contract                        | patch |
| `Documentation`    | documentation only                                                      | patch |

`generate-changelog.py` writes them in this order and any other heading after them. A contract removal is a
`Breaking changes` bullet that starts with "Remove"; a removal outside the contract goes under `Changed`, or is left
out. Removals ship when they are ready, with no deprecation schedule. A `type!:` commit is a prompt to check the PR's
sections, never the bump itself.

### The bump

`scripts/generate-changelog.py --bump` prints the next version from the PRs merged since the last release, and
`cut-release-branch.sh` prints it beside the version the cut is given:

- The highest heading among their sections sets the bump.
- A `rust-version` raised since the last tag is a minor-level change, so it lifts a patch to a minor. A Rust repo's
  `rust-version` equals the toolchain `rust-toolchain.toml` pins, and CI's MSRV job builds on exactly that version.
- Before 1.0, a major or a minor moves the middle number and a patch moves the last: `0.4.2` becomes `0.5.0` or `0.4.3`.
  This is stricter than Cargo's convention on purpose: an addition never ships as a last-number bump, so a `^0.y`
  dependent receives only fixes until it opts in.
- From 1.0, when the sections call for a major, the release agent asks the maintainer: a major, or a minor under the
  small-break exception. A minor ships `docs/migrating/v<version>.md`, whose first line names the exception, and
  preflight fails a 1.0+ release that keeps its major and carries `### Breaking changes` without that guide.

### Overrides

<!-- canonical:repo-begin overrides -->

One addition to the bump: a spec re-vendor made on the release branch in step 2 of
[§ Releasing dev to main](#releasing-dev-to-main) comes after `--bump` has read the PRs, so the maintainer weighs it by
the vendored-spec rule of [§ What the contract is](#what-the-contract-is) and the release takes the higher of the two
bumps.

<!-- canonical:repo-end -->

<!-- canonical:end versioning-semver -->

## Releasing dev to main

Before cutting a release branch, walk [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md) end-to-end. Any unchecked item
holds the release.

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only.
`guard-main-docs.yml` blocks them from reaching `main`, and `guard-release-branch.yml` rejects any PR to main whose head
isn't `release/*`.

**Branch naming**: `release/v<version>` or `release/v<version>-<slug>`. `generate-changelog.py` extracts the version
from the branch name, so the `v<version>` prefix is required.

`main` and `dev` share only an ancient merge-base: every release squash-merges into `main`, so the two branches diverge
in history even as their content converges. Reconciling that with a merge, or a branch cut from `dev`, produces a pile
of rename/delete conflicts that are artifacts of the lineage, not of the content shipping. The release branch is
therefore built as a **clean descendant of `main`** with `dev`'s tree overlaid on top, asserting the desired end-state
directly. `scripts/release/cut-release-branch.sh` builds it:

```bash
# 1. Build the branch: drift gate, branch from main, overlay dev's tree, strip the
#    guarded paths, generate the changelog, and run checks A, B, and D. Stops
#    before committing; --dry-run prints the plan and touches nothing.
scripts/release/cut-release-branch.sh <version>

# 2. Bump the version carriers (see § Project specifics): write <version> into
#    VERSION, and re-vendor the spec when agentnative-spec has shipped a new v* tag.
printf '%s\n' "<version>" > VERSION
scripts/sync-spec.sh

# 3. Commit the overlay as one commit sitting directly on top of main, then run the
#    preflight gates against it.
git add -A
git commit
scripts/release/preflight.sh all

# 4. Push and open the PR. Scrub the body in /tmp/ first.
git push -u origin release/v<version>
gh pr create --base main --head release/v<version> --title "release: v<version>" --body-file /tmp/body.md
```

The script asserts `dev`'s tree onto the `main` base with `git read-tree -u --reset`, one operation that carries the
deletions too. Asserting the tree is what keeps a file `main` carries and `dev` deleted from shipping to `main` anyway.
A diff-driven overlay has to enumerate those deletions separately, and with rename detection on, such a file pairs with
any similar `dev`-side addition, reports as `R` rather than `D`, and drops off the list entirely.

It then strips the paths `guard-main-docs` forbids, resolved from the workflow by `scripts/release/guarded-paths.sh`
rather than from any restated copy, writes the changelog with
`scripts/generate-changelog.py --from-dev-prs --tag v<version>`, and runs three checks:

| Check                                    | Asserts                                                                                                                                                                           | On failure                                                                                                     |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| A: staged tree vs `origin/dev`           | nothing differs but the version carriers (`VERSION` and `CHANGELOG.md` here) and the stripped guarded paths                                                                       | fails, naming each unexpected path                                                                             |
| B: guarded paths vs `origin/main`        | no guarded path is added or modified (`--diff-filter=ACMR`, so removing a guarded doc `main` still carries reads as cleanup, not a leak)                                          | fails, naming each leak                                                                                        |
| D: unguarded docs added to `origin/main` | every added `docs/` entry or markdown file is meant to ship (`--no-renames`, so a doc moved from one `main` carries lists as added rather than as a rename the filter would drop) | reports, never fails: each needs a reason to ship, or registering in the workflow's `extra_paths` and removing |

Check A runs before step 2, so a spec re-vendor in step 2 adds `spec/` rows to the release that the check never saw.
Review them with `git diff --cached --stat -- spec/` before committing; they are the only rows besides `VERSION` and
`CHANGELOG.md` a release may carry beyond `dev`'s tree.

The worktree must be clean before it runs, because the overlay resets the index and working tree. Only exit 0 leads to
step 2:

| Exit | Meaning                                                                                    | Next                                                                                          |
| ---- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| 0    | The branch is staged and every check passed; the script prints the commit steps.           | Step 2.                                                                                       |
| 1    | The drift gate, the changelog step, or a check failed.                                     | Never commit the branch. A drift failure stops before branching; any other recovers as below. |
| 2    | Setup error: a dirty worktree, an unknown ref, a missing tool, or no guarded-path pattern. | Fix what it names. Only the guarded-path error stops after branching; it recovers as below.   |

A cut that stopped after branching, at a failed check or at any failing step, leaves the overlay staged on the release
branch and prints the way back instead of the commit steps. Everything staged is the script's own output, because the
worktree was clean when it started, so discarding it loses nothing:

```bash
git checkout -f dev
git branch -D release/v<version>
```

Then fix the cause and re-run; the script refuses the dirty worktree a failed cut leaves behind.

Scrub `CHANGELOG.md` before the commit in step 3 (see [§ Prose scrubbing](#prose-scrubbing)). Fix findings on the
upstream PR bodies and re-run the generator, never by hand-editing `CHANGELOG.md`.

The result is a single commit whose diff against `main` is the release, with `main` as an ancestor, so the PR merges
with zero conflicts. Consumers read `main` directly (`git clone --depth 1` of the default branch, and `bin/check-update`
comparing against `main`'s `VERSION`), so the merge itself is what ships: merge and tag in one sitting, so `main` never
carries a version with no tag or GitHub Release behind it. Auto-delete removes `release/v<version>` from the remote on
merge. `dev` is untouched.

→ Rationale (why overlay, not merge; why cut from `main`):
[`RELEASES-RATIONALE.md` § Branching model](./RELEASES-RATIONALE.md#branching-model). CHANGELOG mechanics:
[`RELEASES-RATIONALE.md` § CHANGELOG generation](./RELEASES-RATIONALE.md#changelog-generation).

### Exception: cherry-pick

The overlay is the release construction for every repo on this flow. Cherry-picking the dev squash-commits onto the
`origin/main` base is the exception, kept for a release that has a stated reason it cannot overlay; the per-PR changelog
is not such a reason, since `--from-dev-prs` builds it from `dev` either way. When cherry-picking, run the triple-diff
verification:

```bash
# 1. Nothing on main that dev never received, then branch from main, NOT dev.
scripts/release/drift.sh
git fetch origin
git checkout -B release/v<version> origin/main

# 2. List the dev commits not yet on main.
git log --oneline dev --not origin/main

# 3. Cherry-pick the ones to ship. Docs commits stay on dev.
git cherry-pick <sha1> <sha2> ...

# 4. Triple-diff verification.
GUARDED="$(scripts/release/guarded-paths.sh)"

git diff origin/main..HEAD --stat                                              # A: ship surface
git diff HEAD..origin/dev --name-only | grep -Ev "$GUARDED" || echo "(none)"   # B: no missed picks
git diff origin/dev..origin/main --stat | tail -5                              # C: phantom-commits sanity

# Re-confirm no guarded paths leaked. --diff-filter=ACMR for the same reason as the
# overlay's check B: a deletion of a guarded path main still carries is cleanup, not a
# leak, and an unfiltered grep aborts a correct release over it.
git diff origin/main..HEAD --diff-filter=ACMR --name-only \
  | grep -E "$GUARDED" \
  && echo "LEAKED — reset and redo" || echo "(clean)"

# D: what this release ADDS to main (see the overlay's check D for why). --no-renames
#    lists a doc moved from one main carries as added; rename detection would report it as R.
git diff --no-renames origin/main..HEAD --diff-filter=A --name-only | grep -E '(^docs/|\.md$)' | grep -Ev "$GUARDED" || echo "(none unguarded)"

# Patch-id cherry check (noisy in squash-merge workflow; triage per-line).
git cherry HEAD origin/dev | grep '^+' || echo "(none)"
```

Cherry-picks of PRs that touched guarded paths hit modify/delete or rename/delete conflicts, since those paths live on
`dev` but are blocked from `main`; resolve them per the next section. Then generate the changelog the way the cut script
does (`scripts/generate-changelog.py --from-dev-prs --tag v<version>`), and finish with steps 2 to 4 of the overlay
procedure.

→ Triple-diff false-positive triage:
[`RELEASES-RATIONALE.md` § Triple-diff verification](./RELEASES-RATIONALE.md#triple-diff-verification).

### Cherry-pick conflicts on guarded paths

Cherry-picks of feature PRs that touched `docs/plans/` / `docs/brainstorms/` / `docs/ideation/` / `docs/reviews/` /
`docs/solutions/` / `.context/` files will hit modify/delete conflicts on the release branch. Those paths exist on `dev`
but are blocked from `main` by `guard-main-docs.yml`, so the cherry-pick sees them as "deleted in HEAD, modified in
`<commit>`". A PR that renames such a file also produces rename/delete conflicts on the same paths.

Resolution (the standard `git rm` is denied by repo policy; use the plumbing form):

```bash
# 1. Mark every unmerged guarded path as deleted in the index.
git update-index --remove $(git diff --name-only --diff-filter=U)

# 2. Trash the orphan worktree files left by the rename target side.
gio trash docs/plans/<leftover-paths>.md

# 3. Continue the cherry-pick.
git cherry-pick --continue --no-edit
```

Repeat per conflicting commit. After all picks land, run `git ls-files | grep -E "$(scripts/release/guarded-paths.sh)"`.
If anything remains, drop it with the same two-step pattern and commit as
`chore(release): drop stray guarded paths from cherry-pick rename detection` before the leak check. Rename detection
occasionally re-adds a path under the rename target's new name; the post-pick check catches that.

## Tagging and publishing

After the `release/v<version> → main` PR merges, tag and push:

```bash
git checkout main && git pull
git tag -a -m "Release v<version>" v<version>
git push origin v<version>
```

Always use annotated tags (`-a -m`). There is no `release.yml` in this repo: the tag push triggers nothing, and the
GitHub Release is created by hand from the generated CHANGELOG section. Extract by version, never by position, and hand
the notes over as a file:

```bash
awk '/^## \[<version>\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md > /tmp/release-notes-v<version>.md
gh release create v<version> --title "v<version>" --notes-file /tmp/release-notes-v<version>.md
trash /tmp/release-notes-v<version>.md
```

A Release created this way is the repo's latest unless marked otherwise, so no finalize step flips it. Consumers detect
the new release on their next `bin/check-update` run. Then run `scripts/release/postflight.sh all` and walk
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md).

→ Rationale: [`RELEASES-RATIONALE.md` § Release pipeline](./RELEASES-RATIONALE.md#release-pipeline).

### After publish: sync `dev` with the release

Once the GitHub Release is published, bring the release bookkeeping (`VERSION`, `CHANGELOG.md`) back to `dev` so the
integration branch starts from the released baseline:

```bash
scripts/sync-dev-after-release.sh v<version> --dry-run   # see what diverged
scripts/sync-dev-after-release.sh v<version>
```

The script cuts a `chore/sync-dev-after-v<version>` branch, writes the released version into every version carrier
present (`VERSION` here), copies the release changelog from `main`, adopts the paths discovery classes as release-prep,
and opens a PR against `dev` with the version in its title. `--dry-run` prints the contested paths and the paths it
would sync, then creates no branch and leaves the tree clean. A `dev` already in sync exits 0 with nothing committed.

Besides the version carriers and `CHANGELOG.md`, the script **discovers** every other path `main` and `dev` disagree
about, minus the guarded set. A release branch gets edited for reasons no fixed list predicts (a spec re-vendor in step
2 is the usual one here), and those edits are made against `main`'s base and never round-trip; without discovery they
stay on `main` alone until the next release quietly reverts them.

Each discovered path is classified against the **previous** release tag, the last point the branches agreed:

| Class          | Condition                                                   | Action                                          |
| -------------- | ----------------------------------------------------------- | ----------------------------------------------- |
| `release-prep` | `dev`'s copy is byte-identical to its copy at the prior tag | Adopted: `main`'s version is pure release-prep  |
| `contested`    | Both branches moved the path since the prior tag            | Reported, not adopted, unless you say otherwise |

The classification is what keeps a wider copy safe, since `dev` is normally ahead of `main` and adopting `main`'s
version of a file `dev` has moved on would revert unreleased work. `--include-contested` takes every contested path,
which is rarely right. Prefer `--only PATH` (repeatable) to name the ones you want; it intersects with the discovered
set, so a guarded, undiverged, or misspelled path is refused rather than forced through. Guarded paths never enter
discovery, so the sync cannot remove `dev`-only content.

After the commit, when the sync carried the release changelog and `git-cliff` is installed, the script re-runs
`scripts/generate-changelog.py --dry-run` with the cut's arguments and, if that does not pass, warns with the
generator's own reason line (a PR body edited after the release, or a difference in line wrapping only). The warning
does not block the backport.

The script opens a PR against `dev`; merge it once CI is green. The postflight backport gate looks for its
`chore(release): sync dev after <tag>` subject on `dev`. Never merge `main` into `dev` or push to `dev` directly: the
squash-merged histories share no recent ancestry, so the merge conflicts on every file both sides touched, and a direct
push bypasses `dev`'s required checks.

After it merges, confirm the branches actually converged. This is what catches a contested path nobody resolved:

```bash
git fetch origin
git diff --name-only origin/dev origin/main | grep -Ev "$(scripts/release/guarded-paths.sh)" || echo "(converged)"
```

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

A bad release is rolled back at the deploy or registry surface first, then repaired in git. This bundle has no deploy or
registry surface: consumers `git clone --depth 1` the default branch, and `bin/check-update` compares their local
`VERSION` against `main`, so the surface users consume is `main` at its head. That surface only moves forward through a
PR, which makes a rollback a forward fix rather than a re-point:

1. Land the `fix/*` or `revert` PR on `dev` through the normal flow.
2. Cut a patch release (`release/v<version>` with the next patch number) per
   [§ Releasing dev to main](#releasing-dev-to-main), tag it, and create its GitHub Release.

Do not delete or re-tag the bad release: tags are immutable anchors (`protect-tags.json`) and `bin/check-update` reads
`VERSION` on `main`, not the Release list. A consumer that needs the last-good bundle before the patch ships can pin its
checkout to the previous tag; knowing that identifier before the release goes out is a
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md) gate.

→ Rationale: [`RELEASES-RATIONALE.md` § Rollback](./RELEASES-RATIONALE.md#rollback).

## Version bump procedure

The version bump and CHANGELOG generation both happen on the `release/v<version>` branch (steps 1 and 2 of the overlay
recipe above). There is no separate version-bump PR to `dev`. The changelog sections of the PRs merged since the last
release pick the version, by the rules in [§ Versioning](#versioning): `scripts/generate-changelog.py --bump` prints it,
and step 1's `cut-release-branch.sh` passes when the version it was given matches. When they differ, the cut reports a
skip naming the computed version; settle which one ships before the commit in step 3.

→ Rationale: [`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline) (skill
version is independent of spec version).

## Prose scrubbing

Three release-flow artifacts live outside any automated prose check and need a manual scrub before they ship:

- PR bodies (`gh pr create` / `gh pr edit` send body text directly to GitHub).
- `CHANGELOG.md` (a generated artifact built from upstream PR bodies).
- Release-PR bodies (composed after `CHANGELOG.md` has been generated).

The canonical Vale + LanguageTool rule packs live in the agentnative-spec repo at
`~/dev/agentnative-spec/docs/architecture/voice-enforcement.md`. Each repo points Vale at the spec checkout via
`--config`; the spec is the source of truth, not vendored locally.

```bash
# 1. Save the artifact to /tmp/.
gh pr view <num> --json body --jq .body > /tmp/body.md         # for PR body edits
# cp CHANGELOG.md /tmp/body.md                                 # for changelog scrub

# 2. Vale (against the spec's rule packs).
vale --no-global --config ~/dev/agentnative-spec/.vale.ini --output=line --minAlertLevel=error /tmp/body.md

# 3. LanguageTool grammar check via lt_check (~/dotfiles/config/shell/languagetool.sh).
#    Skips cleanly if LanguageTool is unreachable. Inspect: `lt_rules`, `lt_info`.
lt_check /tmp/body.md

# 4. unslop (em-dash density and AI-unique structural patterns).
~/.claude/skills/unslop/scripts/score.py /tmp/body.md

# 5. Apply fixes per finding. Re-run until 0 blocking and unslop score is 0.

# 6. Apply the cleaned version.
gh pr edit <num> --body-file /tmp/body.md     # for PR body edits
```

For a `CHANGELOG.md` finding, fix the upstream PR body (which `generate-changelog.py` re-fetches every run) and
regenerate. Hand-editing `CHANGELOG.md` directly produces drift the next regeneration overwrites.

→ Rationale + which artifacts need this:
[`RELEASES-RATIONALE.md` § Prose scrubbing scope](./RELEASES-RATIONALE.md#prose-scrubbing-scope).

## Branch protection

Three rulesets are committed under `.github/rulesets/` and applied to the repo via the GitHub API:

- `protect-main.json` (required signatures, linear history, squash-only merges via PR with CODEOWNERS review, required
  status checks (`markdownlint`, `shellcheck`, `guard-docs / check-forbidden-docs`,
  `guard-provenance / check-provenance`, `guard-release / check-release-branch-name`), creation/deletion blocked,
  non-fast-forward blocked).
- `protect-dev.json` (required signatures, deletion blocked, non-fast-forward blocked). PR-only norm is convention +
  `guard-release-branch` on the main side.
- `protect-tags.json` (`v*` tags: deletion, force-push, and updates all blocked). Tags are immutable historical anchors
  for released versions.

### Applying changes

```bash
# First apply (creating a ruleset):
gh api -X POST repos/brettdavies/agentnative-skill/rulesets --input .github/rulesets/protect-dev.json

# Subsequent updates (replace by ID — find via `gh api repos/brettdavies/agentnative-skill/rulesets`):
gh api -X PUT repos/brettdavies/agentnative-skill/rulesets/<id> --input .github/rulesets/protect-main.json
```

All three rulesets are installed on this repo. Verify with:

```bash
gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[] | "\(.id)\t\(.name)\t\(.target)"'
```

### Status-check contexts

| Check                    | Source                                               | Context                                     | Required by `protect-main.json` |
| ------------------------ | ---------------------------------------------------- | ------------------------------------------- | ------------------------------- |
| `markdownlint`           | inline job, `name: markdownlint`                     | `markdownlint`                              | yes                             |
| `shellcheck`             | inline job, `name: shellcheck`                       | `shellcheck`                                | yes                             |
| `guard-docs / ...`       | reusable workflow caller, job key `guard-docs`       | `guard-docs / check-forbidden-docs`         | yes                             |
| `guard-release / ...`    | reusable workflow caller, job key `guard-release`    | `guard-release / check-release-branch-name` | yes                             |
| `guard-provenance / ...` | reusable workflow caller, job key `guard-provenance` | `guard-provenance / check-provenance`       | yes                             |

Confirm all five contexts appear on a PR to `main` with:

```bash
gh api repos/brettdavies/agentnative-skill/commits/<sha>/check-runs --jq '.check_runs[].name'
```

→ Status-check context strings (inline vs reusable):
[`RELEASES-RATIONALE.md` § Status-check context strings](./RELEASES-RATIONALE.md#status-check-context-strings).

## Project specifics

- **Version carriers**: `VERSION` (plain text `X.Y.Z`, no leading `v`), bumped in step 2 of the release.
  `bin/check-update` reads it on consumer machines and compares against `main`. `CHANGELOG.md` is the release changelog,
  written by the cut script.
- **Spec re-vendor**: `scripts/sync-spec.sh` in step 2 when `agentnative-spec` has shipped a new `v*` tag since the last
  release. The vendored version lives in `spec/VERSION`; `preflight.sh smoke` compares it with the newest tag and fails
  on a release branch that skipped the re-vendor.
- **Distribution channels**:

| Channel             | How it lands                                                                    |
| ------------------- | ------------------------------------------------------------------------------- |
| `git clone`         | `git clone --depth 1 https://github.com/brettdavies/agentnative-skill` (`main`) |
| `anc skill install` | the same clone, into each host's skill directory                                |
| Submodule           | `brettdavies/agent-skills` pins a commit; bumped by hand after each release     |

  No package registry, no binaries, no `release.yml`.

- **Release tooling**: `scripts/release/` holds the github-repo-setup orchestrators. `cut-release-branch.sh`,
  `drift.sh`, `guarded-paths.sh`, `postflight.sh`, and `_lib.sh` are verbatim copies, as are
  `scripts/generate-changelog.py` (with `cliff.toml`) and `scripts/sync-dev-after-release.sh`; refresh by copy, never
  edit in place. `preflight.sh` is the skeleton with this bundle's smoke gates filled in, and `release.env` is this
  repo's values file.
- **Required secrets**: none. `gh` auth is enough for the changelog generator, the orchestrators, and the backport
  script.
- **Rollback commands**: none beyond [§ Rollback](#rollback); the bundle has no registry to yank from.

These belong in this file (`RELEASES.md`), not in the trio companions: they are operational ship-channel details, not
rationale or pre-cut checks.

## Related docs

- [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md): pre-cut go/no-go checklist gating release-branch creation.
- [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md): post-tag verification of the publish.
- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md), release-flow rationale: branching, PR body, pipeline, prose-check.
- [`.github/pull_request_template.md`](.github/pull_request_template.md): PR body structure with changelog sections.
- [`AGENTS.md`](AGENTS.md): repo layout, lint commands, what agents must not do.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): how to propose changes.
