# AGENTS.md

Project-level agent instructions for `agentnative-skill` — the producer repo for the `agent-native-cli` skill bundle.

This repo is **not** a Rust CLI tool. It is a content + script bundle that ships at the repo root and is consumed via
`git clone` into a host's skills directory (Claude Code, Cursor, Codex, etc.). The bundle defines the standard for
agent-native CLI design and ships an automated compliance checker that consumers run against their own tools.

## Layout

| Path                          | Purpose                                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `SKILL.md`                    | The standard itself: 7 agent-readiness principles, when to trigger, how to use.                              |
| `checklists/`                 | Task-shaped checklists for downstream consumers (e.g., `new-tool.md`).                                       |
| `references/`                 | Deep-dive references: principle specifications, framework idioms, project structure, Rust/clap patterns.     |
| `scripts/check-compliance.sh` | Driver script that runs all 24 compliance checks against a target Rust CLI repo.                             |
| `scripts/checks/`             | Individual check scripts (`check-p1-*.sh`, `check-p4-*.sh`, etc.) plus shared `_helpers.sh`.                 |
| `templates/`                  | Drop-in starting points for downstream tools (`AGENTS.md`, clap main, error types, output format).           |
| `.github/rulesets/`           | Version-controlled GitHub repository rulesets (applied post-public-flip — see `.github/rulesets/README.md`). |
| `.github/workflows/`          | CI: markdownlint, shellcheck. Plus `guard-main-docs.yml` to keep engineering docs off `main`.                |
| `docs/plans/`                 | Engineering plans (`dev`-only — guarded out of `main`).                                                      |

## Lint & Format

```bash
markdownlint-cli2 '**/*.md' '!node_modules/**'
shellcheck --severity=style scripts/check-compliance.sh scripts/checks/*.sh
actionlint .github/workflows/*.yml
```

The repo ships a local `.markdownlint-cli2.yaml` (canonical 120-char line length) and `.shellcheckrc` (three narrow
disables documented inline) so CI and local tooling agree.

## Branch model

`feat/* → dev (squash) → main (squash)`. `dev` and `main` are both forever; release branches are not used.

Engineering docs (`docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/`) live on `dev` only.
`guard-main-docs.yml` blocks them from reaching `main`.

See [`RELEASES.md`](./RELEASES.md) for the full workflow and version-bump procedure.

## Releases

Tags `v*` on `main`. Tag protection (deletion + force-push + update blocked) is in `.github/rulesets/protect-tags.json`;
applied post-public-flip. The site at [`anc.dev/install`](https://anc.dev/install) pins to the commit SHA of the latest
tag.

## What an agent should NEVER do

- Edit shell scripts in `scripts/checks/` casually. They run on user machines at install time. CODEOWNERS gates
  `scripts/**` and `.github/workflows/**` for that reason.
- Commit anything in `docs/plans/` or similar engineering docs to a branch heading toward `main`. Use `dev`.
- Modify `SKILL.md`'s `name` or `description` frontmatter without coordinating with consumers — those fields drive skill
  discovery on every host.
- Re-tag a published version. Tags are immutable historical anchors that the install endpoints pin to.
- Add Rust/Cargo scaffolding. There is no Rust code in this repo and there should be none — the standard is
  language-prescriptive but the bundle itself is shell + markdown.

## Common pitfalls

- The bundle's `templates/agents-md-template.md` is for downstream Rust CLI tools (`cargo build`, `cargo test`, etc.).
  This `AGENTS.md` describes the producer repo and is intentionally different.
- `markdownlint-cli2` does NOT consult a global config — every repo needs its own `.markdownlint-cli2.yaml`. If line
  wrapping looks wrong, the local copy has drifted from `~/.markdownlint-cli2.yaml`.
- The `_helpers.sh` file in `scripts/checks/` is sourced (`source _helpers.sh`), not executed. It is intentionally not
  marked +x.

## References

- [`SKILL.md`](./SKILL.md) — the standard
- [`README.md`](./README.md) — what this repo is, install pointer
- [`SECURITY.md`](./SECURITY.md) — vulnerability disclosure
- [`RELEASES.md`](./RELEASES.md) — release procedure
- [`.github/rulesets/README.md`](./.github/rulesets/README.md) — branch + tag protection apply procedure
