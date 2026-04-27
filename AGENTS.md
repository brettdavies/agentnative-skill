# AGENTS.md

Project-level agent instructions for `agentnative-skill` — the producer repo for the `agent-native-cli` skill bundle.

This repo is **not** a Rust CLI tool and **not** a compliance checker. It is the agent-facing guide that pairs with
[`anc`](https://github.com/brettdavies/agentnative-cli) (the canonical checker) and
[`agentnative-spec`](https://github.com/brettdavies/agentnative) (the canonical principle text, vendored at
`bundle/spec/`). The bundle teaches agents how to use `anc` and supplies the surrounding context — spec, idioms,
templates — that `anc` findings reference.

## Layout

The repo is split into **the bundle** (what consumers install) and **producer-side ops** (governance, CI, plans).
Consumers only see the bundle.

| Path                                                                                     | Ships to consumers? | Purpose                                                                                                                         |
| ---------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `bundle/SKILL.md`                                                                        | ✓                   | Skill metadata + entry-point pointer to `getting-started.md`.                                                                   |
| `bundle/getting-started.md`                                                              | ✓                   | Three working loops (existing CLI / new Rust / other language); canonical `anc check` invocations.                              |
| `bundle/spec/`                                                                           | ✓                   | Vendored copy of `agentnative-spec` at a pinned ref. Canonical principle text + machine-readable `requirements[]`.              |
| `bundle/references/`                                                                     | ✓                   | Implementation guidance: framework idioms (Rust + others), project structure, Rust/clap patterns.                               |
| `bundle/templates/`                                                                      | ✓                   | Drop-in starter files for greenfield Rust CLIs (`clap-main.rs`, `error-types.rs`, `output-format.rs`, `agents-md-template.md`). |
| `scripts/sync-spec.sh`                                                                   | —                   | Vendor `agentnative-spec` into `bundle/spec/` at a pinned `SPEC_REF`. Mirror of the agentnative-cli script.                     |
| `scripts/generate-changelog.sh`                                                          | —                   | Release-time CHANGELOG generator (git-cliff + PR-body extraction).                                                              |
| `AGENTS.md`, `RELEASES.md`, `CONTRIBUTING.md`                                            | —                   | Producer-repo docs. Not part of the skill.                                                                                      |
| `.github/rulesets/`                                                                      | —                   | Version-controlled GitHub repository rulesets (applied post-public-flip — see `.github/rulesets/README.md`).                    |
| `.github/workflows/`                                                                     | —                   | CI: markdownlint, shellcheck. Plus `guard-main-docs.yml` to keep engineering docs off `main`.                                   |
| `.github/ISSUE_TEMPLATE/`                                                                | —                   | Bug report + principle proposal templates.                                                                                      |
| `docs/plans/`                                                                            | —                   | Engineering plans (`dev`-only — guarded out of `main`).                                                                         |
| `.markdownlint-cli2.yaml`, `.shellcheckrc`, `.gitattributes`, `.gitignore`, `cliff.toml` | —                   | Local lint configs, git-cliff config, and repo metadata.                                                                        |

## Lint & Format

```bash
markdownlint-cli2 '**/*.md' '!node_modules/**'
shellcheck --severity=style scripts/*.sh
actionlint .github/workflows/*.yml
```

The repo ships a local `.markdownlint-cli2.yaml` (canonical 120-char line length) and `.shellcheckrc` so CI and local
tooling agree. The bundle has no shell scripts to lint — `anc` is the checker and lives in its own repo.

## Spec sync

The canonical principle text lives in [`brettdavies/agentnative`](https://github.com/brettdavies/agentnative). This repo
vendors it via `scripts/sync-spec.sh` at a pinned `SPEC_REF`. To bump:

```bash
SPEC_REF=v0.2.1 scripts/sync-spec.sh    # pulls from $HOME/dev/agentnative-spec by default
git diff bundle/spec/                    # review
```

Then commit the result with a message like `chore: bump bundle/spec to agentnative-spec@v0.2.1`. The current pin is
recorded in [`bundle/spec/README.md`](./bundle/spec/README.md) and the version itself is in `bundle/spec/VERSION`.

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

- Edit anything under `bundle/spec/` by hand. It is vendored from `agentnative-spec`. Any required change is a PR
  against the spec repo, then a `scripts/sync-spec.sh` bump here.
- Reimplement `anc`. The bundle does not contain shell-script duplicates of `anc`'s checks. If you find yourself writing
  `rg`-based grep checks, you're rebuilding what `anc` already does — use `anc check --output json` instead.
- Commit anything under `docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, or `docs/reviews/` directly to a
  `release/*` branch — those paths are filtered by the cherry-pick pattern. Add to `dev` instead.
- Modify `bundle/SKILL.md`'s `name` or `description` frontmatter without coordinating with consumers — those fields
  drive skill discovery on every host.
- Re-tag a published version. Tags are immutable historical anchors that the install endpoints pin to.
- Add Rust/Cargo scaffolding. There is no Rust code in this repo and there should be none — the standard is
  language-prescriptive but the bundle itself is markdown.
- Move producer-ops files into `bundle/`. The split exists deliberately so consumers don't pull repo-management
  artifacts into their skills directories.

## Common pitfalls

- The bundle's `bundle/templates/agents-md-template.md` is for downstream Rust CLI tools (`cargo build`, `cargo test`,
  etc.). This top-level `AGENTS.md` describes the producer repo and is intentionally different.
- `markdownlint-cli2` does NOT consult a global config — every repo needs its own `.markdownlint-cli2.yaml`. If line
  wrapping looks wrong, the local copy has drifted from `~/.markdownlint-cli2.yaml`.
- `bundle/spec/` is a vendored copy, not a symlink or submodule. Stale orphan files can appear if the upstream spec
  renames or removes a principle. `git status` after `scripts/sync-spec.sh` surfaces them; resolve by deletion.
- `CHANGELOG.md` is generated by `scripts/generate-changelog.sh` (git-cliff + PR-body extraction). Never hand-edit it —
  fix the input (PR body's `## Changelog` section) and re-run.

## References

- [`bundle/SKILL.md`](./bundle/SKILL.md) — skill entry point
- [`bundle/getting-started.md`](./bundle/getting-started.md) — agent's three working loops
- [`bundle/spec/README.md`](./bundle/spec/README.md) — vendored-spec resync procedure
- [`README.md`](./README.md) — what this repo is, repo layout, install pointer
- [`SECURITY.md`](./SECURITY.md) — vulnerability disclosure
- [`RELEASES.md`](./RELEASES.md) — release procedure
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to propose changes
- [`.github/rulesets/README.md`](./.github/rulesets/README.md) — branch + tag protection apply procedure
