---
name: agent-native-cli
description: >-
  Guide to designing, building, and auditing CLI tools for use by AI agents. Pairs with
  [`anc`](https://github.com/brettdavies/agentnative-cli) (the canonical compliance checker) and
  [`agentnative-spec`](https://github.com/brettdavies/agentnative) (the canonical principle text, vendored at
  `spec/`). Provides starter templates, language-specific implementation idioms (Rust/clap, Python Click & argparse,
  Go Cobra, JS Commander/yargs/oclif, Ruby Thor), and a getting-started guide that points agents at
  `anc check --output json` and `anc skill install <host>`. Use when designing a new CLI tool, building a Rust/clap
  binary intended for agents, reviewing one for agent-readiness, claiming the agent-native badge, or remediating
  findings from `anc`. Triggers on agentic CLI, agent-native, CLI design, CLI standard, agent-first, CLI for agents,
  agent-friendly CLI, CLI compliance, agent-readiness, anc, anc check, anc skill install, agent-native badge,
  scorecard, audit-profile, Rust CLI, clap derive. SKIP when the user is building a TUI app meant for humans (use
  `--audit-profile human-tui` rather than this skill), writing a non-CLI library, or asking unrelated Rust questions
  not specifically about agent-readiness of a CLI.
---

# Agent-Native CLI

The standard for CLI tools designed to be operated by AI agents. Three artifacts work together:

| Artifact                                                         | Role                                                                                                                                                                               |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`agentnative-spec`](https://github.com/brettdavies/agentnative) | Canonical text of the seven principles. Frontmatter `requirements[]` is the machine-readable contract. Vendored into [`spec/`](./spec/) — snapshot refreshed each release.         |
| [`anc`](https://github.com/brettdavies/agentnative-cli)          | The compliance checker. Reads target source/binary, emits a JSON scorecard whose entries cite spec `requirement_id`s. The runtime authority.                                       |
| **This skill** (`agent-native-cli`)                              | The agent-facing guide. Tells the agent how to invoke `anc`, how to navigate the spec when remediating findings, and where the implementation patterns and starter templates live. |

The skill does **not** implement principles checking. `anc` does. The skill teaches agents to use `anc` and supplies the
surrounding context (spec, idioms, templates) that `anc`'s findings reference.

## First action: update check

Run once per session before doing real work:

```bash
bash "$(dirname "$0")/bin/check-update"
```

Empty output → continue. `UPGRADE_AVAILABLE <local> <remote>` → prompt the user via `AskUserQuestion` (Yes / Not now /
Never). Full prompt text, snooze ladder, and state-file layout are in
[`references/update-check.md`](./references/update-check.md). Exit code is always `0`; failures degrade silently.

## Start here

→ **[`getting-started.md`](./getting-started.md)** — the three working loops (existing CLI / new Rust CLI / other
language), the canonical `anc check` invocations, the `anc skill install <host>` installer, and a "where things live"
map.

## The seven principles

Defined in [`spec/principles/`](./spec/principles/) (vendored from `agentnative-spec` — currently `v0.3.0`; see
[`spec/README.md`](./spec/README.md) for resync instructions). One file per principle, each with machine-readable
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

## The anc loop: check → fix → re-check → claim badge

Once `anc` is installed (one-line install in [`getting-started.md`](./getting-started.md)), the work is a four-step
loop:

**1. Check.** `anc check --output json . > scorecard.json`. The JSON envelope is schema `0.5` and contains:

- `summary` — `total / pass / warn / fail / skip / error` count.
- `coverage_summary` — `must / should / may`, each with `total` + `verified`. `must.verified == must.total` is the bar
  for "no MUST violations".
- `badge.eligible` (bool), `badge.score_pct` (int), `badge.embed_markdown` (string or `null`), `badge.scorecard_url`,
  `badge.badge_url`, `badge.convention_url`. **80%** is the eligibility floor; below it, `embed_markdown` is `null` and
  the convention says do not advertise a badge.
- `results[]` — per-check entries citing `requirement_id`, `status`, and `evidence`.
- `audit_profile` — the exemption category in effect (or `null`).
- `tool / anc / run / target` metadata — identifies the scored tool, the `anc` build, the invocation, and the resolved
  target.

**2. Fix.** For each `fail`, look up the cited `requirement_id` (e.g. `p1-must-no-interactive`) in
`spec/principles/p<N>-*.md`'s `requirements[]` frontmatter. Apply the fix using the implementation references below.
Re-run with `--principle <N>` to focus on one principle while iterating.

**3. Re-check.** Re-run `anc check --output json .` until `summary.fail == 0` and `coverage_summary.must.verified ==
coverage_summary.must.total`. Use `--audit-profile <category>` to suppress checks that don't apply to the tool class —
`human-tui` (TUIs that legitimately intercept the TTY), `file-traversal` (reserved), `posix-utility` (cat / sed / awk
style), `diagnostic-only` (read-only tools). Suppressed checks emit `Skip` with structured evidence so readers see what
was excluded.

**4. Claim the badge.** Once `badge.eligible == true` (≥80%), copy `badge.embed_markdown` into the project's README. The
`text` output appends an embed hint after the summary line whenever the floor is cleared; below the floor, nothing
badge-related is printed (the convention's "do not nag" rule).

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

Use `anc`. Install once via Homebrew, cargo, or self-install:

```bash
brew install brettdavies/tap/agentnative   # binary is `anc`
cargo install agentnative
```

To install **this skill bundle** into a host's canonical skills directory, use `anc`'s built-in installer:

```bash
anc skill install claude_code              # also: codex, cursor, factory, kiro, opencode
anc skill install --dry-run claude_code    # print resolved git command without spawning
```

Recommended `anc check` invocations and the full agent loop are in [`getting-started.md`](./getting-started.md). Do not
write shell scripts to grep for principle violations — `anc` already implements (and supersedes) every check that
approach could produce.

## Sources

- [`agentnative-spec`](https://github.com/brettdavies/agentnative) — canonical principle text (CC BY 4.0)
- [`agentnative-cli`](https://github.com/brettdavies/agentnative-cli) — `anc`, the canonical checker (MIT / Apache-2.0)
- [`agentnative-skill`](https://github.com/brettdavies/agentnative-skill) — this repo (MIT)
