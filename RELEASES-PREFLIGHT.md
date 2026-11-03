<!-- Canonical version: 2026.11.03 (generic) -->
# Pre-release verification: `agentnative-skill`

Operational pre-flight checklist. Walk it before step 1 of
[`RELEASES.md` § Releasing dev to main](./RELEASES.md#releasing-dev-to-main), the cut: it gates the `release/v<version>`
branch, not the daily dev integration. The automated gates (`scripts/release/preflight.sh all`) run at step 3, against
the committed release branch, because the mechanics checks read the bumped version and the release tree; the cut runs
the drift gate itself before it branches. Each box is an explicit go/no-go. If any item is unchecked or red, hold the
release.

CI (markdownlint, shellcheck, `guard-docs / check-forbidden-docs`) catches mechanical regressions inside the repo. This
checklist covers what CI structurally can't:

- Changes on `main` that `dev` never received, which the release would silently revert.
- Breaking changes to the bundle's contract ([`RELEASES.md` § What the contract is](./RELEASES.md#what-the-contract-is))
  that downstream consumers must adapt to.
- Behavior against live external systems: the `git clone --depth 1` install path, `bin/check-update` against `main`'s
  `VERSION`, and the spec repository `spec/` is vendored from.
- Cross-repo sequencing, where releasing here before `agentnative-spec` is re-vendored or before `agentnative-site`
  recognizes the new bundle content breaks downstreams.

Post-tag verification (the tag, the GitHub Release, the `dev` backport) lives in
[`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md). The tag push happens AFTER the release-branch cut and the
PR-to-main merge, so verification of what the tag publishes is post-flight, not pre-flight.

## Quick start: run the automated gates

Most of this checklist can run from one script. The bundle has no build step, so nothing needs building first:

```bash
scripts/release/preflight.sh all
```

The preflight script (`scripts/release/preflight.sh`) is **project-authored**: each repo owns its own gate
implementations because the surface and smoke fixtures vary per project. It starts from the github-repo-setup skeleton,
which carries the shared scaffolding (gate helpers, `shred -u` tempdir cleanup, subcommand dispatch, and the drift,
surface, changelog-sections, semver, and mechanics gates); this repo's `gate_smoke` body drives the live install path,
`bin/check-update`, and the spec source. `all` runs the drift gate first, since nothing else matters while `main` holds
changes `dev` never received. The recipes in the sections below document what each gate verifies and serve as the manual
fallback when running by hand.

Sub-commands let you re-run one section in isolation:

| Sub-command          | What it checks                                                                                                                                     | Source of truth                                           |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `drift`              | Commits on `main` since the last release whose changes `dev` lacks, `.github/` parity, lockfile packages `main` resolves newer                     | `scripts/release/drift.sh`                                |
| `surface`            | Commits since the last release reached `dev`, files changed since the last tag, breaking markers                                                   | `git log`, `git diff`                                     |
| `smoke`              | `main` is the default branch, a `git clone --depth 1` lands the bundle, `bin/check-update` flags a stale install, `spec/VERSION` is the newest tag | `gh`, `git clone`, `bin/check-update`, the spec repo tags |
| `mechanics`          | `VERSION` and `CHANGELOG.md` agree, no `[Unreleased]`, leak check, unguarded docs added to `main`, diff-B vs `origin/dev`                          | `VERSION`, `CHANGELOG.md`, `guarded-paths.sh`             |
| `changelog-sections` | No PR this release carries leaves its changelog entry to its title for want of a section                                                           | `generate-changelog.py`, `gh`                             |
| `semver`             | Skips: the bundle has no `Cargo.toml`                                                                                                              | `cargo semver-checks`                                     |
| `all`                | Every above sequentially, drift first                                                                                                              |                                                           |

Flags:

- `--smoke-home PATH`: reuse an existing `$SMOKE_HOME` instead of creating one
- `--no-cleanup`: keep `$SMOKE_HOME` after exit (default: shred on exit)
- `--tag TAG`: override `LAST_TAG` resolution (default: the newest `v[0-9]*` tag)

The bundle ships no deployed HTTP / MCP / API surface, so it vendors no `surface-smoke.sh`.

After `git push origin vX.Y.Z`, run [`scripts/release/postflight.sh all`](./RELEASES-POSTFLIGHT.md) to verify the
publish.

## Establish the surface

Everything below assumes you know what's changing. Run this first.

Driven by `scripts/release/preflight.sh surface`.

```bash
LAST_TAG=$(git tag --list 'v[0-9]*' --sort=-version:refname | head -n 1)
# The commit that synced the tag back into dev opens dev's window.
SINCE=$(git log origin/dev --format='%H %s' \
  | grep -E -m1 "^[0-9a-f]+ chore\(release\): (sync dev after|backport) ${LAST_TAG//./\\.}( |$)" | cut -d' ' -f1)
git log "$SINCE..origin/dev" --oneline                          # commits going out
git diff "$LAST_TAG" origin/dev --name-only \
  | grep -Ev "$(scripts/release/guarded-paths.sh)"              # file-level scope: what ships
git diff "$LAST_TAG" origin/dev -- SKILL.md spec/ references/ templates/   # bundle-contract surface
git log "$SINCE..origin/dev" --grep '^[a-z]\+\(([^)]*)\)\?!:' --oneline   # Conventional-Commits breaking markers, scoped or not
```

Every release squash-merges into `main`, so the tag shares no recent history with `dev`, and a log from the tag counts
`dev`'s whole past. The window opens at the commit that synced the tag back into `dev`, whose subject reads
`chore(release): sync dev after vX.Y.Z` (or `chore(release): backport vX.Y.Z ...` for older releases). The file list
compares trees, so it reads from the tag directly, minus the guarded set `dev` carries but never ships. With no tags
yet, or no commit syncing the tag back, `preflight.sh surface` SKIPs, and the surface is `origin/main..origin/dev`.

The previous release branch took `dev` before that sync commit merged, so a PR that merged between the cut and the sync
went out in neither release, and the log above does not show it. `generate-changelog.py` reads it: it also reads the PRs
between the sync commit before that one and this one, and leaves out every PR `CHANGELOG.md` already lists. When this
sync commit is the first, it reads the PRs after the newest one the previous section cites instead, and a previous
section that cites no PR, such as hand-written notes, carries nothing over. The generated section is the complete list,
and a breaking PR merged in that gap appears in its `### Breaking changes` rather than in the tally. No section cites a
PR the previous release left out of its notes on purpose either, so it comes back in this section; leave it out the same
way.

A `!:` commit is a cross-check hint only: the PRs' changelog sections set the bump
([`RELEASES.md` § Versioning](./RELEASES.md#versioning)). A `!:` commit whose PR filed no `### Breaking changes` bullet
is a question for its author, not a major on its own.

## Checklist

### Branch drift (main ahead of dev)

Driven by `scripts/release/preflight.sh drift` (delegates to `scripts/release/drift.sh`).

Security PRs, hotfixes, and config edits land on `main` first. The release branch is cut from `main` and then takes
`dev`'s changes, so anything `main` holds that `dev` never received is reverted by the release or collides with it, and
Dependabot raises the same fix again.

<!-- canonical:begin drift-gate -->

- [ ] The previous release's own bookkeeping reached `dev` (gate 0).

  Gate 0 checks the version carriers and `CHANGELOG.md` as the release left them. It fails when a backport never ran;
  run `scripts/sync-dev-after-release.sh v<previous>`, merge its PR, and rerun.

- [ ] Every commit on `main` since the last release has its changes on `dev` (gate 1).

  Gate 1 lists each commit that does not, as `differs` or `missing`. Backport them by PR into `dev` first, merge, and
  rerun.

- [ ] Nothing under `.github/` on `main` is missing from `dev` (gate 2).

  `.github/` reaches `main` through the release, so config that has reached `dev` and not `main` is what this release
  delivers, and the gate counts it. The gate fails on the other direction, where `main` holds workflow or ruleset
  config `dev` never received, and names each path as `missing` or `differs`.

- [ ] No lockfile package resolves newer on `main` than on `dev` (gate 3).

  Gate 3 reads `package-lock.json`, `bun.lock`, and `Cargo.lock`. The one benign case is a version still inside the
  local package manager's release-age window when the advisory is already patched at `dev`'s version.

- [ ] `dev`-newer packages are the routine updates this release ships; the gate counts them and does not list them.

<!-- canonical:end drift-gate -->

In this repo gate 3 reports SKIP: the bundle carries no `package-lock.json`, `bun.lock`, or `Cargo.lock`, so anything
else there means a manifest landed that this checklist does not know about.

### Bundle contract

The bundle's contract is the list in [`RELEASES.md` § What the contract is](./RELEASES.md#what-the-contract-is). Confirm
it against the previous release before tagging.

- [ ] **Contract diff.** Diff every surface that list names between `$LAST_TAG` and `dev`. Every surface removed,
  renamed, or retyped, or whose meaning changed, has a `### Breaking changes` bullet in the release changelog (a
  removal's starts with "Remove"), and every new one an `### Added` bullet; consumers feature-detect from these lists.
- [ ] **Downstream consumer (`agentnative-site`) ready** to render the new bundle content / `schema_version` if either
  has changed. If the site is not ready, hold the tag.

### Real-world smoke (live install path and sources)

Driven by `scripts/release/preflight.sh smoke`. The gate body covers the first four items; the rest are manual.

The bundle has no test suite, and CI lints only. Exercises that only fire end-to-end against GitHub belong here.

- [ ] **Install-path destination exists.** `main` is the default branch of `brettdavies/agentnative-skill`, the branch
  `bin/check-update` reads (see
  [`RELEASES-RATIONALE.md` § `bin/check-update` semantics](./RELEASES-RATIONALE.md#bincheck-update-semantics)).
- [ ] **Bundle install probe.** `git clone --depth 1 https://github.com/brettdavies/agentnative-skill` lands `SKILL.md`,
  `getting-started.md`, `VERSION`, `spec/`, `references/`, `templates/`, and an executable `bin/check-update`, and no
  `docs/plans/` (guarded off `main`).
- [ ] **Negative control: `bin/check-update` flags a stale install.** With a local `VERSION` of `0.0.0` it prints
  `UPGRADE_AVAILABLE 0.0.0 <main's VERSION>`, and with `main`'s own `VERSION` it prints nothing. A check that only ever
  ran on an up-to-date install would pass identically if the comparison had stopped working.
- [ ] **Spec vendor in lockstep.** `spec/VERSION` matches the newest `agentnative-spec` `v*` tag. On `dev` a mismatch
  SKIPs: it is the re-vendor step 2 of the release makes. On a release branch it FAILs. Confirm here that you intend to
  ship the re-vendor in this release; see
  [`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline).
- [ ] **`anc skill install <host>` for each host slug** the upstream CLI knows about, against a clean per-host
  destination directory. Confirms the hardened `git clone` reaches the live bundle repo and every host slug resolves to
  an existing destination. (Host routing lives in `agentnative-cli`'s `src/skill_install/skill.json`; if a new host has
  been added upstream since the last release, exercise it here.)
- [ ] **Bundle load probe.** After `anc skill install <host>`, the host can load `SKILL.md` without error and any
  cross-references (relative links into `spec/`, `references/`, `templates/`) resolve.
- [ ] **Regression markers.** Any bug fixed in this release: re-run the failing scenario against the freshly cloned
  bundle. Confirms the fix lands at the release tag, not just on `dev`.

### Release mechanics sanity

Driven by `scripts/release/preflight.sh mechanics`.

These items duplicate steps in `RELEASES.md` deliberately: easy to skip, expensive to recover from. Confirm explicitly.

- [ ] `VERSION` bumped to the new tag value (plain-text `X.Y.Z`, no leading `v`). This is what `bin/check-update`
  reports on consumer machines; a mis-bump silently breaks update detection.
- [ ] No PR this release carries leaves its changelog entry to its title. Swept, not sampled, by
  `scripts/release/preflight.sh changelog-sections`, which runs `generate-changelog.py --audit-sections`. It reads the
  PRs from `dev`'s history since the previous release, stacked PRs included, and names every one that never offered the
  `## Changelog` section under a title the fallback would print. A section left empty on purpose passes.
- [ ] `scripts/release/cut-release-branch.sh` exited 0, so its check A held: the staged tree equals `origin/dev`'s apart
  from the version carriers and the guarded paths. A spec re-vendor in step 2 adds `spec/` rows after that check; review
  them before committing. A cherry-pick release runs the triple diff in `RELEASES.md` § Exception: cherry-pick instead,
  with `HEAD..origin/dev` filtered by the guarded set (not all of `docs/`, since `docs/SYNCS.md` ships to `main` and a
  blanket filter would hide a missed pick there).
- [ ] **Leak check before pushing the release branch.** No guarded path may be added or modified in the diff vs
  `origin/main`. The cut's check B screens the staged tree, and `preflight.sh mechanics` screens the committed branch;
  both resolve the set from `.github/workflows/guard-main-docs.yml` via `scripts/release/guarded-paths.sh`, so never
  restate the pattern inline. `--diff-filter=ACMR`, because a release that removes a guarded doc `main` still carries
  lists the removal too, and that is cleanup, not a leak. Run on `dev` itself, the gate fails by design: `dev` carries
  the guarded docs the cut strips.

  ```bash
  GUARDED="$(scripts/release/guarded-paths.sh)"
  git diff origin/main..HEAD --diff-filter=ACMR --name-only | grep -E "$GUARDED" && echo "LEAKED: reset and redo" || echo "(clean)"
  ```

- [ ] **Every doc this release adds to `main` is meant to ship.** The leak check is blind to a category nobody
  registered. The cut's check D and `preflight.sh mechanics` list the unguarded additions, as does the command below;
  each one needs a reason to ship, or it gets registered in the workflow's `extra_paths` and removed from the branch.
  `--no-renames` lists a doc moved from one `main` carries as added, where rename detection would report it as a rename
  and the `A` filter would drop it.

  ```bash
  git diff --no-renames origin/main..HEAD --diff-filter=A --name-only | grep -E '(^docs/|\.md$)' | grep -Ev "$GUARDED"
  ```

- [ ] `CHANGELOG.md` versioned section has no `[Unreleased]` placeholder and matches the bumped version.
- [ ] **The version is the one the changelog sections call for.** `scripts/release/cut-release-branch.sh` prints the
  version `scripts/generate-changelog.py --bump` computes beside the one it was given
  ([`RELEASES.md` § Versioning](./RELEASES.md#versioning)); a difference is the maintainer's call, made before the
  release commit.
- [ ] **A 1.0+ release that keeps its major ships a migration guide for its breaking changes.**
  `scripts/release/preflight.sh mechanics` fails a release whose changelog carries `### Breaking changes` when it keeps
  the previous tag's major and has no `docs/migrating/v<version>.md` opening with a line that names the small-break
  exception. A 0.x release needs no guide.
- [ ] **Prose scrub.** `CHANGELOG.md` and the release-PR body pass Vale + LanguageTool + `unslop`. See
  [`RELEASES.md` § Prose scrubbing](./RELEASES.md#prose-scrubbing).
- [ ] **Local hooks ran.** `scripts/hooks/pre-push` mirrors CI (markdownlint, shellcheck, actionlint); run it explicitly
  before pushing the release branch.

### Post-tag verification

Moved to [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md) because tagging happens **after** the release-branch cut
and PR-to-main merge, so verification of the published tag (GitHub Release, live `bin/check-update`, backport, consumer
submodule pins) is post-flight, not pre-flight. Run `scripts/release/postflight.sh all` immediately after
`git push origin vX.Y.Z`.

## Related docs

- [`RELEASES-POSTFLIGHT.md`](./RELEASES-POSTFLIGHT.md). Runs AFTER the tag push to verify the publish.
- [`RELEASES.md`](./RELEASES.md). Operational runbook this checklist gates.
- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md). Release-flow rationale.
- [`AGENTS.md`](./AGENTS.md). Repo layout, lint commands, what agents must not do.
