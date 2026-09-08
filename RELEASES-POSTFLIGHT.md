# Post-release verification: `agentnative-skill`

Operational post-flight checklist. Runs **after** the `release/v<version> → main` PR merges and you push the tag and
create the GitHub Release per [`RELEASES.md` § Tagging and publishing](./RELEASES.md#tagging-and-publishing). Verifies
that what the tag published is what consumers will install, and that the bookkeeping the release leaves behind
(backport to `dev`, consumer pins, downstream manifests) actually moved.

Companion to [`RELEASES-PREFLIGHT.md`](./RELEASES-PREFLIGHT.md), which gates the release-branch cut. Both docs follow
the same go/no-go shape: every box is explicit, an unchecked or red item holds the next release (or motivates a patch
release).

## Quick start

There is no tag-triggered pipeline in this repo: no `release.yml`, no registry publish, no Homebrew dispatch, no
`finalize-release` callback. The skill's `postflight.sh` orchestrator would have nothing to drive, so it is not
vendored and every item below runs by hand. One command covers the backport:

```bash
scripts/sync-dev-after-release.sh v<version>    # opens the chore/sync-dev-after-v<version> PR against dev
```

## Checklist

Run immediately after `gh release create`.

- [ ] **Tag is annotated and sits on `main`.** `git cat-file -t v<version>` prints `tag`, and
  `git merge-base --is-ancestor v<version> origin/main` exits 0. A lightweight tag or a tag on the deleted release
  branch means the GitHub Release points at the wrong commit.
- [ ] **GitHub Release is published and latest.** `gh release view v<version> --json isDraft,isPrerelease` shows both
  `false`, and `gh api repos/brettdavies/agentnative-skill/releases/latest --jq .tag_name` returns `v<version>`, not
  the previous tag. The notes are the `CHANGELOG.md` section for this version, extracted by version, not by position.
- [ ] **Fresh-clone install lands the tag's content.** From an empty directory,
  `git clone --depth 1 https://github.com/brettdavies/agentnative-skill <tmp>`; `cat <tmp>/VERSION` prints `<version>`
  and the expected files (`SKILL.md`, `spec/`, `references/`, `templates/`, `bin/check-update`) are present at the
  expected paths. Drive it from a throwaway directory, not an existing install.
- [ ] **Live `bin/check-update` sanity probe.** From a clone at the prior release's `VERSION`, run `bin/check-update`
  against the live remote URL. Must print `UPGRADE_AVAILABLE <old> <new>`. First-time renders on
  `raw.githubusercontent.com` can lag the push by minutes; re-probe rather than hold.
- [ ] **Last-good identifier recorded.** Note the previous tag (`git tag --sort=-version:refname | sed -n 2p`) and its
  commit somewhere reachable under incident pressure. A consumer that needs the last-good bundle before a patch ships
  pins its checkout to that tag; see [`RELEASES.md` § Rollback](./RELEASES.md#rollback).
- [ ] **Rollback path confirmed.** If this release is bad, the fix is a forward patch release through the normal `dev`
  to `release/*` to `main` flow, never a deleted or moved tag. Confirm `protect-tags.json` still reports as installed
  (`gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[] | select(.target == "tag") | .name'`).
- [ ] **Backport `main` → `dev`** via a **merged PR to `dev` with the version in its title.**
  `scripts/sync-dev-after-release.sh v<version>` writes `VERSION` and copies `CHANGELOG.md` from `main`, cuts
  `chore/sync-dev-after-v<version>`, and opens the PR; merge it once CI is green. Verify with
  `gh pr list --base dev --state merged --search "v<version> in:title"`. Never merge `main` into `dev` or push to `dev`
  directly. Keeps the next release's diff-B quiet so a real missed change stands out instead of hiding in expected
  divergence noise.
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
