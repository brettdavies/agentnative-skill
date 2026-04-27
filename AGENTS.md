# AGENTS.md

Project-level agent instructions for `agentnative-skill` — the producer repo for the `agent-native-cli` skill bundle.

This repo is **not** a Rust CLI tool. It is a content + script bundle plus producer-side ops scaffolding. The bundle
defines the standard for agent-native CLI design and ships an automated compliance checker that consumers run against
their own tools.

## Layout

The repo is split into **the bundle** (what consumers install) and **producer-side ops** (governance, CI, plans).
Consumers only see the bundle.

| Path                                                                       | Ships to consumers? | Purpose                                                                                                        |
| -------------------------------------------------------------------------- | ------------------- | -------------------------------------------------------------------------------------------------------------- |
| `bundle/SKILL.md`                                                          | ✓                   | The standard itself: 7 agent-readiness principles, when to trigger, how to use.                                |
| `bundle/checklists/`                                                       | ✓                   | Task-shaped checklists for downstream consumers (e.g., `new-tool.md`).                                         |
| `bundle/references/`                                                       | ✓                   | Deep-dive references: principle specifications, framework idioms, project structure, Rust/clap patterns.       |
| `bundle/scripts/check-compliance.sh`                                       | ✓                   | Driver script that runs all 24 compliance checks against a target Rust CLI repo.                               |
| `bundle/scripts/checks/`                                                   | ✓                   | Individual check scripts (`check-p1-*.sh`, `check-p4-*.sh`, etc.) plus shared `_helpers.sh`.                   |
| `bundle/templates/`                                                        | ✓                   | Drop-in starting points for downstream tools (`agents-md-template.md`, clap main, error types, output format). |
| `AGENTS.md`, `RELEASES.md`, `CONTRIBUTING.md`                              | —                   | Producer-repo docs. Not part of the skill.                                                                     |
| `.github/rulesets/`                                                        | —                   | Version-controlled GitHub repository rulesets (applied post-public-flip — see `.github/rulesets/README.md`).   |
| `.github/workflows/`                                                       | —                   | CI: markdownlint, shellcheck. Plus `guard-main-docs.yml` to keep engineering docs off `main`.                  |
| `.github/ISSUE_TEMPLATE/`                                                  | —                   | Bug report + principle proposal templates.                                                                     |
| `docs/plans/`                                                              | —                   | Engineering plans (`dev`-only — guarded out of `main`).                                                        |
| `.markdownlint-cli2.yaml`, `.shellcheckrc`, `.gitattributes`, `.gitignore` | —                   | Local lint configs and repo metadata.                                                                          |

## Lint & Format

```bash
markdownlint-cli2 '**/*.md' '!node_modules/**'
shellcheck --severity=style bundle/scripts/check-compliance.sh bundle/scripts/checks/*.sh
actionlint .github/workflows/*.yml
```

The repo ships a local `.markdownlint-cli2.yaml` (canonical 120-char line length) and `.shellcheckrc` (three narrow
disables documented inline) so CI and local tooling agree.

## Branch + release model

`feat/* → dev (squash) → release/<slug> from origin/main → main (squash)`. Cherry-pick the non-docs commits from `dev`
onto the `release/*` branch. `dev` and `main` are both forever branches; `release/*` branches are short-lived and
auto-deleted on merge.

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only.
`guard-main-docs.yml` blocks any `added` or `modified` files under those paths from reaching `main`. The release-branch
cherry-pick pattern handles this naturally: docs commits stay on `dev`, only feature commits go onto `release/*`.

See [`RELEASES.md`](./RELEASES.md) for the full workflow, version-bump procedure, and the verified status-check context
table.

## What an agent should NEVER do

- Edit shell scripts in `bundle/scripts/checks/` casually. They run on user machines at install time. CODEOWNERS gates
  `bundle/scripts/**` and `.github/workflows/**` for that reason.
- Commit anything under `docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, or `docs/reviews/` directly to a
  `release/*` branch — those paths are filtered by the cherry-pick pattern. Add to `dev` instead.
- Modify `bundle/SKILL.md`'s `name` or `description` frontmatter without coordinating with consumers — those fields
  drive skill discovery on every host.
- Re-tag a published version. Tags are immutable historical anchors that the install endpoints pin to.
- Add Rust/Cargo scaffolding. There is no Rust code in this repo and there should be none — the standard is
  language-prescriptive but the bundle itself is shell + markdown.
- Move producer-ops files into `bundle/`. The split exists deliberately so consumers don't pull repo-management
  artifacts into their skills directories.

## Common pitfalls

- The bundle's `bundle/templates/agents-md-template.md` is for downstream Rust CLI tools (`cargo build`, `cargo test`,
  etc.). This top-level `AGENTS.md` describes the producer repo and is intentionally different.
- `markdownlint-cli2` does NOT consult a global config — every repo needs its own `.markdownlint-cli2.yaml`. If line
  wrapping looks wrong, the local copy has drifted from `~/.markdownlint-cli2.yaml`.
- The `_helpers.sh` file in `bundle/scripts/checks/` is sourced (`source _helpers.sh`), not executed. It is
  intentionally not marked +x.

## References

- [`bundle/SKILL.md`](./bundle/SKILL.md) — the standard
- [`README.md`](./README.md) — what this repo is, repo layout, install pointer
- [`SECURITY.md`](./SECURITY.md) — vulnerability disclosure
- [`RELEASES.md`](./RELEASES.md) — release procedure
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to propose changes
- [`.github/rulesets/README.md`](./.github/rulesets/README.md) — branch + tag protection apply procedure
