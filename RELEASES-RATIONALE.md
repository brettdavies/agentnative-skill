# Releases rationale

Companion to [`RELEASES.md`](./RELEASES.md). RELEASES.md is the runbook (commands, paths, decision tables). This file
holds the WHY behind those rules: branching model, PR conventions, CHANGELOG generation, spec-vendor pipeline,
flat-bundle convention, `bin/check-update` semantics, cross-host install considerations, branch-protection pitfalls.

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
reach `main`. `guard-main-docs.yml` blocks any `added` or `modified` engineering-doc files in PRs targeting `main`. The
release-branch cherry-pick handles this cleanly: docs commits stay on `dev`, only feature/fix/chore commits go onto
`release/*`.

### Why cherry-pick from `main`, not branch from `dev`

Branching from `dev` and then `gio trash`-ing the guarded paths seems simpler but produces `add/add` merge conflicts
whenever `dev` and `main` have diverged. The file appears as "added" on both sides with different content. Always branch
from `origin/main` and cherry-pick onto it.

### Why `main` is the default branch + release pointer

Consumers install the bundle via `git clone --depth 1` (see `SKILL.md` install commands), which lands on the default
branch. `main` is therefore the published-release pointer; `dev` is the integration branch. Each release requires the
skill maintainer to fast-forward `main` to the new tag (the `release/* → main` PR squash-merge does this).

## PR body conventions

### No explainer prose in the body

Every section of a PR body is user-facing substance only: what is changing for the consumer that was not already there —
the **net diff**, not the commit history or intermediate state that produced it. Workflow mechanics (cherry-pick,
regenerate, pre-push gate, CI behavior) is documented in RELEASES.md and `.github/`, NOT in the PR body. Triple-diff
output ("A: 12 files, B: none, C: clean"), leak-check narration ("`guard-main-docs` runs clean", "no guarded paths
leaked"), patch-id cherry-check counts, pre-push gate results, CI check status, exclusion rationale, and other
verification artifacts stay local; anomalies get fixed before push, not audit-trailed in the body.

The PR body is read by humans reviewing what shipped. Workflow mechanics and tool-fix provenance are noise from that
perspective; they belong in this file, the script outputs, and the commit history respectively.

## Triple-diff verification

The release-PR procedure runs three diffs (A: main→release, B: release→dev for non-doc paths, C: dev→main) plus a
patch-id cherry check. This is belt-and-suspenders because missed cherry-picks have shipped to `main` on this and
sibling repos before, and the file-level diff in B alone doesn't catch the patch-id false-negative class.

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

If every touched file is guarded (`docs/plans/`, `docs/brainstorms/`, etc.) OR the content is already on main via a
prior squash, it's a false positive (no action). Otherwise cherry-pick the commit and re-run the triple-diff.

## CHANGELOG generation

### Generated, never hand-written

`scripts/generate-changelog.sh` (with `cliff.toml`) is the only sanctioned way to update `CHANGELOG.md`. The script:

- Runs `git-cliff` to prepend a versioned entry for commits since the last tag.
- Walks each squash-merged PR's body, extracts the `## Changelog → ### Added / Changed / Fixed / Documentation`
  subsections, and replaces the auto-generated bullets with the curated PR-body content (with author and PR-link
  attribution).

If a PR's `## Changelog` section is empty, that PR's entry is omitted from the changelog (empty section = no user-facing
change). To fix a wrong CHANGELOG entry, fix the input: edit the squash-merged PR body, then re-run the script. Do
**not** edit `CHANGELOG.md` directly.

`scripts/generate-changelog.sh --check` verifies that `CHANGELOG.md` has a versioned section (not just `[Unreleased]`):
wire this into the release-branch CI if/when one is added.

### Why `cliff.toml` skips chore/style/test/ci/build

These commit types do not produce user-facing content. If a cherry-picked PR has user-facing `## Changelog` content but
its commit subject starts with one of those types, its bullets get silently dropped. After running the script,
cross-check the generated section against `gh pr view <num> --json body` for each cherry-picked PR; correct mistyped PR
titles (e.g. `chore` → `feat`) and re-amend the cherry-pick subject before re-running. See "Prefer `feat`/`fix` over
`chore`" in global CLAUDE.md for prevention.

## Spec-vendor pipeline

The bundle vendors a snapshot of [`agentnative-spec`](https://github.com/brettdavies/agentnative) under `spec/`. When
the spec ships a new tag (e.g., `v0.3.0`), this skill re-vendors via `scripts/sync-spec.sh` on the `release/v<X.Y.Z>`
branch (same commit as the version bump, message `chore(spec): re-vendor spec to <version>`). The script auto-resolves
the latest upstream tag from the remote, so no manual version selection is needed.

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

Once a release tag publishes, `scripts/sync-dev-after-release.sh` backports the release-bookkeeping files from `main` to
`dev` so future feature branches inherit the correct baseline. Two files move: `VERSION` (overwritten with the released
number) and `CHANGELOG.md` (copied verbatim from `origin/main`, which is authoritative for the changelog).

Without the backport, `dev` keeps the pre-release `VERSION` indefinitely (the release bump lives only on the `release/*`
branch that was squash-merged to `main` and never touched `dev`). Feature branches cut from `dev` then carry a stale
baseline — confusing during review, and load-bearing in two places: (a) `bin/check-update` compares the caller's local
`VERSION` against the producer repo's `main`, so a stale local `VERSION` from a `dev` clone would falsely report
`UPGRADE_AVAILABLE` on a current main; (b) the `chore(spec)` re-vendor commit message references the current bundle
version.

The backport opens a PR against `dev` (`chore/sync-dev-after-vX.Y.Z`); it does **not** commit directly to `dev`. The
PR-only norm on `dev` documented in [`RELEASES.md`](./RELEASES.md) applies here as it applies to everything else. The
diff is mechanical (just `VERSION` + `CHANGELOG.md` copied from main), so reviewers can spot-check and squash-merge as
usual; the script's idempotency also makes the work safe to re-run if a maintainer pulls before merging the sync PR.

The script is idempotent: it exits 0 without creating a branch or PR when `VERSION` and `CHANGELOG.md` already match
`main`. Safe to re-run, safe to invoke from automation that doesn't track whether the last release was already
backported.

Mirror of `~/dev/agentnative-cli/scripts/sync-dev-after-release.sh`. The cli variant additionally regenerates
`Cargo.lock` via `cargo build --release` after surgically updating `Cargo.toml`'s `[package].version`; the skill bundle
is markdown-only and ships no lock file, so those steps drop.

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

For a `CHANGELOG.md` finding, fix the upstream PR body (which `generate-changelog.sh` re-fetches every run) and
regenerate. Hand-editing `CHANGELOG.md` directly produces drift the next regeneration overwrites.

## Branch protection

### Why three rulesets

This repo ships three rulesets (`protect-main.json`, `protect-dev.json`, `protect-tags.json`) where peer repos ship two.
The third (`protect-tags.json`) treats `v*` tags as immutable historical anchors for released versions: deletion,
force-push (re-tag), and updates are all blocked. The bundle's `bin/check-update` and the `git clone --depth 1` install
path both rely on `main` and on tag identity; a re-tagged release would lie to consumers about what they're installing.

### Why the apply step is re-runnable

The three rulesets ship in `.github/rulesets/` and are applied via the GitHub API. The apply commands in RELEASES.md are
deliberately idempotent so they survive: (a) the original public-flip from the bootstrap window when the repo was
private (GitHub's free tier does not allow rulesets on private repos, so rulesets could not be applied until visibility
flipped); (b) any future ruleset reset; (c) the same procedure being copied into a new repo's bootstrap.

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

## Related docs

- [`RELEASES.md`](./RELEASES.md) (operational runbook: commands, paths, decision tables)
- [`AGENTS.md`](./AGENTS.md) (repo layout, lint commands, what agents must not do)
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) (how to propose changes)
- [`.github/pull_request_template.md`](.github/pull_request_template.md) (PR body structure with changelog sections)
- [`.github/rulesets/README.md`](.github/rulesets/README.md) (ruleset apply + verify procedure)
- [`CHANGELOG.md`](./CHANGELOG.md) (released versions and their notes)
