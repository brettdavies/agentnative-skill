# Contributing to `agentnative-skill`

Thanks for your interest. This repo defines a north-star standard for agent-native CLI tools and ships an automated
compliance checker. Substantive proposals should engage with the principles directly.

## Where to start

| You want to…                                    | Read first                                                                                                                            |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Understand the standard                         | [`bundle/SKILL.md`](./bundle/SKILL.md) and [`bundle/references/principles-deep-dive.md`](./bundle/references/principles-deep-dive.md) |
| File a bug in the compliance checker or a check | Open an issue with the **Bug report** template                                                                                        |
| Propose a new principle, check, or template     | Open an issue with the **Principle proposal** template                                                                                |
| Add or fix something concrete                   | Read [`RELEASES.md`](./RELEASES.md) for the branch model, then open a PR                                                              |
| Operate as an agent in this repo                | [`AGENTS.md`](./AGENTS.md) (lint commands, hard rules, common pitfalls)                                                               |

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

- **Title format**: [Conventional Commits](https://www.conventionalcommits.org/) — `type(scope): description`.
- **Body**: follow [`.github/pull_request_template.md`](.github/pull_request_template.md). The `## Changelog` section is
  the source of truth for `CHANGELOG.md` entries — write for users, not implementers.
- **Scope**: keep PRs small and single-purpose where possible. A bundle change, a check tightening, and a docs refactor
  should be three PRs, not one.
- **Tests**: there is no test runner in this repo, but every PR must pass `markdownlint`, `shellcheck`, and (when
  targeting `main`) `guard-docs / check-forbidden-docs`. Run locally before pushing:

  ```bash
  markdownlint-cli2 '**/*.md' '!node_modules/**'
  shellcheck --severity=style bundle/scripts/check-compliance.sh bundle/scripts/checks/*.sh
  actionlint .github/workflows/*.yml
  ```

## Bundle vs producer-ops boundary

The repository is split into:

- **`bundle/`** — what consumers install via `anc.dev/install`. SKILL.md, checklists, references, scripts, templates.
- **Everything else** — producer-side ops: governance (`AGENTS.md`, `RELEASES.md`, `CONTRIBUTING.md`, `SECURITY.md`), CI
  (`.github/workflows/`), rulesets (`.github/rulesets/`), engineering plans (`docs/plans/`).

Do not move producer-ops files into `bundle/`. Do not move bundle content out of `bundle/`. The split is what keeps
consumer skill directories clean.

## Substantive changes to the standard

The 7 principles are stable. Proposing a new principle, removing one, or materially changing existing semantics
requires:

1. An issue using the **Principle proposal** template, including the problem statement, prior art, and a draft of how
   `bundle/SKILL.md` and `bundle/references/principles-deep-dive.md` would change.
2. Discussion in the issue. Maintainer signoff before any PR.
3. A PR that updates SKILL.md, the deep-dive, the relevant `bundle/scripts/checks/check-p*-*.sh` scripts, the templates,
   and the `CHANGELOG.md` together. Partial coverage isn't merged.

Tightening a check's pass criteria is a `Changed` (minor or major depending on how many existing tools regress). Adding
a new check is `Added`. Removing a check is `Removed` (major). See SemVer guidance in `RELEASES.md`.

## Security

See [`SECURITY.md`](./SECURITY.md). Do not file security issues in the public tracker — use the GitHub private security
advisories channel.

## License

By contributing, you agree your contributions are licensed under the MIT license that covers this repository (see
[`LICENSE`](./LICENSE)).
