# Pre-release verification: `agentnative-skill`

Operational pre-flight checklist. Runs **before** step 1 of
[`RELEASES.md` § Releasing dev to main](./RELEASES.md#releasing-dev-to-main). Gates the cut of the `release/v<version>`
branch, not the daily dev integration. Each box is an explicit go/no-go. If any item is unchecked or red, hold the
release.

CI (markdownlint, shellcheck, `guard-docs / check-forbidden-docs`) catches mechanical regressions inside this repo. This
checklist covers what CI structurally can't:

- Changes on `main` that `dev` never received, which the release would silently revert.
- Breaking changes to the bundle's contract (`SKILL.md` frontmatter fields, directory layout, vendored `spec/` shape)
  that downstream consumers must adapt to.
- Real-world behavior against external systems CI only mocks (`git clone --depth 1` to a live host destination).
- Distribution paths that only exercise on real artifacts (the bundle is markdown-only, so the "artifact" is the
  contents of `main` at the tag, but the install path still needs a probe).
- Cross-repo sequencing where releasing here before `agentnative-spec` is re-vendored or before `agentnative-site`
  recognizes the new bundle content breaks downstreams.

Post-tag verification lives in [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md). The tag push happens AFTER the
release-branch cut and the PR-to-main merge, so verification of what the tag publishes is post-flight, not pre-flight.

## Quick start: the automated gate

The bundle has no build, test, or deploy surface, so this repo does not vendor the skill's `preflight.sh` orchestrator;
the items below run by hand. One gate is scripted:

```bash
scripts/release/drift.sh          # exits 1 while main holds anything dev never received
```

Run it first. Nothing else matters while `main` holds changes `dev` never received.

## Establish the surface

Everything below assumes you know what's changing. Run this first.

```bash
LAST_TAG=$(git tag --sort=-version:refname | head -n 1)
git log "$LAST_TAG..dev" --oneline                              # commits going out
git diff "$LAST_TAG..dev" --stat                                # file-level scope
git diff "$LAST_TAG..dev" -- SKILL.md spec/ references/ templates/   # bundle-contract surface
git log "$LAST_TAG..dev" --grep '^[a-z]\+\(([^)]*)\)\?!:' --oneline   # Conventional-Commits breaking markers, scoped or not
```

Because every release squash-merges into `main`, no tag is an ancestor of `dev`; `$LAST_TAG..dev` therefore lists
`dev`'s whole lineage since the merge-base rather than only the commits since the last release. Read the surface as
`origin/main..origin/dev` when that list is too long to be useful, and skip the tag-based counts on a repo with no
tags yet.

Every `!:` commit drives the major-version decision and gets a row in the release's `### Breaking changes` section.

## Checklist

### Branch drift (main ahead of dev)

Driven by `scripts/release/drift.sh`.

Security PRs, hotfixes, and config edits land on `main` first. The release branch is cut from `main` and then takes
`dev`'s tree, so anything `main` holds that `dev` never received is reverted by the release or collides with it, and
Dependabot raises the same fix again.

- [ ] The previous release's bookkeeping (`VERSION`, `CHANGELOG.md`) is on `dev`. Gate 0 fails when it never reached
      `dev`; run `scripts/sync-dev-after-release.sh v<version>`, merge its PR, and rerun.
- [ ] Every commit on `main` since the last release has its changes on `dev` (gate 1 lists the ones that do not, as
      `differs` or `missing`). Backport them by PR into `dev` first, merge, and rerun.
- [ ] `.github/` is identical on both branches (gate 2). A difference either way is a config change that only reached
      one branch. Rows where `dev` is ahead are the config this release ships; rows where `main` is ahead need a
      backport first.
- [ ] Gate 3 (lockfiles) reports SKIP. The bundle carries no `package-lock.json`, `bun.lock`, or `Cargo.lock`; anything
      else here means a manifest landed that this checklist does not know about.

### Cross-repo blast radius

- [ ] **Contract diff.** Diff every consumer-facing contract between `$LAST_TAG` and `dev`: `SKILL.md` frontmatter
  fields, the layout under `spec/` / `references/` / `templates/`, and any path consumers reference by absolute name.
  Every field renamed / added / removed / shape-changed becomes a row in the release's `### Breaking changes` (consumers
  feature-detect from this list).
- [ ] **Spec vendor in lockstep.** `agentnative-spec`'s latest tag matches what `scripts/sync-spec.sh` last vendored
  under `spec/`. If a new spec tag has shipped upstream since the last re-vendor, the release branch's step 4
  (`scripts/sync-spec.sh`) will catch it; confirm here that you intend to ship the re-vendor in this release. See
  [`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline).
- [ ] **Vendored `spec/VERSION` matches the source tag.** `cat spec/VERSION` against the latest `agentnative-spec` tag;
  mismatched values mean the bundle ships stale spec content while consumers see the new version via `bin/check-update`
  (and any field that surfaces `spec_version` in downstream artifacts will lie).
- [ ] **Downstream consumer (`agentnative-site`) ready** to render the new bundle content / `schema_version` if either
  has changed. If the site is not ready, hold the tag.
- [ ] **Install-path destination exists.** The `git clone --depth 1` install URL
  (`https://github.com/brettdavies/agentnative-skill`) resolves and `main` is the default branch (this is what
  `bin/check-update` reads; see
  [`RELEASES-RATIONALE.md` § `bin/check-update` semantics](./RELEASES-RATIONALE.md#bincheck-update-semantics)).

### Real-world smoke

CI exercises one shape; manual probes cover the rest. Pick fresh targets each release.

- [ ] **`anc skill install <host>` for each host slug** the upstream CLI knows about, against a clean per-host
  destination directory. Confirms the hardened `git clone` reaches the live bundle repo at this release's tag and every
  host slug resolves to an existing destination. (Host routing lives in `agentnative-cli`'s
  `src/skill_install/skill.json`; if a new host has been added upstream since the last release, exercise it here.)
- [ ] **Bundle load probe.** After `anc skill install <host>`, the host can load `SKILL.md` without error and any
  cross-references (relative links into `spec/`, `references/`, `templates/`) resolve.
- [ ] **Regression markers.** Any bug fixed in this release: re-run the failing scenario against the freshly cloned
  bundle. Confirms the fix lands at the release tag, not just on `dev`.

### Distribution and install paths

The bundle is markdown-only: no compiled artifact, no package-manager publication. The "distribution" surface is `main`
at the tag plus the install command that lands it.

- [ ] **Bundle install probe.** `git clone --depth 1 https://github.com/brettdavies/agentnative-skill <tmp>` from a
  fresh directory. Confirms the install lands the expected files (`SKILL.md`, `spec/`, `references/`, `templates/`,
  `bin/check-update`, `VERSION`) at the expected paths and that the on-disk `VERSION` matches the new tag.
- [ ] **`bin/check-update` against the new `main`.** From a clone whose `VERSION` matches the prior release, run
  `bin/check-update` and confirm it prints `UPGRADE_AVAILABLE <old> <new>`. The remote URL is hard-coded to
  `raw.githubusercontent.com/.../main/VERSION`; confirm that URL serves the new value (GitHub Raw can lag the push by
  ~minutes for first-time renders).

### Release mechanics sanity

These items duplicate steps in `RELEASES.md` deliberately: easy to skip, expensive to recover from. Confirm explicitly
against the release branch after step 5 of the overlay recipe.

- [ ] **`VERSION` bumped** on the release branch to the new tag value (plain-text `X.Y.Z`, no leading `v`). This is what
  `bin/check-update` reports on consumer machines; a mis-bump silently breaks update detection. See
  [`RELEASES-RATIONALE.md` § `bin/check-update` semantics](./RELEASES-RATIONALE.md#bincheck-update-semantics).
- [ ] **Every merged PR since `$LAST_TAG` has a non-empty `## Changelog` section.** A PR without one falls back to its
  title as a `Changed` bullet, or drops out entirely when its title is typed `chore`/`ci`/`build`/`style`/`test`.
  Spot-check via:

  ```bash
  gh pr list --base dev --state merged \
    --search "merged:>$(git log -1 --format=%aI $LAST_TAG)"
  # Then for each PR:
  gh pr view <num> --json body
  ```

  See [`RELEASES-RATIONALE.md` § CHANGELOG generation](./RELEASES-RATIONALE.md#changelog-generation).

- [ ] **`CHANGELOG.md` versioned section** has no `[Unreleased]` placeholder and matches the bumped version
  (`scripts/generate-changelog.py --check`).
- [ ] **Leak check.** No guarded path may surface in the diff vs `origin/main`. The set resolves from
  `.github/workflows/guard-main-docs.yml` via `scripts/release/guarded-paths.sh`; never restate the pattern inline.

  ```bash
  GUARDED="$(scripts/release/guarded-paths.sh)"
  git diff origin/main..HEAD --name-only | grep -E "$GUARDED" && echo "LEAKED: reset and redo" || echo "(clean)"
  ```

  `guard-main-docs.yml` enforces this on the release PR, but catching it here avoids a wasted CI cycle.

- [ ] **Every doc this release adds to `main` is meant to ship.** The leak check is blind to a category nobody
  registered. `git diff origin/main..HEAD --diff-filter=A --name-only | grep -E '(^docs/|\.md$)' | grep -Ev "$GUARDED"`
  lists the unguarded additions; each one needs a reason to ship, or it gets registered in the workflow's
  `extra_paths` and removed from the branch.
- [ ] **Diff-B is quiet.** `git diff HEAD..origin/dev --name-only | grep -Ev "$GUARDED"` prints only `VERSION`,
  `CHANGELOG.md`, and any `spec/` rows from a re-vendor. Filter by the guarded set, not all of `docs/`: `docs/SYNCS.md`
  ships to `main`, and a blanket `docs/` filter would hide a missed change there.
- [ ] **Prose scrub.** `CHANGELOG.md` and the release-PR body pass Vale + LanguageTool + `unslop`. See
  [`RELEASES.md` § Prose scrubbing](./RELEASES.md#prose-scrubbing).
- [ ] **Local hooks ran.** `scripts/hooks/pre-push` mirrors CI (markdownlint + shellcheck); run it explicitly before
  pushing the release branch.

### Post-tag verification

Moved to [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md) because tagging happens **after** the release-branch cut
and PR-to-main merge, so verification of the published tag (GitHub Release, live `bin/check-update`, backport, consumer
submodule pins) is post-flight, not pre-flight.

## Related docs

- [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md): runs AFTER the tag push to verify what it published.
- [`RELEASES.md`](./RELEASES.md): operational runbook this checklist gates.
- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md): release-flow rationale (branching model, CHANGELOG pipeline,
  spec-vendor pipeline, `bin/check-update` semantics, branch-protection pitfalls).
