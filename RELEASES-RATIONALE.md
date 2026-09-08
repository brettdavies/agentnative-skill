# Releases rationale

Companion to [`RELEASES.md`](./RELEASES.md). RELEASES.md is the runbook (commands, paths, decision tables). This file
holds the WHY behind those rules: branching model, PR conventions, the guarded set, CHANGELOG generation, spec-vendor
pipeline, `bin/check-update` semantics, backport and rollback, branch-protection pitfalls.

Read this when:

- A rule in RELEASES.md doesn't make sense and you're tempted to change it.
- A new contributor asks "why do we do X this way".
- You're adding a new release-flow rule and need to know where it fits the existing model.

## Branching model

### Forever `dev`, ephemeral release branches

`dev` is never deleted, even after a release. The next release cycle reuses the same `dev`. The repo's
`delete_branch_on_merge: true` setting doesn't touch `dev` because `dev` is never the head of a PR. Using a short-lived
`release/*` head is what keeps the setting compatible with a forever integration branch.

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only. They never
reach `main`. `guard-main-docs.yml` blocks any `added` or `modified` engineering-doc files in PRs targeting `main`, and
`guard-release-branch.yml` rejects any PR to `main` whose head isn't `release/*`. The release recipe strips the guarded
set from the branch before the commit, so the guard is a backstop rather than the first line.

### Why the release branch is cut from `main`, never from `dev`

Every release squash-merges into `main`, so `dev` and `main` diverge in history even as their content converges: after
the first release they share only an ancient merge-base. Cutting the release branch from `dev` (or merging `dev` into
`main`) forces a 3-way merge across that divergence: `add/add` collisions on files both sides changed, plus
rename/delete pairs git cannot auto-resolve. The conflict pile is an artifact of the lineage, not of the content
shipping.

Always cut the release branch from `origin/main` and bring `dev`'s content onto it as a forward diff, never by
reconciling histories. The default is the whole-tree overlay (`git checkout origin/dev -- .`, then strip the guarded
set): `main` ships `dev`'s tree minus a small, known exclusion set, so asserting that end-state directly is simpler and
safer than hand-resolving a merge. The overlay commit carries no per-PR history, so the changelog is built from the PRs
merged into `dev` since the previous release (`generate-changelog.py --from-dev-prs`) rather than from the branch's
commits; the result is the same per-PR section a cherry-picked branch would yield. Cherry-picking the dev
squash-commits is kept only as an exception for a cut with a stated reason it cannot overlay, at the cost of
guarded-path conflict handling.

Either way, the release must start from a `main` that `dev` fully contains. Security PRs, hotfixes, and config edits
land on `main` first, and both constructions take `dev`'s content for the files they touch, so anything `main` holds
that `dev` never received is reverted by the release. `scripts/release/drift.sh` lists that set and the cut waits until
it is empty.

### Why `main` is the default branch + release pointer

Consumers install the bundle via `git clone --depth 1` (see `SKILL.md` install commands), which lands on the default
branch. `main` is therefore the published-release pointer; `dev` is the integration branch. Each release requires the
skill maintainer to fast-forward `main` to the new tag (the `release/* → main` PR squash-merge does this).

### Version branch naming

`release/v<version>` or `release/v<version>-<slug>` keeps release branches sortable and unambiguous when more than one
cut is in flight. `generate-changelog.py` extracts the version from the branch name, so the `v<version>` prefix is
required. Slug is kebab-case, short, descriptive.

## PR body conventions

### No explainer prose in the body

Every section of a PR body is user-facing substance only: what is changing for the consumer that was not already there,
the **net diff**, not the commit history or intermediate state that produced it. Workflow mechanics (overlay,
regenerate, pre-push gate, CI behavior) are documented in RELEASES.md and `.github/`, NOT in the PR body. Diff output,
leak-check narration ("`guard-main-docs` runs clean", "no guarded paths leaked"), patch-id cherry-check counts, pre-push
gate results, CI check status, exclusion rationale, and other verification artifacts stay local; anomalies get fixed
before push, not audit-trailed in the body.

The PR body is read by humans reviewing what shipped. Workflow mechanics and tool-fix provenance are noise from that
perspective; they belong in this file, the script outputs, and the commit history respectively.

## The guarded set

### Why the guarded set resolves from the workflow

`guard-main-docs` is what CI enforces on a PR to `main`: the reusable workflow's hardcoded base list plus this repo's
`extra_paths` (`scripts/sync-prose-tooling.sh`). Every hand-kept copy of that union (runbook, checklist, leak-check
one-liner) drifts from it, and a copy that omits a guarded path reports a real leak as clean while CI turns red after
the push. `scripts/release/guarded-paths.sh` reads `extra_paths` out of the caller workflow and adds the base list, so
registering a path in the workflow is the only edit a new guarded path needs. The base list is the one copy that still
needs a manual edit when the reusable changes, because it lives in another repo. Entries are globs with one rule set
shared by the reusable and the script (`**/` any depth, `*` and `?` within a segment, trailing slash guards the
subtree), so the two never disagree about what is guarded.

### Why the release enumerates what it adds

The leak check screens the diff against the registered set, so it says nothing about a category nobody registered. A
new engineering directory or a stray note under `docs/` passes the local check and `guard-main-docs` alike. Step D of
the release recipe lists every `docs/` file and every markdown file the release adds to `main` outside the guarded set
and puts them in front of a human; each one needs a reason to ship, or it gets registered in `extra_paths` and dropped
from the branch. Root-level markdown is in scope because an agent-facing note at the repo root is exactly the kind of
addition a `docs/`-only listing misses.

## Triple-diff verification

The cherry-pick exception runs three diffs (A: main→release, B: release→dev filtered by the guarded set, C: dev→main)
plus a patch-id cherry check. This is belt-and-suspenders because missed cherry-picks have shipped to `main` on this and
sibling repos before, and the file-level diff in B alone doesn't catch the patch-id false-negative class. The overlay
recipe keeps A, B, and D (the additions listing) and drops the patch-id check, since a single overlay commit has no
per-commit patch-ids to compare.

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
merged into `dev` since the previous release are the entries, and each PR's body supplies its `## Changelog → ###
Breaking changes / Added / Changed / Fixed / Documentation` subsections (with author and PR-link attribution). On a
cherry-picked branch it runs `git-cliff` first to prepend a versioned entry from the branch's commits, then expands the
same way.

If a PR's body carries no changelog content, its title becomes a `Changed` bullet, except for `chore`, `ci`, `build`,
`style`, and `test` PRs, which stay out unless they carry a `## Changelog` of their own. To fix a wrong CHANGELOG entry,
fix the input: edit the squash-merged PR body, then re-run the script. Do **not** edit `CHANGELOG.md` directly.

`scripts/generate-changelog.py --check` verifies that `CHANGELOG.md` has a versioned section (not just `[Unreleased]`):
wire this into the release-branch CI if/when one is added.

### Why `cliff.toml` skips chore/style/test/ci/build

These commit types do not produce user-facing content. On a cherry-picked branch, a PR with user-facing `## Changelog`
content whose commit subject starts with one of those types gets its bullets silently dropped; on an overlay branch the
same PR drops out of `--from-dev-prs` unless its body carries a `## Changelog`. After running the script, cross-check
the generated section against `gh pr view <num> --json body` for each PR; correct mistyped PR titles (e.g. `chore` →
`feat`) before re-running. See "Prefer `feat`/`fix` over `chore`" in global CLAUDE.md for prevention.

## Spec-vendor pipeline

The bundle vendors a snapshot of [`agentnative-spec`](https://github.com/brettdavies/agentnative) under `spec/`. When
the spec ships a new tag (e.g., `v0.3.0`), this skill re-vendors via `scripts/sync-spec.sh` on the `release/v<version>`
branch, in the same overlay commit as the version bump. The script auto-resolves the latest upstream tag from the
remote, so no manual version selection is needed.

Without re-vendoring, the bundle ships stale spec content while consumers see the new version on `anc.dev`. Re-vendoring
on the release branch keeps the on-disk snapshot in lockstep with the published version that consumers will detect via
`bin/check-update`.

### Skill version is independent of spec version

The skill's version is independent of the spec it vendors. A spec bump that doesn't affect the skill's surface (e.g.,
prose-only edits) can ship as a patch even when the spec went minor. SemVer guidance applies to the *skill's* observable
behaviour, not the spec's:

- **Patch** (doc updates, internal cleanups, non-substantive template edits, vendoring a patch-level spec bump).
- **Minor** (new templates, new reference docs, new bundle files (backward-compatible additions), vendoring a
  minor-level spec bump that adds requirements without tightening existing tiers).
- **Major** (breaking changes to the bundle's contract: renaming `SKILL.md` frontmatter fields, restructuring directory
  layout in ways that break existing skill installations, moving content between subdirectories and the producer-ops
  root, or vendoring a major-level spec bump (renamed/removed principles or tightened MUSTs that would regress existing
  consumers)).

## `bin/check-update` semantics

Update detection at install sites is delegated to the bundle's `bin/check-update`, which compares the local bundle's
`VERSION` against `main` on GitHub. This is a pull-side mechanism: there is no push or notification. Consumers detect
the new release on their next `bin/check-update` run.

This is why `main` (not `dev`) must be the published-release pointer: a `git clone --depth 1` lands on `main`, and
`bin/check-update` compares against `main`. Cutting a release without fast-forwarding `main` would mean consumers never
see the new VERSION.

## Why backport `main` → `dev` after publish

Once a release tag publishes, the release-bookkeeping files on `main` (`VERSION`, `CHANGELOG.md`) need to reach `dev` so
future feature branches inherit the correct baseline.

Without the backport, `dev` keeps the pre-release `VERSION` indefinitely (the release bump lives only on the `release/*`
branch that was squash-merged to `main` and never touched `dev`). Feature branches cut from `dev` then carry a stale
baseline: confusing during review, and load-bearing in two places: (a) `bin/check-update` compares the caller's local
`VERSION` against the producer repo's `main`, so a stale local `VERSION` from a `dev` clone would falsely report
`UPGRADE_AVAILABLE` on a current main; (b) the next release's diff-B lists `VERSION` and `CHANGELOG.md` as expected
noise only when `dev` is current, so a stale baseline hides a real missed change behind expected rows.

The backport is a PR opened by `scripts/sync-dev-after-release.sh` (`chore/sync-dev-after-vX.Y.Z`), never a merge of
`main` into `dev` and never a direct push. The squash-merged branches share no recent history, so a merge conflicts on
every file both sides touched, and a direct push to `dev` bypasses its required status checks. The script writes the
released version into every version carrier it finds (`VERSION` here), copies `CHANGELOG.md` from `main`, and opens the
PR; the merged PR is the durable signal that the backport ran. The diff is mechanical, so reviewers can spot-check and
squash-merge as usual.

The script is idempotent: it exits 0 without creating a branch or PR when `VERSION` and `CHANGELOG.md` already match
`main`. Safe to re-run, safe to invoke from automation that doesn't track whether the last release was already
backported.

## Rollback

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
- **`CHANGELOG.md`.** A generated artifact built from upstream PR bodies. Findings inherit whatever prose those PR
  bodies carry.
- **Release-PR bodies.** The `release/* → main` PR carries contributor-authored wrap-up text composed after
  `CHANGELOG.md` has been generated, and the same out-of-repo gap applies.

The canonical Vale + LanguageTool rule packs and orchestrator behaviour live in the spec repo at
[`~/dev/agentnative-spec/docs/architecture/voice-enforcement.md`](https://github.com/brettdavies/agentnative/blob/dev/docs/architecture/voice-enforcement.md).
Until those packs are vendored into this repo via a `scripts/sync-spec.sh` extension (a deferred follow-up tracked in
the spec plan), the scrub commands point at the spec checkout directly.

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

### Why the apply step is re-runnable

The three rulesets ship in `.github/rulesets/` and are applied via the GitHub API. The apply commands in RELEASES.md are
deliberately idempotent so they survive: (a) a bootstrap window in which the repo is private (GitHub's free tier does
not allow rulesets on private repos, so rulesets cannot be applied until visibility flips); (b) any future ruleset
reset; (c) the same procedure being copied into a new repo's bootstrap.

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

- [`RELEASES.md`](./RELEASES.md) (operational runbook: commands, paths, decision tables)
- [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md) (pre-cut checklist gating the release-branch cut)
- [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md) (post-tag verification)
- [`AGENTS.md`](./AGENTS.md) (repo layout, lint commands, what agents must not do)
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) (how to propose changes)
- [`.github/pull_request_template.md`](.github/pull_request_template.md) (PR body structure with changelog sections)
- [`.github/rulesets/README.md`](.github/rulesets/README.md) (ruleset apply + verify procedure)
- [`CHANGELOG.md`](./CHANGELOG.md) (released versions and their notes)
