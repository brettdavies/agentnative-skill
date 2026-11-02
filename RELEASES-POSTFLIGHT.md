<!-- Canonical version: 2026.10.22 (generic) -->
# Post-release verification: `agentnative-skill`

Operational post-flight checklist. Runs **after** the `release/v<version> → main` PR merges and you push the tag
(`git push origin vX.Y.Z`) and create the GitHub Release per
[`RELEASES.md` § Tagging and publishing](./RELEASES.md#tagging-and-publishing). Verifies that what the tag published is
what consumers will install, and that the bookkeeping the release leaves behind (backport to `dev`, consumer pins,
downstream manifests) actually moved.

Companion to [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md), which gates the release-branch cut. Both docs follow
the same go/no-go shape: every box is explicit, an unchecked or red item holds the next release (or motivates a patch
release).

## Quick start: run the automated gates

```bash
scripts/release/postflight.sh all
```

The script (`scripts/release/postflight.sh`, a verbatim copy of the github-repo-setup orchestrator) covers the
automatable post-tag gates. This repo has no tag-triggered pipeline (no `release.yml`, no registry publish, no Homebrew
dispatch, no `finalize-release` callback), so most of its gates SKIP with a reason, and the ones that carry weight here
are `make-latest` and `backport`. The bundle has a single environment, so `--env` stays at its `prod` default.
Install-on-fresh-machine smokes are documented below but not driven from the script; drive them from a throwaway
directory.

Sub-commands let you re-run one verification in isolation:

| Sub-command     | What it checks                                                                    | In this repo                                |
| --------------- | --------------------------------------------------------------------------------- | ------------------------------------------- |
| `release`       | The tag's `release.yml` run concluded `"success"`                                 | SKIPs: no `release.yml`                     |
| `tap`           | `<owner>/homebrew-tap` `update-formula` + `Publish formula` ran SUCCESS           | SKIPs: no `release.yml` run to match        |
| `finalize`      | `finalize-release.yml` callback ran in this repo                                  | SKIPs: no `release.yml` run to match        |
| `make-latest`   | GitHub Release is non-draft, non-prerelease, and `releases/latest` resolves to it | the GitHub Release `gh release create` made |
| `crates`        | `crates.io` shows the tag's crate at its version                                  | SKIPs: no `Cargo.toml`                      |
| `tags`          | Every workspace member the release moved is tagged on the binary tag's commit     | SKIPs: no `Cargo.toml`                      |
| `backport`      | A merged PR to `dev` with the version in its title                                | the `sync-dev-after-release.sh` PR          |
| `surface-smoke` | Delegates to `scripts/release/surface-smoke.sh` against the env's deployed URL    | not vendored; the gate does not run         |
| `all`           | every above                                                                       |                                             |

Flags:

- `--repo OWNER/REPO`: override the auto-detected nameWithOwner
- `--tag vX.Y.Z`: override auto-detection (default: `v` plus the contents of `VERSION`; falls back to the newest
  `v[0-9]*` tag)

The `backport` gate passes on the newest merged PR to `dev` whose title carries the version, preferring a backport PR.
Read the PR it names: a feature PR whose title happens to carry the same version string also satisfies it, so confirm
the named PR is the `chore/sync-dev-after-v<version>` one.

## Checklist

Run immediately after `gh release create`.

- [ ] **Tag is annotated and sits on `main`.** `git cat-file -t v<version>` prints `tag`, and
  `git merge-base --is-ancestor v<version> origin/main` exits 0. A lightweight tag or a tag on the deleted release
  branch means the GitHub Release points at the wrong commit.
- [ ] **GitHub Release marked latest.** `scripts/release/postflight.sh make-latest`: the Release is non-draft and
  non-prerelease, and `releases/latest` returns `v<version>`, not the previous tag. The notes are the `CHANGELOG.md`
  section for this version, extracted by version, not by position.
- [ ] **Fresh-clone install lands the tag's content.** From an empty directory,
  `git clone --depth 1 https://github.com/brettdavies/agentnative-skill <tmp>`; `cat <tmp>/VERSION` prints `<version>`
  and the expected files (`SKILL.md`, `spec/`, `references/`, `templates/`, `bin/check-update`) are present at the
  expected paths. Drive it from a throwaway directory, not an existing install.
- [ ] **Live `bin/check-update` sanity probe.** From a clone at the prior release's `VERSION`, run `bin/check-update`
  against the live remote URL. Must print `UPGRADE_AVAILABLE <old> <new>`. First-time renders on
  `raw.githubusercontent.com` can lag the push by minutes; re-probe rather than hold. `preflight.sh smoke` drives the
  same check against whatever `main` serves, so rerunning it here confirms the new value.
- [ ] **Last-good identifier recorded.** Before the release goes live, note the previous tag
  (`git tag --list 'v[0-9]*' --sort=-version:refname | sed -n 2p`) and its commit somewhere reachable under incident
  pressure. A consumer that needs the last-good bundle before a patch ships pins its checkout to that tag; see
  [`RELEASES.md` § Rollback](./RELEASES.md#rollback).
- [ ] **Rollback path confirmed.** If this release is bad, the fix is a forward patch release through the normal `dev`
  to `release/*` to `main` flow, never a deleted or moved tag. Confirm `protect-tags.json` still reports as installed
  (`gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[] | select(.target == "tag") | .name'`).
- [ ] **Backport `main` → `dev`** via a **merged PR to `dev` with the version in its title.** Bring the release-only
  changes (`VERSION`, `CHANGELOG.md`, and anything the release branch edited on `main` that never round-tripped to
  `dev`, such as a spec re-vendor) across with `scripts/sync-dev-after-release.sh`, which opens that PR
  ([`RELEASES.md` § After publish](./RELEASES.md#after-publish-sync-dev-with-the-release)). It keeps the next release's
  drift and `diff-B` checks quiet, so a real missed change stands out instead of hiding in expected divergence. Per the
  documented learning at
  `docs/solutions/workflow-issues/post-release-backport-prevents-diff-b-false-positives-2026-05-07.md`.

  ```bash
  scripts/sync-dev-after-release.sh v<X.Y.Z>
  ```

  The gate (`scripts/release/postflight.sh backport`) is signal-agnostic about which files moved: it searches merged PRs
  to `dev` by the tag (the search index tokenizes `v1.2.0` as one word, so a bare `1.2.0` misses it) and accepts either
  spelling in the title. Its SKIP and FAIL name the sync command to run. Never merge `main` into `dev` or push to `dev`
  directly.

- [ ] **Consumer submodule pins bumped.** `brettdavies/agent-skills` (and any other aggregator) has its `agentnative`
  submodule pointing at this tag's commit; `git submodule status agentnative` in the consumer matches
  `git rev-parse v<version>^{commit}` here. Procedure in
  [`RELEASES.md` § After publish: bump consumer submodule pins](./RELEASES.md#after-publish-bump-consumer-submodule-pins).
- [ ] **Downstream chain advanced or deliberately held.** Per [`docs/SYNCS.md`](./docs/SYNCS.md), `agentnative-site`
  updates `src/data/skill.json` (`version`, `source.commit`) to this release, and `agentnative-cli` re-syncs its skill
  fixture from the site. Nothing is automated between the three repos; record the decision to advance or hold.

## Related docs

- [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md): pre-cut go/no-go checklist (runs BEFORE this one).
- [`RELEASES.md`](./RELEASES.md): operational runbook for the full release lifecycle.
- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md): release-flow rationale.
- [`docs/SYNCS.md`](./docs/SYNCS.md): the manual cross-repo propagation chain.
