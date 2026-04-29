# AGENTS.md

Project-level agent instructions for `agentnative-skill` — the producer repo for the `agent-native-cli` skill.

This repo is **not** a Rust CLI tool and **not** a compliance checker. It is the agent-facing guide that pairs with
[`anc`](https://github.com/brettdavies/agentnative-cli) (the canonical checker) and
[`agentnative-spec`](https://github.com/brettdavies/agentnative) (the canonical principle text, vendored at `spec/`).
The skill teaches agents how to use `anc` and supplies the surrounding context — spec, idioms, templates — that `anc`
findings reference.

## Layout

The repo ships to consumers via plain `git clone`. After install, the host (Claude Code, Codex, Cursor, OpenCode)
auto-discovers `SKILL.md` at the install root and ignores everything else. Producer-side files (`scripts/`, `docs/`,
`.github/`, `cliff.toml`, etc.) clone alongside the skill content but are inert at runtime.

| Path                                                                                     | Read at runtime by host? | Purpose                                                                                                                            |
| ---------------------------------------------------------------------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `SKILL.md`                                                                               | ✓                        | Skill metadata + entry-point pointer to `getting-started.md`. The host's first read.                                               |
| `getting-started.md`                                                                     | ✓                        | Three working loops (existing CLI / new Rust / other language); canonical `anc check` invocations.                                 |
| `bin/check-update`                                                                       | ✓                        | Consumer-side update-check script. Compares local `VERSION` to GitHub `main`; emits `UPGRADE_AVAILABLE` for the SKILL.md preamble. |
| `spec/`                                                                                  | ✓                        | Vendored copy of `agentnative-spec`. Canonical principle text + machine-readable `requirements[]`.                                 |
| `references/`                                                                            | ✓                        | Implementation guidance: framework idioms (Rust + others), project structure, Rust/clap patterns.                                  |
| `templates/`                                                                             | ✓                        | Drop-in starter files for greenfield Rust CLIs (`clap-main.rs`, `error-types.rs`, `output-format.rs`, `agents-md-template.md`).    |
| `VERSION`                                                                                | ✓                        | Single-line current version. `bin/check-update` reads this for the upgrade comparison.                                             |
| `scripts/sync-spec.sh`                                                                   | —                        | Vendor the latest `agentnative-spec` v\* tag into `spec/`. Mirror of the agentnative-cli script.                                   |
| `scripts/generate-changelog.sh`                                                          | —                        | Release-time CHANGELOG generator (git-cliff + PR-body extraction).                                                                 |
| `AGENTS.md`, `RELEASES.md`, `CONTRIBUTING.md`, `README.md`, `SECURITY.md`                | —                        | Producer-repo docs.                                                                                                                |
| `.github/rulesets/`                                                                      | —                        | Version-controlled GitHub repository rulesets.                                                                                     |
| `.github/workflows/`                                                                     | —                        | CI: markdownlint, shellcheck. Plus `guard-main-docs.yml` to keep engineering docs off `main`.                                      |
| `.github/ISSUE_TEMPLATE/`                                                                | —                        | Bug report + bundle-proposal templates.                                                                                            |
| `docs/plans/`                                                                            | —                        | Engineering plans (`dev`-only — guarded out of `main`).                                                                            |
| `.markdownlint-cli2.yaml`, `.shellcheckrc`, `.gitattributes`, `.gitignore`, `cliff.toml` | —                        | Local lint configs, git-cliff config, and repo metadata.                                                                           |

## Lint & Format

```bash
markdownlint-cli2 '**/*.md' '!node_modules/**'
shellcheck --severity=style scripts/*.sh bin/*
actionlint .github/workflows/*.yml
```

The repo ships a local `.markdownlint-cli2.yaml` (canonical 120-char line length) and `.shellcheckrc` so CI and local
tooling agree.

## Spec sync

The canonical principle text lives in [`brettdavies/agentnative`](https://github.com/brettdavies/agentnative). This repo
vendors the latest released `v*` tag via `scripts/sync-spec.sh`. To resync:

```bash
git -C $HOME/dev/agentnative-spec fetch --tags    # pick up new upstream tags
scripts/sync-spec.sh                              # auto-resolves the latest v* tag locally
git diff spec/                                    # review
```

Then commit the result with a message like `chore: bump spec to agentnative-spec@<version>`. The vendored version is
recorded in `spec/VERSION`.

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

- Edit anything under `spec/` by hand. It is vendored from `agentnative-spec`. Any required change is a PR against the
  spec repo, then a `scripts/sync-spec.sh` bump here.
- Reimplement `anc`. The skill does not contain shell-script duplicates of `anc`'s checks. If you find yourself writing
  `rg`-based grep checks, you're rebuilding what `anc` already does — use `anc check --output json` instead.
- Commit anything under `docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, or `docs/reviews/` directly to a
  `release/*` branch — those paths are filtered by the cherry-pick pattern. Add to `dev` instead.
- Modify `SKILL.md`'s `name` or `description` frontmatter without coordinating with consumers — those fields drive skill
  discovery on every host.
- Re-tag a published version. Tags are immutable historical anchors for released versions.
- Add Rust/Cargo scaffolding. There is no Rust code in this repo and there should be none — the standard is
  language-prescriptive but the skill itself is markdown + a tiny bash update-check.

## Common pitfalls

- The skill's `templates/agents-md-template.md` is for downstream Rust CLI tools (`cargo build`, `cargo test`, etc.).
  This top-level `AGENTS.md` describes the producer repo and is intentionally different.
- `markdownlint-cli2` does NOT consult a global config — every repo needs its own `.markdownlint-cli2.yaml`. If line
  wrapping looks wrong, the local copy has drifted from `~/.markdownlint-cli2.yaml`.
- `spec/` is a vendored copy, not a symlink or submodule. Stale orphan files can appear if the upstream spec renames or
  removes a principle. `git status` after `scripts/sync-spec.sh` surfaces them; resolve by deletion.
- `CHANGELOG.md` is generated by `scripts/generate-changelog.sh` (git-cliff + PR-body extraction). Never hand-edit it —
  fix the input (PR body's `## Changelog` section) and re-run.

## References

- [`SKILL.md`](./SKILL.md) — skill entry point
- [`getting-started.md`](./getting-started.md) — agent's three working loops
- [`spec/README.md`](./spec/README.md) — vendored-spec resync procedure
- [`README.md`](./README.md) — what this repo is, repo layout, install pointer
- [`SECURITY.md`](./SECURITY.md) — vulnerability disclosure
- [`RELEASES.md`](./RELEASES.md) — release procedure
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to propose changes
</content>

</invoke>
