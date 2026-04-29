# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-04-29

### Added

- Version-controlled GitHub repository rulesets for `main`, `dev`, and release tags (`v*`). Apply procedure documented in `.github/rulesets/README.md`. by @brettdavies in [#1](https://github.com/brettdavies/agentnative-skill/pull/1)
- `AGENTS.md` (root) describing the bundle layout, lint commands, branch model, and hard rules for agents working in this producer repo. by @brettdavies in [#2](https://github.com/brettdavies/agentnative-skill/pull/2)
- `RELEASES.md` (root) documenting a release procedure for this repo (later rewritten in #3 to the canonical full `release/*` pattern).
- `.github/pull_request_template.md` (canonical PR template).
- `.github/workflows/guard-main-docs.yml` caller for the `brettdavies/.github` reusable workflow that blocks `docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/` from PRs targeting `main`.
- `cliff.toml` — git-cliff configuration mirroring sibling repos. by @brettdavies in [#3](https://github.com/brettdavies/agentnative-skill/pull/3)
- `scripts/generate-changelog.sh` — release-time CHANGELOG generator. Reads PR-body `## Changelog` sections and prepends a curated, attributed `[X.Y.Z]` section. Authoritative; never hand-edit `CHANGELOG.md`.
- `CONTRIBUTING.md` — how to propose changes, link to release procedure.
- `.github/ISSUE_TEMPLATE/bug_report.md` — bug report template.
- `.github/ISSUE_TEMPLATE/principle_proposal.md` — substantive standards-change template.
- `**Renamed:**` subsection in `.github/pull_request_template.md` (sync of the canonical update at `~/dotfiles/stow/github/dot-config/github/pull_request_template.md`). Sister sync PRs landing in agentnative-cli (#30 there) and agentnative-site (already on dev as commit 4437435).
- Add vendored `bundle/spec/` tree (agentnative-spec @ v0.2.0): `VERSION`, `CHANGELOG.md`, `README.md`, and seven `principles/p*.md` files with machine-readable `requirements[]` frontmatter — canonical principle text the skill now points at instead of paraphrasing. by @brettdavies in [#4](https://github.com/brettdavies/agentnative-skill/pull/4)
- Add `bundle/getting-started.md` covering three working agent loops (existing CLI / new Rust / other language), canonical `anc check --output json` invocations, and a "where things live" map.
- Add `scripts/sync-spec.sh` so the bundle can re-vendor agentnative-spec on demand.
- `LICENSE-APACHE` — Apache 2.0 boilerplate, identical to the file in `agentnative-cli`. by @brettdavies in [#6](https://github.com/brettdavies/agentnative-skill/pull/6)
- `bundle/bin/check-update` — script that compares the consumer's local `VERSION` against the producer repo's `main` and emits `UPGRADE_AVAILABLE <local> <remote>` (or empty when up-to-date / snoozed / disabled). Adapts the gstack pattern with cache TTL (60min UP_TO_DATE / 720min UPGRADE_AVAILABLE) and a 3-level snooze (24h / 48h / 7d). State directory: `$HOME/.cache/agent-native-cli/`. by @brettdavies in [#8](https://github.com/brettdavies/agentnative-skill/pull/8)
- `bundle/SKILL.md` `## Update check` section — first non-frontmatter section after the intro. Documents how to invoke the script and inlines the AskUserQuestion-driven upgrade flow with three options ("Yes, upgrade now" / "Not now" / "Never ask again").

### Changed

- `.gitignore` adds `!AGENTS.md` to override the global `**/AGENTS.md` ignore for this repo only. Other repos remain unaffected. by @brettdavies in [#2](https://github.com/brettdavies/agentnative-skill/pull/2)
- **Breaking (install layout):** Skill bundle moved into `bundle/` subdirectory. Installers must fetch `bundle/` rather than the entire repo. Consumer's installed skill directory shape is unchanged (`SKILL.md` at the root). by @brettdavies in [#3](https://github.com/brettdavies/agentnative-skill/pull/3)
- Adopted the full `release/*` cherry-pick release pattern (was lightweight `dev → main`). Plans on `dev` no longer conflict with release PRs because release branches cherry-pick only non-docs commits.
- `RELEASES.md` rewritten to the canonical pattern; broken `../../.claude/...` link removed.
- **Breaking (install layout):** Skill bundle no longer ships `bundle/scripts/` or `bundle/checklists/`. Installers and consumers should fetch only the surviving directories: `SKILL.md`, `getting-started.md`, `spec/`, `references/`, `templates/`. The consumer's installed skill-directory shape (`SKILL.md` at the root) is unchanged. by @brettdavies in [#4](https://github.com/brettdavies/agentnative-skill/pull/4)
- Rewrite `bundle/SKILL.md` to drop inline principle prose, link `bundle/getting-started.md` and `bundle/spec/principles/` for progressive disclosure, and frame the spec / `anc` / skill three-artifact ecosystem.
- Reframe `RELEASES.md` SemVer guidance around the bundle's actual surface (markdown + templates + vendored spec) rather than deleted shell-script exit codes; document the spec-bump-vs-skill-version distinction.
- License changed from MIT-only to dual MIT or Apache-2.0 (consumer's choice). The skill bundle, top-level scripts, and all repo content are now dual-licensed; no MIT compatibility regression. by @brettdavies in [#6](https://github.com/brettdavies/agentnative-skill/pull/6)
- Documentation now points at `https://anc.dev/skill` instead of `https://anc.dev/install` for skill installation instructions, the cross-repo re-pin process, and the `bundle/` consumer description. by @brettdavies in [#7](https://github.com/brettdavies/agentnative-skill/pull/7)
- `bundle/SKILL.md`, `bundle/getting-started.md`, `bundle/spec/README.md` — drop "pinned ref" / "pinned upstream tag" / "pinned SPEC_VERSION" framing in favor of "vendored snapshot, refreshed each release". The bundle's behavior is unchanged; the language was misleading because the install command never actually pinned at the consumer side. by @brettdavies in [#8](https://github.com/brettdavies/agentnative-skill/pull/8)
- **BREAKING (install layout):** Skill content moved out of `bundle/` to the repo root. After install, hosts find `SKILL.md` at the skill root (where Claude Code expects it), not at `<skill-root>/bundle/SKILL.md`. Plain `git clone --depth 1` and `git pull --ff-only` are now the load-bearing install + update commands; no sparse-checkout magic, no post-install scripts. by @brettdavies in [#9](https://github.com/brettdavies/agentnative-skill/pull/9)
- `bin/check-update`: `SKILL_DIR` is now one dir up from the script (was two), since there's no `bundle/` layer.
- `scripts/sync-spec.sh` writes to `spec/` (was `bundle/spec/`).
- README, AGENTS, CONTRIBUTING reframe the consumer/producer split from a directory boundary (`bundle/` vs everything else) to an audience boundary (host reads `SKILL.md` + `bin/` + `spec/` + `references/` + `templates/` + `VERSION`; ignores everything else).
- Spec content vendored under `spec/` re-vendored from `agentnative-spec` v0.2.0 to v0.3.0. All 7 principles flip `status: draft` → `status: active` (P1–P7 are now the shipped baseline); prose tightened across P1 (TUI parenthetical), P2 (sysexits acknowledgment), P4 (dependency-gating cleanup), P5 (`--dry-run` write-gate + retry hedge), P6 (SIGPIPE language-neutral + global-flags behavioral lead), P7 (LLM-vs-non-LLM cost generalization). No requirement IDs added/removed/renamed; no level changes. Full upstream context: agentnative `v0.3.0` CHANGELOG. by @brettdavies in [#10](https://github.com/brettdavies/agentnative-skill/pull/10)
- `scripts/sync-spec.sh` no longer accepts `SPEC_REF`. The script always vendors the latest `v*` tag, queried from `SPEC_REMOTE_URL` (default `https://github.com/brettdavies/agentnative.git`) via `git ls-remote --tags --sort=-version:refname` and shallow-cloned for extraction. On any remote failure, falls back to the existing `SPEC_ROOT`-based logic (default `$HOME/dev/agentnative-spec`). New env var `SPEC_REMOTE_URL` overrides the remote; the temp clone is auto-cleaned on script exit via trap. by @brettdavies in [#11](https://github.com/brettdavies/agentnative-skill/pull/11)
- `.markdownlint-cli2.yaml` excludes `CHANGELOG.md` from linting. Aligns its treatment with `spec/CHANGELOG.md` and reflects that the file is regenerated by `scripts/generate-changelog.sh`, not hand-edited. Per-line content is governed by PR-body bullets in source PRs, not by this repo's MD013 line-length rule. by @brettdavies in [#13](https://github.com/brettdavies/agentnative-skill/pull/13)

### Fixed

- Harden `bundle/bin/check-update` against malformed local `VERSION` (apply SemVer regex; malformed → silent exit) and against curl failure being cached as UP_TO_DATE (skip cache write on network failure so the next invocation retries). by @brettdavies in [#8](https://github.com/brettdavies/agentnative-skill/pull/8)
- Align table pipes in `SKILL.md` and `getting-started.md` after the `bundle/` path strip (markdownlint MD060). MD060 isn't auto-fixable, so violations slipped past the local PostToolUse hook and surfaced in CI. by @brettdavies in [#9](https://github.com/brettdavies/agentnative-skill/pull/9)

### Documentation

- `README.md` — License section rewritten to reflect dual licensing and link both LICENSE files; tree row updated. by @brettdavies in [#6](https://github.com/brettdavies/agentnative-skill/pull/6)
- `CONTRIBUTING.md` — License section rewritten: contributions are dual-licensed at the consumer's option, no CLA, with an explicit pointer to the Apache §3 patent grant.
- `bundle/spec/README.md` licensing reference catches drift from PR #6: was "MIT-licensed", now reflects the actual dual MIT/Apache-2.0 posture introduced in `18836d8`. by @brettdavies in [#8](https://github.com/brettdavies/agentnative-skill/pull/8)
- `RELEASES.md` gains a `## Spec re-vendoring` section between `## Why branch from main, not dev` and `## Version bump procedure`, documenting the `scripts/sync-spec.sh` re-vendor step. The script auto-resolves the latest upstream tag from the remote, so no manual version selection is needed at re-vendor time. by @brettdavies in [#10](https://github.com/brettdavies/agentnative-skill/pull/10)
- `AGENTS.md` `## Spec sync` section: rewritten — single-step recipe (`scripts/sync-spec.sh` then review); notes the remote-first / local-fallback behavior and the `SPEC_REMOTE_URL` / `SPEC_ROOT` overrides. Commit-message example uses `<version>` placeholder instead of a hard-coded version. by @brettdavies in [#11](https://github.com/brettdavies/agentnative-skill/pull/11)
- `spec/README.md` `## Resync` section: rewritten similarly; drops the manually-maintained `**Current snapshot:**` line and points readers at `spec/VERSION` (which `sync-spec.sh` writes verbatim from upstream).
- `RELEASES.md` post-merge sequence ends at the GitHub Release; replaces deleted step 5 with a one-liner pointing consumers at `bin/check-update`.

### Removed

- Remove `bundle/scripts/check-compliance.sh` and 24 `bundle/scripts/checks/check-*.sh` files (plus `_helpers.sh`). `anc check --output json` is the canonical replacement. by @brettdavies in [#4](https://github.com/brettdavies/agentnative-skill/pull/4)
- Remove `bundle/references/principles-deep-dive.md` (419-line hand-typed paraphrase of the spec; canonical text now lives at `bundle/spec/principles/`).
- Remove `bundle/checklists/new-tool.md` (pre-anc manual checklist; replaced by `bundle/getting-started.md`).
- All SHA-pin claims from public-facing markdown (`RELEASES.md`, `AGENTS.md`, `README.md`, `spec/README.md`, `CONTRIBUTING.md`): pipeline diagram's "site re-pins to commit SHA" step, the post-merge "site re-pins via its own PR" step, the `protect-tags.json` / `install endpoints` claims that tags are pinned to install endpoints, and the spec-vendor "pinned ref" / "pinned `SPEC_REF`" / "current pin is recorded" vocabulary across all docs. by @brettdavies in [#11](https://github.com/brettdavies/agentnative-skill/pull/11)

**Full Changelog**: [v0.1.0...v0.2.0](https://github.com/brettdavies/agentnative-skill/compare/v0.1.0...v0.2.0)

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
