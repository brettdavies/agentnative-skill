# agentnative-skill

The producer repo for the [`agent-native-cli`](./SKILL.md) skill bundle — a north-star standard for CLI tools designed
to be operated by AI agents.

This repo ships the bundle at the root so that `git clone` directly into a host's skills directory IS install.

## Install

See [anc.dev/install](https://anc.dev/install) for the cloned-in-place install model and supported hosts (Claude Code,
Cursor, Codex, etc.).

## What's inside

- [`SKILL.md`](./SKILL.md) — the standard itself: 7 agent-readiness principles, when to trigger, how to use.
- [`checklists/`](./checklists/) — task-shaped checklists (e.g., starting a new tool).
- [`references/`](./references/) — deep-dive references: principle specifications, framework idioms, project structure,
  Rust/clap patterns.
- [`scripts/`](./scripts/) — automated compliance checker (`check-compliance.sh`) plus 24 individual checks across 9
  groups under `scripts/checks/`.
- [`templates/`](./templates/) — drop-in starting points (`AGENTS.md`, clap main, error types, output format).

The principles are also published as a stable web reference at [anc.dev/p1](https://anc.dev/p1) through `/p7`.

## Versioning

Tagged releases follow [SemVer](https://semver.org/). The current version lives in [`VERSION`](./VERSION); release notes
are in [`CHANGELOG.md`](./CHANGELOG.md).

## Contributing

Issues and PRs welcome. The bundle's content is the authoritative source of truth for what "agent-native CLI" means in
this ecosystem — substantive proposals should engage with the principles in [`SKILL.md`](./SKILL.md) and
[`references/principles-deep-dive.md`](./references/principles-deep-dive.md).

Branch model: `feat/*` off `dev`, squash-merged back to `dev`; `dev` → `main` PRs cut releases.

## Security

See [`SECURITY.md`](./SECURITY.md) for vulnerability disclosure.

## License

MIT — see [`LICENSE`](./LICENSE).
