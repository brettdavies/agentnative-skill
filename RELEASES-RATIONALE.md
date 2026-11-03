<!-- Canonical version: 2026.11.03 (generic) -->
# Releases rationale

Companion to [`RELEASES.md`](./RELEASES.md). RELEASES.md is the runbook (commands, paths, decision tables). This file
holds the WHY behind those rules: branching model, PR conventions, release pipeline, CHANGELOG generation, spec-vendor
pipeline, `bin/check-update` semantics, prose-check pipeline, branch-protection pitfalls.

Read this when:

- A rule in RELEASES.md doesn't make sense and you're tempted to change it.
- A new contributor asks "why do we do X this way".
- You're adding a new release-flow rule and need to know where it fits the existing model.

## Branching model

### Forever `dev`, ephemeral release branches

`dev` is never deleted, even after a release. The next release cycle reuses the same `dev`. The repo's
`deleteBranchOnMerge: true` setting doesn't touch `dev` as long as `dev` is never the head of a PR. Using a short-lived
`release/*` head is what keeps the setting compatible with a forever integration branch.

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only. They never
reach `main`. `guard-main-docs.yml` blocks them from PRs targeting `main`, and `guard-release-branch.yml` rejects any PR
to main whose head isn't `release/*`.

### Why the release branch is cut from `main`, never from `dev`

Every release squash-merges into `main`, so `dev` and `main` diverge in history even as their content converges: after
the first release they share only an ancient merge-base. Cutting the release branch from `dev` (or merging `dev` into
`main`) forces a 3-way merge across that divergence: `add/add` collisions on files both sides changed, plus
rename/delete pairs git cannot auto-resolve. The conflict pile is an artifact of the lineage, not of the content
shipping.

Always cut the release branch from `origin/main` and bring `dev`'s content onto it as a forward diff, never by
reconciling histories. The default is the whole-tree overlay (`dev`'s tree asserted onto the base with
`git read-tree -u --reset`, then the guarded set stripped): `main` ships `dev`'s tree minus a small, known exclusion
set, so asserting that end-state directly is simpler and safer than hand-resolving a merge. The overlay commit carries
no per-PR history, so the changelog is built from the PRs merged into `dev` since the previous release
(`generate-changelog.py --from-dev-prs`) rather than from the branch's commits; the result is the same per-PR section a
cherry-picked branch would yield. Cherry-picking the dev squash-commits is kept only as an exception for a release with
a stated reason it cannot overlay, at the cost of guarded-path conflict handling.

Either way, the release must start from a `main` that `dev` fully contains. Security PRs, hotfixes, and config edits
land on `main` first, and both constructions take `dev`'s content for the files they touch, so anything `main` holds
that `dev` never received is reverted by the release. `scripts/release/drift.sh` lists that set and the cut waits until
it is empty.

### Why a script builds the release branch

The overlay and its checks are where a hand-typed command goes wrong quietly. `git checkout origin/dev -- .` writes
`dev`'s paths but leaves every file `main` carries and `dev` deleted, so those have to be read off a diff and removed,
and that diff and the added-docs listing both need `--no-renames`: with rename detection on, a deleted file pairs with
any similar addition, reports as `R`, and drops out of a filter on `D` or `A`. `scripts/release/cut-release-branch.sh`
asserts the tree with `git read-tree -u --reset`, which carries the deletions with no diff to read, and runs its checks
as code the `github-repo-setup` bats suite covers. The version bump stays with the operator: here it is `VERSION` plus
an optional spec re-vendor, and whether a new spec tag ships in this release is a judgment, not an input the script can
take.

### Why `main` is the default branch + release pointer

Consumers install the bundle via `git clone --depth 1` (see `SKILL.md` install commands), which lands on the default
branch. `main` is therefore the published-release pointer; `dev` is the integration branch. The `release/* → main` PR
squash-merge is what moves `main` to the new release, so the merge itself is what consumers receive.

### Version branch naming

Branch naming `release/v<version>` or `release/v<version>-<slug>` makes release branches sortable and unambiguous when
multiple cuts are in flight. `generate-changelog.py` extracts the version from the branch name, so the `v<version>`
prefix is required. Slug is kebab-case, short, descriptive.

## PR body conventions

### No explainer prose in the body

Every section of a PR body is user-facing substance only: the **net diff**, what is changing for the consumer that was
not already there, not the commit history or intermediate state that produced it. Workflow mechanics (overlay,
regenerate, pre-push gate, CI behavior) are documented in RELEASES.md and `.github/`, NOT in the PR body. Triple-diff
output, leak-check narration, patch-id cherry-check counts, pre-push gate results, CI check status, exclusion rationale,
and other verification artifacts stay local; anomalies get fixed before push, not audit-trailed in the body.

The PR body is read by humans reviewing what shipped. Workflow mechanics and tool-fix provenance are noise from that
perspective; they belong in this file, the script outputs, and the commit history respectively.

### Why `feat`/`fix` are preferred over `chore`

`cliff.toml` drops commits whose subject starts with `chore`, `style`, `test`, `ci`, or `build` regardless of body
content. Mistyping a user-facing change as `chore` silently strips it from release notes. Prefer `feat` / `fix` when the
change has any user-observable effect (new or changed bundle content, templates, references, `bin/check-update`
behavior).

Security advisory bumps in particular use `fix(deps):`, never `chore(deps):`, so they appear in the changelog. A bumped
dependency that closes a CVE is user-visible value, not internal tooling.

### Why required-when-empty sub-headers

`Related Issues/Stories` has four labels (`Story:` / `Issue:` / `Architecture:` / `Related PRs:`). `Files Modified` has
four sub-headers (`Modified` / `Created` / `Renamed` / `Deleted`). All four must appear in every PR, even when empty:
write `- None.` or `n/a` rather than deleting the label. Reason: scanners and humans both rely on a known section shape.
Conditionally-absent sections force every reader to mentally check "did the author skip this or does it not apply?"

### Why no AI attribution

`Co-Authored-By: Claude ...`, robot emoji / "Generated with Claude Code" trailers, or any similar AI-attribution trailer
is banned from commit messages and PR bodies. Commits and PRs stand on their own technical content. Attribution trailers
are noise and they age poorly as tools shift.

### Why no hard line wraps

Author each paragraph and each bullet as one logical line, however long. GitHub soft-wraps for display. Hard wraps
within prose produce visible mid-sentence breaks in some renderers and interfere with the prose-check pipeline: Vale's
line-anchored output reports findings against split lines, and LanguageTool's input handling can choke on certain
control-char interactions.

### Why release-PR bodies repeat changelog entries from upstream PRs

The release PR carries the same changelog bullets as the feature PRs it ships. The repetition is intentional and
harmless: the release PR merges into `main`, so `--from-dev-prs`, which reads `dev`'s history, never sees it, and
`cliff.toml` skips the `release:` squash commit on the git-cliff path, so it is never counted twice.

### Why internal-tooling commits don't appear in `## Changelog`

`chore(cliff): ...`, `chore(ci): ...`, and similar internal-tooling commits don't appear in the PR body's
`## Changelog`. They are not user-facing. They belong in commit history and in the Files Modified section of the PR
body, not in the source-of-truth release notes.

## Triple-diff verification

`cut-release-branch.sh` screens the staged release tree twice before the commit (A: release→dev for paths outside the
guarded set and the version carriers, B: no guarded path added or modified in release→main) and enumerates what the
release adds (D). The cherry-pick exception runs three diffs (A: main→release, B: release→dev for paths outside the
guarded set, C: dev→main) plus a patch-id cherry check. This is belt-and-suspenders because missed cherry-picks have
shipped to `main` on this and sibling repos before, and the file-level diff in B alone doesn't catch the patch-id
false-negative class.

B excludes only the guarded set, not all of `docs/`: `docs/SYNCS.md` ships to `main`, and a blanket `docs/` filter would
hide a missed change there.

### Why the guarded set resolves from the workflow

`guard-main-docs` is what CI enforces on a PR to `main`: the reusable workflow's hardcoded base list plus this repo's
`extra_paths` (`scripts/sync-prose-tooling.sh`). Every hand-kept copy of that union (runbook, checklist, preflight
script) drifted from it, and a copy that omits a guarded path reports a real leak as clean while CI turns red after the
push. `scripts/release/guarded-paths.sh` reads `extra_paths` out of the caller workflow and adds the base list, so
registering a path in the workflow is the only edit a new guarded path needs. The base list is the one copy that still
needs a manual edit when the reusable changes, because it lives in another repo. Entries are globs with one rule set
shared by the reusable and the script (`**/` any depth, `*` and `?` within a segment, trailing slash guards the
subtree), so `**/.agent/` guards that directory wherever it appears and the two never disagree about what is guarded.

### Why the release enumerates what it adds

The leak check screens the diff against the registered set, so it says nothing about a category nobody registered. A new
engineering directory or a stray note under `docs/` passes the local check and `guard-main-docs` alike. Step D lists
every `docs/` file and every markdown file the release adds to `main` outside the guarded set and puts them in front of
a human; each one needs a reason to ship, or it gets registered in `extra_paths` and dropped from the branch. Root-level
markdown is in scope because an agent-facing glossary at the repo root is exactly the kind of addition a `docs/`-only
listing misses.

### Why patch-id cherry-check output is noisy

In a squash-merge workflow, `git cherry HEAD origin/dev` produces many `+` lines that need human triage. They do NOT
auto-block the release. Expected sources of false positives:

1. **Historical commits squash-merged in prior releases.** The squash commit on main has a different patch-id than the
   dev commits it consolidates, so old commits show as `+` forever. Anything older than the previous release tag is
   almost always this.
2. **Cherry-picks where conflict resolution stripped guarded paths** (`docs/plans/`, `docs/brainstorms/`, etc.) or
   otherwise altered the tree. Same source-code intent, different patch-id.
3. **Intentionally skipped commits** (docs-only commits, release-prep backports, revert-and-redo prep steps).

A real miss looks like: a recent feat/fix/chore commit on dev whose *file content* is not yet on main. To triage a `+`
line:

```bash
git show <sha> --stat                       # what did it touch?
git diff origin/main..HEAD -- <those-files> # already on release?
```

If every touched file is guarded OR the content is already on main via a prior squash, it's a false positive (no
action). Otherwise cherry-pick the commit and re-run the triple-diff.

## CHANGELOG generation

### Generated, never hand-written

`scripts/generate-changelog.py` (vendored from the `github-repo-setup` skill, with the repo-local `cliff.toml`) is the
only sanctioned way to update `CHANGELOG.md`. On an overlay-built release branch it runs as `--from-dev-prs`: the PRs
merged into `dev` since the previous release are the entries, and each PR's body supplies its `## Changelog` subsections
under the six headings of [`RELEASES.md` § Versioning](./RELEASES.md#versioning) (`Breaking changes`, `Added`,
`Changed`, `Deprecated`, `Fixed`, `Documentation`), with author and PR-link attribution. A heading outside the six still
renders, after them. On a cherry-picked branch it runs `git-cliff` first to prepend a versioned entry from the branch's
commits, then expands the same way.

If a PR's body offers no changelog section at all, its title becomes a bullet under the group `cliff.toml` gives the
same commit (`type!:` under Breaking changes, `feat` under Added, `fix` under Fixed, `docs` under Documentation,
anything else under Changed), except for `chore`, `ci`, `build`, `style`, and `test` PRs, which stay out unless they
carry a `## Changelog` of their own, and the `release:` PR, which is bookkeeping. A body that carries the `## Changelog`
heading and leaves it empty is the PR template's way of saying the PR ships nothing user-facing, and the fallback
respects that whatever the title: internal work also lands as `fix(ci)`, `fix(hooks)`, or `fix(release)`, which the skip
list does not cover. `preflight.sh changelog-sections` names every PR whose entry would fall back to its title. To fix a
wrong CHANGELOG entry, fix the input: edit the squash-merged PR body, then re-run the script. Do **not** edit
`CHANGELOG.md` directly.

`preflight.sh mechanics` checks that `CHANGELOG.md` opens on the version `VERSION` names, with no `[Unreleased]`
placeholder. The GitHub Release body is cut by hand from the section whose heading names the tag's version
([`RELEASES.md` § Tagging and publishing](./RELEASES.md#tagging-and-publishing)).

### Why the changelog sections set the version

A SemVer release's bump comes from the headings its PRs filed, not from commit markers or a judgment made at the cut:
the author of a change knows best whether it adds, fixes, or breaks a contract surface, and the heading records that
answer where review sees it. `generate-changelog.py --bump` reads the same sections the release notes are built from, so
the version and the notes cannot disagree. A `!:` commit stays a cross-check: a PR can break the contract with no
marker, and a marker can sit on a change outside the contract. The rules, the pre-1.0 shift, the MSRV rule, and the
small-break exception are in [`RELEASES.md` § Versioning](./RELEASES.md#versioning).

### Why `cliff.toml` skips chore/style/test/ci/build

These commit types do not produce user-facing content, so neither generation path emits a bullet for one on the strength
of its subject alone. What differs is the handling when such a PR *does* carry `## Changelog` content, and the two paths
differ in a way that decides how much the title matters:

- **`--from-dev-prs`.** The generator enumerates merged PRs and reads each body directly. A body with `## Changelog`
  content is extracted whatever the title says, so a `test:` or `chore:` PR carrying real bullets still lands in the
  section. The skip list applies only to the no-body fallback, where the title would otherwise become a bullet on its
  own.
- **`git-cliff` (the cherry-pick path).** The commit parsers drop these types from the skeleton before any PR body is
  fetched, so the PR number never enters the section, the expansion pass never reaches it, and its bullets are silently
  lost.

So on a cherry-picked branch a mistyped subject loses content: cross-check the generated section against `gh pr view
<num> --json body`, correct the title (e.g. `chore` → `feat`), re-amend the cherry-pick subject, and re-run. On a
`--from-dev-prs` branch the title costs only the fallback bullet, so the check worth making there is narrower: a PR with
an *empty* `## Changelog` and a skipped type that nonetheless shipped something user-facing. Either way the fix is to
the input, never to `CHANGELOG.md`.

## Spec-vendor pipeline

The bundle vendors a snapshot of [`agentnative-spec`](https://github.com/brettdavies/agentnative) under `spec/`. When
the spec ships a new tag (e.g., `v0.3.0`), this skill re-vendors via `scripts/sync-spec.sh` on the `release/v<version>`
branch, in the same overlay commit as the version bump. The script auto-resolves the latest upstream tag from the
remote, so no manual version selection is needed, and `preflight.sh smoke` compares `spec/VERSION` with that same tag.

Without re-vendoring, the bundle ships stale spec content while consumers see the new version on `anc.dev`. Re-vendoring
on the release branch keeps the on-disk snapshot in lockstep with the published version that consumers will detect via
`bin/check-update`.

### Skill version is independent of spec version

The skill's version is independent of the spec it vendors. A spec bump that doesn't affect the skill's surface (e.g.,
prose-only edits) can ship as a patch even when the spec went minor. SemVer applies to the *skill's* observable
behaviour, not the spec's: [`RELEASES.md` § What the contract is](./RELEASES.md#what-the-contract-is) names the surfaces
and weighs a re-vendor by what it does to them, so renamed or removed principles and tightened MUSTs that would regress
existing consumers are a break, added requirements that tighten no existing tier are an addition, and prose-only edits
are neither.

## `bin/check-update` semantics

Update detection at install sites is delegated to the bundle's `bin/check-update`, which compares the local bundle's
`VERSION` against `main` on GitHub. This is a pull-side mechanism: there is no push or notification. Consumers detect
the new release on their next `bin/check-update` run.

This is why `main` (not `dev`) must be the published-release pointer: a `git clone --depth 1` lands on `main`, and
`bin/check-update` compares against `main`. Cutting a release without moving `main` would mean consumers never see the
new `VERSION`.

`preflight.sh smoke` runs it with a stale local `VERSION` as a negative control. Every other smoke gate passes the same
way whether the comparison works or not; only an install that must be told to upgrade shows the check still does its
job.

## Release pipeline

### Annotated tags, no publish workflow

Always use annotated tags (`-a -m`). Bare `git tag <name>` silently fails with `fatal: no tag message?` on machines
where `tag.gpgsign=true` is set globally (a brettdavies dotfile default). See
[solutions: git tag fails with tag.gpgsign, use annotated tags](https://github.com/brettdavies/solutions-docs/blob/main/best-practices/git-tag-fails-with-tag-gpgsign-use-annotated-tags-2026-04-13.md).

The bundle has nothing to build, sign, or publish to a registry, so the tag push triggers no `release.yml`. The GitHub
Release is created by hand from the tag's `CHANGELOG.md` section, and `gh release create` marks it latest directly, so
there is no `make_latest: false` window and no `finalize-release` callback to flip it. `postflight.sh` is vendored
verbatim anyway: its `make-latest` and `backport` gates carry weight here, and its pipeline gates SKIP with a reason
rather than failing.

### Why backport `main` → `dev` after publish

Once a release tag publishes, the release-bookkeeping files on `main` (`VERSION`, `CHANGELOG.md`) need to reach `dev` so
future feature branches inherit the correct baseline.

Without the backport, `dev` keeps the pre-release `VERSION` indefinitely (the release bump lives only on the `release/*`
branch that was squash-merged to `main` and never touched `dev`). Feature branches cut from `dev` then carry a stale
baseline: confusing during review, and load-bearing in two places: (a) `bin/check-update` compares the caller's local
`VERSION` against the producer repo's `main`, so a stale local `VERSION` from a `dev` clone would falsely report
`UPGRADE_AVAILABLE` on a current main; (b) the next release's diff-B and drift gate 0 read `VERSION` and `CHANGELOG.md`
as expected only when `dev` is current, so a stale baseline hides a real missed change behind expected rows.

The backport is a PR opened by `scripts/sync-dev-after-release.sh` (`chore/sync-dev-after-vX.Y.Z`), never a merge of
`main` into `dev` and never a direct push. The squash-merged branches share no recent history, so a merge conflicts on
every file both sides touched, and a direct push to `dev` bypasses its required status checks. The script writes the
released version into every version carrier it finds (`VERSION` here), copies `CHANGELOG.md` from `main`, and opens the
PR; the postflight backport gate treats the backport's own subject on `dev` (`chore(release): sync dev after <tag>`, or
`chore(release): backport <tag> artifacts to dev` on a commit made without a PR) as the durable signal that the backport
ran, so a feature PR that only mentions the version does not satisfy it. Guarded paths never enter the copy, so the
backport cannot remove `dev`-only content.

The other paths are discovered rather than listed. A release branch is edited for reasons nobody predicts (a spec
re-vendor, a doc fix, a reverted payload), each such edit is made against `main`'s base, and a fixed list misses it
silently until the next release's overlay restores `dev`'s copy over it. Discovery is bounded by the previous release
tag, the last point the branches agreed: a path `dev` left alone since then is release-prep and adopted, and a path
`dev` also changed is contested and withheld unless the operator names it, so widening the copy cannot revert `dev`'s
unreleased work.

The script is idempotent: it exits 0 without creating a branch or PR when `dev` already matches `main` on every path it
would sync.

### Rollback

Rollback happens at the surface users consume, not in git. For most projects that surface is a deployment, a registry,
or a formula, where re-pointing traffic or yanking a version is fast and reversible. This bundle's surface is `main`
itself: consumers `git clone --depth 1` the default branch and `bin/check-update` compares against `main`, so the only
way to change what users get is to move `main`, and `main` only ever moves forward through a PR. A bad release is
therefore repaired by a forward patch release through `dev`, a release branch, and `main` like any other change.
Deleting or re-tagging the bad version would not help (the ruleset blocks it, and `bin/check-update` never reads the tag
list) and would break the one guarantee consumers rely on: a tag always resolves to the bytes it shipped. Recording the
last-good tag before the release is what lets a consumer pin to it while the patch is in flight.

## Prose scrubbing scope

Three release-flow artifacts live outside any automated prose check and need a manual scrub before they ship:

- **PR bodies.** `gh pr create` and `gh pr edit` send body text directly to GitHub; no automated prose check has reach
  there.
- **`CHANGELOG.md`.** A generated artifact built from upstream PR bodies; it inherits whatever prose those PR bodies
  carry, so scrubbing happens at generation time on the release branch.
- **Release-PR bodies.** The `release/v<version>` PR to `main` carries contributor-authored wrap-up text composed after
  `CHANGELOG.md` has been generated, and the same out-of-repo gap applies.

The canonical Vale + LanguageTool rule packs and orchestrator behavior live in the agentnative-spec repo. This repo does
not vendor a local copy of those packs; point Vale at the spec checkout via `--config`.

Scrub-before-submit (author in `/tmp/`, scrub there, submit via `--body-file`) avoids the round-trip of "submit, scrub,
edit, scrub again". Every fix lands locally and the public PR sees only clean text. The auto-format hook skips `/tmp/`
paths so the body keeps its authored shape and no soft-wrapping is injected.

For a `CHANGELOG.md` finding, fix the upstream PR body (which `generate-changelog.py` re-fetches every run) and
regenerate. Hand-editing `CHANGELOG.md` directly produces drift the next regeneration overwrites.

## Branch protection

### Why three rulesets

This repo ships three rulesets (`protect-main.json`, `protect-dev.json`, `protect-tags.json`) where peer repos ship two.
The third (`protect-tags.json`) treats `v*` tags as immutable historical anchors for released versions: deletion,
force-push (re-tag), and updates are all blocked. The bundle's `bin/check-update` and the `git clone --depth 1` install
path both rely on `main` and on tag identity; a re-tagged release would lie to consumers about what they're installing.

The apply commands in RELEASES.md are idempotent so they survive a ruleset reset and copy cleanly into a new repo's
bootstrap.

### Status-check context strings

The `required_status_checks[].context` strings in `protect-main.json` MUST match exactly what GitHub publishes for each
check:

- **Inline job** (with `name:` field): published as just `<job-name>` (no workflow-name prefix).
- **Reusable-workflow caller** (`uses: .../foo.yml@ref`): published as `<caller-job-id> / <reusable-job-id-or-name>`.

Mixing these produces a stuck-but-green PR: all actual checks report green, but the ruleset waits forever on a context
that will never appear. Confirm the real contexts after a first CI run with:

```bash
gh api repos/brettdavies/agentnative-skill/commits/<sha>/check-runs --jq '.check_runs[].name'
```

### Why rulesets live in-repo

Committing the JSON alongside code means ruleset changes land via the same review process as workflow changes. A
`chore(ci): tighten protect-main` change goes through dev → release/* → main like anything else.

## Related docs

- [`RELEASES.md`](./RELEASES.md): operational runbook (commands, paths, decision tables).
- [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md): pre-cut checklist gating the release-branch cut.
- [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md): post-tag verification.
- [`.github/pull_request_template.md`](.github/pull_request_template.md): PR body structure with changelog sections.
- [`CHANGELOG.md`](./CHANGELOG.md): released versions and their notes.
