# agentnative-skill

The producer repo for the [`agent-native-cli`](./SKILL.md) skill: an agent-facing guide to designing, building, and
auditing CLI tools for use by AI agents.

This skill is the fourth artifact in a four-repo ecosystem:

| Repo                                                                        | Role                                                           |
| --------------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`agentnative`](https://github.com/brettdavies/agentnative) (the spec)      | Canonical text of the eight principles. CC BY 4.0.             |
| [`agentnative-cli`](https://github.com/brettdavies/agentnative-cli) (`anc`) | The compliance checker. MIT / Apache-2.0.                      |
| [`agentnative-site`](https://github.com/brettdavies/agentnative-site)       | `anc.dev`: leaderboard, scorecards, live scoring.              |
| **This repo** (`agentnative-skill`)                                         | The agent-facing guide. Vendors the spec; teaches `anc` usage. |

## Repository layout

```text
agentnative-skill/
├── SKILL.md                skill entry point — host-discovered; points the agent at getting-started.md
├── getting-started.md      three working loops; canonical anc invocations
├── bin/
│   └── check-update        consumer-side update-check script (gstack-style)
├── spec/                   vendored from agentnative-spec (do not edit)
├── references/             implementation guidance: framework idioms, project structure, Rust/clap patterns
├── templates/              drop-in starter files (clap-main, error-types, output-format, agents-md-template)
├── VERSION                 single-line current version (read by bin/check-update)
├── scripts/
│   ├── sync-spec.sh                vendor the latest agentnative-spec v* tag into spec/
│   ├── sync-prose-tooling.sh       vendor BRAND.md from agentnative-spec main HEAD
│   └── generate-changelog.sh       release-time CHANGELOG generator (git-cliff + PR-body extraction)
├── docs/plans/             engineering plans (dev-only — guarded out of main)
├── .github/                workflows, rulesets, issue templates, PR template
├── AGENTS.md               project-level agent instructions FOR THIS REPO (producer-side)
├── BRAND.md                universal voice and identity (vendored from agentnative-spec)
├── PRODUCT.md              skill-bundle channel design context (inherits from BRAND.md)
├── CONTRIBUTING.md         how to propose changes
├── RELEASES.md             release procedure (cherry-pick from dev → release/* → main)
├── RELEASES-RATIONALE.md   rationale companion to RELEASES.md (the WHY)
├── SECURITY.md             vulnerability disclosure
├── CHANGELOG.md            released versions (generated, never hand-edited)
├── cliff.toml              git-cliff configuration
├── LICENSE-MIT             MIT (one half of the dual license)
├── LICENSE-APACHE          Apache 2.0 (the other half)
└── README.md               this file
```

Consumer-facing files (`SKILL.md`, `getting-started.md`, `bin/`, `spec/`, `references/`, `templates/`, `VERSION`,
`LICENSE-*`) are read by the agent at runtime. Producer-side files (`scripts/`, `docs/`, `.github/`, `AGENTS.md`,
`CONTRIBUTING.md`, `RELEASES.md`, `cliff.toml`) ship to consumers via `git clone` but are inert at runtime. The host
discovers `SKILL.md` and ignores everything else.

## Install

See [anc.dev/skill](https://anc.dev/skill) for the supported hosts (Claude Code, Cursor, Codex, etc.) and the exact
install commands. The install model is plain `git clone --depth 1` into the host's skills directory: for example
`~/.claude/skills/agent-native-cli/`. The host auto-discovers `SKILL.md` at the install root; `SKILL.md` then points the
agent at `getting-started.md` for progressive disclosure. Updates are `git pull --ff-only` from inside the install dir,
prompted by `bin/check-update`.

## Skill contents

- [`SKILL.md`](./SKILL.md): skill metadata + entry-point pointer.
- [`getting-started.md`](./getting-started.md): three working loops (existing CLI / new Rust / other language);
  canonical `anc check` invocations; "where things live" map.
- [`bin/check-update`](./bin/check-update): periodic version check. Compares local `VERSION` to GitHub `main`, emits
  `UPGRADE_AVAILABLE` so the agent can offer to `git pull`.
- [`spec/`](./spec/): vendored canonical principle text from
  [`agentnative-spec`](https://github.com/brettdavies/agentnative). See [`spec/README.md`](./spec/README.md) for the
  resync procedure. **Do not edit by hand.**
- [`references/`](./references/): implementation guidance: framework idioms (Rust + others), project structure,
  Rust/clap patterns. Used when remediating `anc` findings.
- [`templates/`](./templates/): drop-in starting points for greenfield Rust CLIs (`clap-main.rs`, `error-types.rs`,
  `output-format.rs`, `agents-md-template.md`).

The principles are also published as a stable web reference at [anc.dev/p1](https://anc.dev/p1) through `/p8`.

## Versioning

Tagged releases follow [SemVer](https://semver.org/). The current version lives in [`VERSION`](./VERSION); release notes
are in [`CHANGELOG.md`](./CHANGELOG.md). Each tag has a corresponding GitHub Release with the same notes.

The skill's own version is independent of the spec it vendors. The currently-vendored spec version is in
[`spec/VERSION`](./spec/VERSION).

## Contributing

Issues and PRs welcome. See [`CONTRIBUTING.md`](./CONTRIBUTING.md). Routing:

- **Spec questions or principle proposals** → file in
  [`brettdavies/agentnative`](https://github.com/brettdavies/agentnative) (the spec repo). This skill vendors the spec;
  substantive principle changes happen there first.
- **`anc` bugs or feature requests** → file in
  [`brettdavies/agentnative-cli`](https://github.com/brettdavies/agentnative-cli). The skill teaches `anc` usage but
  doesn't implement the checker.
- **Skill issues** (templates, references, getting-started, layout) → file here.

Branch + release model documented in [`RELEASES.md`](./RELEASES.md).

## Security

See [`SECURITY.md`](./SECURITY.md) for vulnerability disclosure.

## License

Dual-licensed under either of:

- MIT: see [`LICENSE-MIT`](./LICENSE-MIT)
- Apache License, Version 2.0: see [`LICENSE-APACHE`](./LICENSE-APACHE)

at your option. Matches the licensing on `agentnative-cli` so producers can adapt the skill's content into their own
tooling without re-licensing friction.

Vendored spec content under `spec/` is CC BY 4.0 (upstream from
[`brettdavies/agentnative`](https://github.com/brettdavies/agentnative)); attribution is in
[`spec/README.md`](./spec/README.md).
</content>
</invoke>
