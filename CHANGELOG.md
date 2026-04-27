# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-27

### Added

- Initial release of the `agent-native-cli` skill bundle.
- `SKILL.md` defining the north-star standard and 7 agent-readiness principles (non-interactive, structured output,
  progressive help, actionable errors, safe retries, composable structure, bounded responses).
- `checklists/new-tool.md` — task checklist for starting a new agent-native CLI.
- `references/` — five deep-dive references: principle specifications, framework idioms (Rust/clap and other languages),
  project structure, Rust/clap patterns.
- `scripts/check-compliance.sh` — automated compliance checker that produces deterministic pass/warn/fail scorecards
  across 24 checks in 9 groups.
- `scripts/checks/` — individual check scripts plus shared `_helpers.sh`.
- `templates/` — starter files: `AGENTS.md`, `clap-main.rs`, `error-types.rs`, `output-format.rs`.
- Governance: `LICENSE` (MIT), `SECURITY.md`, `CODEOWNERS`, `.gitattributes`, `.gitignore`.
- CI: `markdownlint` and `shellcheck` jobs running on `push` and `pull_request`.

[0.1.0]: https://github.com/brettdavies/agentnative-skill/releases/tag/v0.1.0
