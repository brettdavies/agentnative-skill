# Contributing to `agentnative-skill`

Thanks for your interest. This repo is the agent-facing skill that pairs with three siblings:

- [`agentnative`](https://github.com/brettdavies/agentnative) (the spec): canonical principle text. Vendored here at
  `spec/`.
- [`agentnative-cli`](https://github.com/brettdavies/agentnative-cli) (`anc`): the canonical compliance checker.
- [`agentnative-site`](https://github.com/brettdavies/agentnative-site) (`anc.dev`): the public site, leaderboard
  renderer, live-scoring loop, and skill-distribution endpoint.

This skill does **not** define principles (the spec does) and does **not** check compliance (`anc` does). It teaches
agents how to use them and supplies surrounding context (idioms, templates, getting-started). Route contributions
accordingly. For cross-repo visitor-facing navigation, see [`anc.dev/contribute`](https://anc.dev/contribute).

## Contribution tiers

The skill bundle accepts three shapes of contribution. All three are welcome; none is required. Skill work skews toward
Tier 3 because most improvements are concrete bundle changes; Tier 2 proposals matter when the change spans bundle
structure or host-runtime support.

| Tier            | Shape                                                                                                                                     | Intake                                                                                                                                                                                                              | Effort   |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| **1. Signal**   | Bundle content issue, install path bug, host-runtime detection failure, instructional content critique                                    | [`bug-report`](https://github.com/brettdavies/agentnative-skill/issues/new?template=bug-report.yml) / [`bundle-proposal`](https://github.com/brettdavies/agentnative-skill/issues/new?template=bundle-proposal.yml) | ~5 min   |
| **2. Proposal** | A new host runtime to support in `anc skill install`, bundle reorganization, instructional content rework                                 | Issue with the design before opening a PR                                                                                                                                                                           | ~1-2 hrs |
| **3. Code**     | Bundle content improvements, host-runtime additions, `bin/check-update` work, `SKILL.md` / `getting-started.md` prose, template additions | PR against `dev` (branch model below)                                                                                                                                                                               | Variable |

For principle-level discussion (the spec's MUST/SHOULD/MAY tiers, including P8 on discoverability), file a
`pressure-test` issue in the
[spec repo](https://github.com/brettdavies/agentnative/issues/new?template=pressure-test.yml). For scoring engine or
`anc check` work, file in the [CLI repo](https://github.com/brettdavies/agentnative-cli). Those discussions don't belong
here.

**Response expectations:** Tier 1 and Tier 2 are welcome and get a substantive reply when time allows. Tier 3 PRs are
reviewed when scope and time permit. Real PRs land; no merge-window promise.

## Where to file what

| You want to…                                                    | Where                                                                               |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Propose a new principle, change MUST/SHOULD/MAY tiers, etc.     | [`brettdavies/agentnative`](https://github.com/brettdavies/agentnative) (the spec)  |
| Report an `anc check` bug, or propose a new checker feature     | [`brettdavies/agentnative-cli`](https://github.com/brettdavies/agentnative-cli)     |
| Report a site bug (rendering, deployment, anc.dev surface)      | [`brettdavies/agentnative-site`](https://github.com/brettdavies/agentnative-site)   |
| Improve a starter template, add a language idiom, fix the guide | This repo. Issue + PR. Templates: **Bug report** or **Bundle proposal**.            |
| Bump the vendored spec to a newer tag                           | This repo. Run `scripts/sync-spec.sh` and PR the diff.                              |
| Operate as an agent in this repo                                | Read [`AGENTS.md`](./AGENTS.md) first (lint commands, hard rules, common pitfalls). |

## Branch model (TL;DR)

```text
feat/* → PR to dev (squash merge)
       → cherry-pick non-docs commits to release/<version>
       → PR release/* to main (squash merge)
       → tag v<X.Y.Z> + GitHub Release
```

`dev` is the integration branch. `main` is what consumers install. Engineering docs (`docs/plans/`, `docs/solutions/`,
`docs/brainstorms/`, `docs/reviews/`) live on `dev` only and are blocked from `main` by `guard-main-docs.yml`. Full
procedure in [`RELEASES.md`](./RELEASES.md).

## Pull requests

- **Title format**: [Conventional Commits](https://www.conventionalcommits.org/) (`type(scope): description`).
- **Body**: follow [`.github/pull_request_template.md`](.github/pull_request_template.md). The `## Changelog` section is
  the source of truth for `CHANGELOG.md` entries. Write for users, not implementers. Never hand-edit `CHANGELOG.md`;
  it's generated by `scripts/generate-changelog.sh` from PR bodies at release time.
- **Scope**: keep PRs small and single-purpose where possible.
- **Tests**: there is no test runner in this repo, but every PR must pass `markdownlint`, `shellcheck`, and (when
  targeting `main`) `guard-docs / check-forbidden-docs`. Run locally before pushing:

  ```bash
  markdownlint-cli2 '**/*.md' '!node_modules/**'
  shellcheck --severity=style scripts/*.sh bin/*
  actionlint .github/workflows/*.yml
  ```

## Repo layout

The repo ships to consumers as a flat `git clone`. After install, the host (Claude Code, Codex, Cursor, OpenCode)
auto-discovers `SKILL.md` at the install root and ignores everything else. Producer-side files (`scripts/`, `docs/`,
`.github/`, `cliff.toml`, `AGENTS.md`, `CONTRIBUTING.md`, `RELEASES.md`) clone alongside but are inert at runtime.

**Read at runtime by the host:** `SKILL.md`, `getting-started.md`, `bin/check-update`, `spec/`, `references/`,
`templates/`, `VERSION`.

**Producer-side, inert at runtime:** `scripts/`, `docs/plans/`, `.github/`, `cliff.toml`, the producer-docs above.

## Touching the skill content

- **`spec/`** is vendored. Do not edit by hand. Substantive principle changes happen in `brettdavies/agentnative`; bring
  them here by re-running `scripts/sync-spec.sh` after a new upstream tag lands.
- **`SKILL.md`** is the host-discovered entry point. Changes to its `name` or `description` frontmatter affect skill
  discovery on every host. Coordinate before changing.
- **`getting-started.md`** is the agent's first read after `SKILL.md`. Keep it short and concrete; cite spec paths and
  `anc` invocations rather than restating the principles.
- **`bin/check-update`** is the consumer-side update-check script. It compares local `VERSION` to GitHub `main` and
  emits `UPGRADE_AVAILABLE` for the SKILL.md preamble. Treat as load-bearing. Agents rely on it to detect staleness.
- **`references/`** holds implementation guidance (Rust/clap patterns, framework idioms, project structure). When `anc
  --fix` lands upstream, these may shrink. They exist today because the agent has to apply remediations by hand.
- **`templates/`** are starter files. They encode principles by construction. Changes here should be informed by
  `agentnative-cli`'s reference patterns to avoid drift; the cross-repo alignment story is documented in the spec repo's
  `AGENTS.md`.

## AI disclosure

Inherits from the spec's AI disclosure policy. See
[agentnative/CONTRIBUTING.md § AI disclosure policy](https://github.com/brettdavies/agentnative/blob/main/CONTRIBUTING.md#ai-disclosure-policy).

## Security

See [`SECURITY.md`](./SECURITY.md). Do not file security issues in the public tracker. Use the GitHub private security
advisories channel.

## License

By contributing, you agree your contributions are dual-licensed under the same terms as the rest of this repository:

- MIT: see [`LICENSE-MIT`](./LICENSE-MIT)
- Apache License, Version 2.0: see [`LICENSE-APACHE`](./LICENSE-APACHE)

at the consumer's option. No CLA. The Apache-2.0 side carries the standard contributor patent grant under §3 of the
license.

Vendored content under `spec/` is CC BY 4.0 (upstream); contributions to that directory should happen upstream in
[`agentnative-spec`](https://github.com/brettdavies/agentnative).

## Cross-repo navigation

The full visitor-facing menu lives at [`anc.dev/contribute`](https://anc.dev/contribute). Per-repo intakes:

- [Spec](https://github.com/brettdavies/agentnative): principle text, pressure-tests, versioning policy
- [Linter](https://github.com/brettdavies/agentnative-cli): `anc`, the scoring engine, the registry
- [Site](https://github.com/brettdavies/agentnative-site): anc.dev source, leaderboard renderer, live-scoring
- This repo: the agent-facing skill bundle, install paths, host-runtime detection
</content>
</invoke>
