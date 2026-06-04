# Pre-release verification: `agentnative-skill`

Operational pre-flight checklist. Runs **before** step 1 of
[`RELEASES.md` § Releasing dev to main](./RELEASES.md#releasing-dev-to-main). Gates the cut of the `release/v<version>`
branch, not the daily dev integration. Each box is an explicit go/no-go. If any item is unchecked or red, hold the
release.

CI (markdownlint, shellcheck, `guard-docs / check-forbidden-docs`) catches mechanical regressions inside this repo. This
checklist covers what CI structurally can't:

- Breaking changes to the bundle's contract (`SKILL.md` frontmatter fields, directory layout, vendored `spec/` shape)
  that downstream consumers must adapt to.
- Real-world behavior against external systems CI only mocks (`git clone --depth 1` to a live host destination).
- Distribution paths that only exercise on real artifacts (the bundle is markdown-only, so the "artifact" is the
  contents of `main` at the tag — but the install path still needs a probe).
- Cross-repo sequencing where releasing here before `agentnative-spec` is re-vendored or before `agentnative-site`
  recognizes the new bundle content breaks downstreams.

## Establish the surface

Everything below assumes you know what's changing. Run this first.

```bash
LAST_TAG=$(git tag --sort=-version:refname | head -n 1)
git log "$LAST_TAG..dev" --oneline                              # commits going out
git diff "$LAST_TAG..dev" --stat                                # file-level scope
git diff "$LAST_TAG..dev" -- SKILL.md spec/ references/ templates/   # bundle-contract surface
git log "$LAST_TAG..dev" --grep '^[a-z]\+!:' --oneline          # Conventional-Commits breaking markers
```

Every `!:` commit drives the major-version decision and gets a row in the release's `### Breaking changes` section.

## Checklist

### Cross-repo blast radius

- [ ] **Contract diff.** Diff every consumer-facing contract between `$LAST_TAG` and `dev`: `SKILL.md` frontmatter
  fields, the layout under `spec/` / `references/` / `templates/`, and any path consumers reference by absolute name.
  Every field renamed / added / removed / shape-changed becomes a row in the release's `### Breaking changes` (consumers
  feature-detect from this list).
- [ ] **Spec vendor in lockstep.** `agentnative-spec`'s latest tag matches what `scripts/sync-spec.sh` last vendored
  under `spec/`. If a new spec tag has shipped upstream since the last re-vendor, the release branch's step 6
  (`scripts/sync-spec.sh`) will catch it — but confirm here that you intend to ship the re-vendor in this release. See
  [`RELEASES-RATIONALE.md` § Spec-vendor pipeline](./RELEASES-RATIONALE.md#spec-vendor-pipeline).
- [ ] **Vendored `spec/VERSION` matches the source tag.** `cat spec/VERSION` against the latest `agentnative-spec` tag;
  mismatched values mean the bundle ships stale spec content while consumers see the new version via `bin/check-update`
  (and any field that surfaces `spec_version` in downstream artifacts will lie).
- [ ] **Downstream consumer (`agentnative-site`) ready** to render the new bundle content / `schema_version` if either
  has changed. If the site is not ready, hold the tag.
- [ ] **Install-path destination exists.** The `git clone --depth 1` install URL
  (`https://github.com/brettdavies/agentnative-skill`) resolves and `main` is the default branch (this is what
  `bin/check-update` reads — see
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

The bundle is markdown-only — no compiled artifact, no package-manager publication. The "distribution" surface is `main`
at the tag plus the install command that lands it.

- [ ] **Bundle install probe.** `git clone --depth 1 https://github.com/brettdavies/agentnative-skill <tmp>` from a
  fresh directory. Confirms the install lands the expected files (`SKILL.md`, `spec/`, `references/`, `templates/`,
  `bin/check-update`, `VERSION`) at the expected paths and that the on-disk `VERSION` matches the new tag.
- [ ] **`bin/check-update` against the new `main`.** From a clone whose `VERSION` matches the prior release, run
  `bin/check-update` and confirm it prints `UPGRADE_AVAILABLE <old> <new>`. The remote URL is hard-coded to
  `raw.githubusercontent.com/.../main/VERSION` — confirm that URL serves the new value (GitHub Raw can lag the push by
  ~minutes for first-time renders).

### Release mechanics sanity

These items duplicate steps in `RELEASES.md` deliberately: easy to skip, expensive to recover from. Confirm explicitly.

- [ ] **`VERSION` bumped** on the release branch to the new tag value (plain-text `X.Y.Z`, no leading `v`). This is what
  `bin/check-update` reports on consumer machines — a mis-bump silently breaks update detection. See
  [`RELEASES-RATIONALE.md` § `bin/check-update` semantics](./RELEASES-RATIONALE.md#bincheck-update-semantics).
- [ ] **Every merged PR since `$LAST_TAG` has a non-empty `## Changelog` section.** Empty sections silently drop from
  the generated `CHANGELOG.md`. Spot-check via:

  ```bash
  gh pr list --base dev --state merged \
    --search "merged:>$(git log -1 --format=%aI $LAST_TAG)"
  # Then for each PR:
  gh pr view <num> --json body
  ```

  See [`RELEASES-RATIONALE.md` § CHANGELOG generation](./RELEASES-RATIONALE.md#changelog-generation) for why
  `chore`/`style`/`test`/`ci`/`build`-typed commits silently drop their changelog bullets.

- [ ] **Leak check.** Engineering-doc paths and `.context/` aren't reaching the release branch:

  ```bash
  git diff origin/main..HEAD --name-only \
    | grep -E '^(docs/plans|docs/brainstorms|docs/ideation|docs/reviews|docs/solutions|\.context)'
  ```

  Returns nothing. `guard-main-docs.yml` enforces this on the release PR, but catching it here avoids a wasted CI
  cycle.

- [ ] **Prose scrub.** `CHANGELOG.md` and the release-PR body pass Vale + LanguageTool + `unslop`. See
  [`RELEASES.md` § Prose scrubbing](./RELEASES.md#prose-scrubbing).

### Post-tag verification

Run immediately after the tag push.

- [ ] **`release.yml` green end-to-end** (if/when a release workflow exists in this repo). `gh run watch <id>
  --exit-status` then verify with `gh run view <id> --json conclusion`. The watcher exit code alone is not authoritative
  — re-check explicitly.
- [ ] **`finalize-release.yml` ran** (if/when one exists in this repo) and flipped the GitHub Release `make_latest:
  true`. Until that workflow exists, set `make_latest` manually on `gh release create`.
- [ ] **Live `bin/check-update` sanity probe.** From a clone at the prior release's `VERSION`, run `bin/check-update`
  against the live remote URL. Must print `UPGRADE_AVAILABLE <old> <new>`. First-time renders on
  `raw.githubusercontent.com` can lag the push.
- [ ] **Backport.** `./scripts/sync-dev-after-release.sh v<version>` opens the `chore/sync-dev-after-v<version>` PR
  against `dev` per
  [`RELEASES.md` § After publish — sync `dev` with the release](./RELEASES.md#after-publish--sync-dev-with-the-release).

## Related docs

- [`RELEASES.md`](./RELEASES.md): operational runbook this checklist gates.
- [`RELEASES-RATIONALE.md`](./RELEASES-RATIONALE.md): release-flow rationale (branching model, CHANGELOG pipeline,
  spec-vendor pipeline, `bin/check-update` semantics, branch-protection pitfalls).
