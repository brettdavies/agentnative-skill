# agentnative-skill

The producer repo for the [`agent-native-cli`](./bundle/SKILL.md) skill bundle — a north-star standard for CLI tools
designed to be operated by AI agents.

## Repository layout

```text
agentnative-skill/
├── bundle/             ← THE SKILL — what consumers install
│   ├── SKILL.md        skill metadata + the standard itself
│   ├── checklists/     task-shaped checklists (new-tool.md)
│   ├── references/     deep-dive specs, framework idioms, project structure
│   ├── scripts/        compliance checker + 24 individual checks
│   └── templates/      drop-in starter files (AGENTS, clap-main, error-types, output-format)
├── docs/plans/         engineering plans (dev-only — guarded out of main)
├── .github/            workflows, rulesets, issue templates, PR template
├── AGENTS.md           project-level agent instructions FOR THIS REPO (not the bundle)
├── CONTRIBUTING.md     how to propose changes
├── RELEASES.md         release procedure (cherry-pick from dev → release/* → main)
├── SECURITY.md         vulnerability disclosure
├── CHANGELOG.md        released versions
├── VERSION             single-line current version
├── LICENSE             MIT
└── README.md           this file
```

The skill bundle is **`bundle/`**. Everything outside `bundle/` is producer-side ops and **does not ship to consumers**.

## Install

See [anc.dev/install](https://anc.dev/install) for the supported hosts (Claude Code, Cursor, Codex, etc.) and the exact
install commands.

The install fetches `bundle/` (only) at a tagged commit SHA into the host's skills directory — for example
`~/.claude/skills/agent-native-cli/`. The installed layout looks like:

```text
~/.claude/skills/agent-native-cli/
├── SKILL.md
├── checklists/
├── references/
├── scripts/
└── templates/
```

The host then auto-discovers `SKILL.md` at the root of the skill directory.

## Bundle contents

- [`bundle/SKILL.md`](./bundle/SKILL.md) — the standard itself: 7 agent-readiness principles, when to trigger, how to
  use.
- [`bundle/checklists/`](./bundle/checklists/) — task-shaped checklists (e.g., starting a new tool).
- [`bundle/references/`](./bundle/references/) — deep-dive references: principle specifications, framework idioms,
  project structure, Rust/clap patterns.
- [`bundle/scripts/`](./bundle/scripts/) — automated compliance checker (`check-compliance.sh`) plus 24 individual
  checks across 9 groups under `bundle/scripts/checks/`.
- [`bundle/templates/`](./bundle/templates/) — drop-in starting points (`agents-md-template.md`, clap main, error types,
  output format).

The principles are also published as a stable web reference at [anc.dev/p1](https://anc.dev/p1) through `/p7`.

## Versioning

Tagged releases follow [SemVer](https://semver.org/). The current version lives in [`VERSION`](./VERSION); release notes
are in [`CHANGELOG.md`](./CHANGELOG.md). Each tag has a corresponding GitHub Release with the same notes.

## Contributing

Issues and PRs welcome — see [`CONTRIBUTING.md`](./CONTRIBUTING.md). The bundle's content is the authoritative source of
truth for what "agent-native CLI" means in this ecosystem; substantive proposals should engage with the principles in
[`bundle/SKILL.md`](./bundle/SKILL.md) and
[`bundle/references/principles-deep-dive.md`](./bundle/references/principles-deep-dive.md).

Branch + release model documented in [`RELEASES.md`](./RELEASES.md).

## Security

See [`SECURITY.md`](./SECURITY.md) for vulnerability disclosure.

## License

MIT — see [`LICENSE`](./LICENSE).
