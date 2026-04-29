---
name: agent-native-cli
description: >-
  Guide to designing, building, and auditing CLI tools for use by AI agents. Pairs with
  [`anc`](https://github.com/brettdavies/agentnative-cli) (the canonical compliance checker) and
  [`agentnative-spec`](https://github.com/brettdavies/agentnative) (the canonical principle text, vendored at
  `bundle/spec/`). Provides starter templates, language-specific implementation idioms, and a short
  getting-started guide that points agents at `anc check --output json`. Use when designing a new CLI tool,
  reviewing one for agent-readiness, or remediating findings from `anc`. Triggers on agentic CLI, agent-native,
  CLI design, CLI standard, agent-first, CLI for agents, agent-friendly CLI, CLI compliance, anc.
---

# Agent-Native CLI

The standard for CLI tools designed to be operated by AI agents. Three artifacts work together:

| Artifact                                                         | Role                                                                                                                                                                               |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`agentnative-spec`](https://github.com/brettdavies/agentnative) | Canonical text of the seven principles. Frontmatter `requirements[]` is the machine-readable contract. Vendored into [`bundle/spec/`](./spec/) — snapshot refreshed each release.  |
| [`anc`](https://github.com/brettdavies/agentnative-cli)          | The compliance checker. Reads target source/binary, emits a JSON scorecard whose entries cite spec `requirement_id`s. The runtime authority.                                       |
| **This skill** (`agent-native-cli`)                              | The agent-facing guide. Tells the agent how to invoke `anc`, how to navigate the spec when remediating findings, and where the implementation patterns and starter templates live. |

The skill does **not** implement principles checking. `anc` does. The skill teaches agents to use `anc` and supplies the
surrounding context (spec, idioms, templates) that `anc`'s findings reference.

## Update check

On first invocation per session, run `bundle/bin/check-update`. It compares this bundle's `VERSION` against `main` on
GitHub and prints one of:

| Output                               | Meaning                                                                         |
| ------------------------------------ | ------------------------------------------------------------------------------- |
| (empty)                              | Up to date, snoozed, disabled, or check skipped (broken install, no network).   |
| `UPGRADE_AVAILABLE <local> <remote>` | A newer release is on `main`. Surface the upgrade flow below before continuing. |

```bash
bash "$(dirname "$0")/bin/check-update"
```

Exit code is always 0; failures degrade silently.

### Inline upgrade flow

When stdout is `UPGRADE_AVAILABLE <local> <remote>`, ask the user via `AskUserQuestion`:

> `agent-native-cli` **v{remote}** is available (you're on v{local}). Upgrade now?

Three options:

- **"Yes, upgrade now"** — run `git -C <bundle-parent-dir> pull --ff-only`. Report the new HEAD and the upgrade outcome.
  The bundle root is the parent of `bundle/`; `git -C ../.. pull --ff-only` from `bundle/bin/` works for the default
  install layout (`~/<host>/skills/agent-native-cli/`). If `--ff-only` rejects (uncommitted edits or divergent history),
  surface git's error verbatim and stop — do not auto-stash.
- **"Not now"** — write `$HOME/.cache/agent-native-cli/update-snoozed` in the format `<remote> <level> <epoch>`, where
  `<level>` is `1` (24h reminder), `2` (48h), or `3` (7 days), escalating each time the user defers. Tell the user the
  next reminder window.
- **"Never ask again"** — `touch $HOME/.cache/agent-native-cli/disabled` and tell the user how to re-enable (`rm
  $HOME/.cache/agent-native-cli/disabled`).

State directory: `$HOME/.cache/agent-native-cli/`. All three files (`last-update-check`, `update-snoozed`, `disabled`)
live there; the script auto-creates the directory on first slow-path fetch.

## Start here

→ **[`getting-started.md`](./getting-started.md)** — the three working loops (existing CLI / new Rust CLI / other
language), the canonical `anc check` invocations, and a "where things live" map.

## The seven principles

Defined in [`bundle/spec/principles/`](./spec/principles/) (vendored from `agentnative-spec` — currently `v0.2.0`; see
[`bundle/spec/README.md`](./spec/README.md) for resync instructions). One file per principle, each with machine-readable
`requirements[]` frontmatter:

| #   | File                                                                                                                 | Subject                           |
| --- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| P1  | [`p1-non-interactive-by-default.md`](./spec/principles/p1-non-interactive-by-default.md)                             | Non-Interactive by Default        |
| P2  | [`p2-structured-parseable-output.md`](./spec/principles/p2-structured-parseable-output.md)                           | Structured, Parseable Output      |
| P3  | [`p3-progressive-help-discovery.md`](./spec/principles/p3-progressive-help-discovery.md)                             | Progressive Help Discovery        |
| P4  | [`p4-fail-fast-actionable-errors.md`](./spec/principles/p4-fail-fast-actionable-errors.md)                           | Fail Fast, Actionable Errors      |
| P5  | [`p5-safe-retries-mutation-boundaries.md`](./spec/principles/p5-safe-retries-mutation-boundaries.md)                 | Safe Retries, Mutation Boundaries |
| P6  | [`p6-composable-predictable-command-structure.md`](./spec/principles/p6-composable-predictable-command-structure.md) | Composable, Predictable Structure |
| P7  | [`p7-bounded-high-signal-responses.md`](./spec/principles/p7-bounded-high-signal-responses.md)                       | Bounded, High-Signal Responses    |

Do not paraphrase the principles inside this skill — read the spec files directly. They are the source of truth.

## Implementation guidance (when fixing findings)

Once `anc check` reports a failure, the agent has the cited `requirement_id` and the spec text. The next question is
"how do I write code that satisfies this requirement?" — answered by:

| Need                                                    | File                                                                                                 |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Rust/clap-specific patterns per principle               | [`references/rust-clap-patterns.md`](./references/rust-clap-patterns.md)                             |
| General Rust idioms (output, errors, dependency gating) | [`references/framework-idioms.md`](./references/framework-idioms.md)                                 |
| Idioms in Python, Go, JS, Ruby                          | [`references/framework-idioms-other-languages.md`](./references/framework-idioms-other-languages.md) |
| Required project structure (modules, tests, AGENTS.md)  | [`references/project-structure.md`](./references/project-structure.md)                               |

## Starter code

Drop-in starting points for greenfield Rust CLIs. Each encodes the relevant principles by construction.

| File                                                                   | Encodes                                                              |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------- |
| [`templates/clap-main.rs`](./templates/clap-main.rs)                   | `try_parse`, SIGPIPE fix, three-tier dependency gating, global flags |
| [`templates/error-types.rs`](./templates/error-types.rs)               | `thiserror` enum + `exit_code()` mapping                             |
| [`templates/output-format.rs`](./templates/output-format.rs)           | `OutputConfig`, `OutputFormat`, `diag!`, NO_COLOR / IsTerminal       |
| [`templates/agents-md-template.md`](./templates/agents-md-template.md) | Project-level AGENTS.md scaffold                                     |

## Compliance checking

Use `anc`. Install once:

```bash
brew install brettdavies/tap/agentnative   # binary is `anc`
cargo install agentnative
```

Recommended invocations and the full agent loop are in [`getting-started.md`](./getting-started.md). Do not write shell
scripts to grep for principle violations — `anc` already implements (and supersedes) every check that approach could
produce.

## Sources

- [`agentnative-spec`](https://github.com/brettdavies/agentnative) — canonical principle text (CC BY 4.0)
- [`agentnative-cli`](https://github.com/brettdavies/agentnative-cli) — `anc`, the canonical checker (MIT / Apache-2.0)
- [`agentnative-skill`](https://github.com/brettdavies/agentnative-skill) — this repo (MIT)
