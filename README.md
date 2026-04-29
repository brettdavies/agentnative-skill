# agentnative-skill

The producer repo for the [`agent-native-cli`](./bundle/SKILL.md) skill bundle — an agent-facing guide to designing,
building, and auditing CLI tools for use by AI agents.

This skill is the third artifact in a three-repo ecosystem:

| Repo                                                                        | Role                                                           |
| --------------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`agentnative`](https://github.com/brettdavies/agentnative) (the spec)      | Canonical text of the seven principles. CC BY 4.0.             |
| [`agentnative-cli`](https://github.com/brettdavies/agentnative-cli) (`anc`) | The compliance checker. MIT / Apache-2.0.                      |
| **This repo** (`agentnative-skill`)                                         | The agent-facing guide. Vendors the spec; teaches `anc` usage. |

## Repository layout

```text
agentnative-skill/
├── bundle/                 ← THE SKILL — what consumers install
│   ├── SKILL.md            skill metadata + entry-point pointer to getting-started.md
│   ├── getting-started.md  three working loops; canonical anc invocations
│   ├── spec/               vendored from agentnative-spec at a pinned ref (do not edit)
│   ├── references/         implementation guidance: framework idioms, project structure, Rust/clap patterns
│   └── templates/          drop-in starter files (clap-main, error-types, output-format, agents-md-template)
├── scripts/
│   ├── sync-spec.sh        vendor agentnative-spec into bundle/spec/ at a pinned ref
│   └── generate-changelog.sh  release-time CHANGELOG generator (git-cliff + PR-body extraction)
├── docs/plans/             engineering plans (dev-only — guarded out of main)
├── .github/                workflows, rulesets, issue templates, PR template
├── AGENTS.md               project-level agent instructions FOR THIS REPO (not the bundle)
├── CONTRIBUTING.md         how to propose changes
├── RELEASES.md             release procedure (cherry-pick from dev → release/* → main)
├── SECURITY.md             vulnerability disclosure
├── CHANGELOG.md            released versions (generated, never hand-edited)
├── VERSION                 single-line current version
├── cliff.toml              git-cliff configuration
├── LICENSE-MIT             MIT (one half of the dual license)
├── LICENSE-APACHE          Apache 2.0 (the other half)
└── README.md               this file
```

The skill bundle is **`bundle/`**. Everything outside `bundle/` is producer-side ops and **does not ship to consumers**.

## Install

See [anc.dev/skill](https://anc.dev/skill) for the supported hosts (Claude Code, Cursor, Codex, etc.) and the exact
install commands.

The install fetches `bundle/` (only) at a tagged commit SHA into the host's skills directory — for example
`~/.claude/skills/agent-native-cli/`. The installed layout looks like:

```text
~/.claude/skills/agent-native-cli/
├── SKILL.md
├── getting-started.md
├── spec/
├── references/
└── templates/
```

The host auto-discovers `SKILL.md` at the root of the skill directory; `SKILL.md` then points the agent at
`getting-started.md` for progressive disclosure.

## Bundle contents

- [`bundle/SKILL.md`](./bundle/SKILL.md) — skill metadata + entry-point pointer.
- [`bundle/getting-started.md`](./bundle/getting-started.md) — three working loops (existing CLI / new Rust / other
  language); canonical `anc check` invocations; "where things live" map.
- [`bundle/spec/`](./bundle/spec/) — vendored canonical principle text from
  [`agentnative-spec`](https://github.com/brettdavies/agentnative). See
  [`bundle/spec/README.md`](./bundle/spec/README.md) for the pin and resync procedure. **Do not edit by hand.**
- [`bundle/references/`](./bundle/references/) — implementation guidance: framework idioms (Rust + others), project
  structure, Rust/clap patterns. Used when remediating `anc` findings.
- [`bundle/templates/`](./bundle/templates/) — drop-in starting points for greenfield Rust CLIs (`clap-main.rs`,
  `error-types.rs`, `output-format.rs`, `agents-md-template.md`).

The principles are also published as a stable web reference at [anc.dev/p1](https://anc.dev/p1) through `/p7`.

## Versioning

Tagged releases follow [SemVer](https://semver.org/). The current version lives in [`VERSION`](./VERSION); release notes
are in [`CHANGELOG.md`](./CHANGELOG.md). Each tag has a corresponding GitHub Release with the same notes.

The skill's own version is independent of the spec it vendors. The currently-pinned spec version is in
[`bundle/spec/VERSION`](./bundle/spec/VERSION).

## Contributing

Issues and PRs welcome — see [`CONTRIBUTING.md`](./CONTRIBUTING.md). Routing:

- **Spec questions or principle proposals** → file in
  [`brettdavies/agentnative`](https://github.com/brettdavies/agentnative) (the spec repo). This skill vendors the spec;
  substantive principle changes happen there first.
- **`anc` bugs or feature requests** → file in
  [`brettdavies/agentnative-cli`](https://github.com/brettdavies/agentnative-cli). The skill teaches `anc` usage but
  doesn't implement the checker.
- **Skill-bundle issues** (templates, references, getting-started, layout) → file here.

Branch + release model documented in [`RELEASES.md`](./RELEASES.md).

## Security

See [`SECURITY.md`](./SECURITY.md) for vulnerability disclosure.

## License

Dual-licensed under either of:

- MIT — see [`LICENSE-MIT`](./LICENSE-MIT)
- Apache License, Version 2.0 — see [`LICENSE-APACHE`](./LICENSE-APACHE)

at your option. Matches the licensing on `agentnative-cli` so producers can adapt the bundle's check scripts into their
own tooling without re-licensing friction.

Vendored spec content under `bundle/spec/` is CC BY 4.0 (upstream from
[`brettdavies/agentnative`](https://github.com/brettdavies/agentnative)); attribution is in
[`bundle/spec/README.md`](./bundle/spec/README.md).
