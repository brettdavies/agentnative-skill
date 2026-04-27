---
name: agent-native-cli
description: >-
  North-star standard for agent-native CLI tools. Defines 7 agent-readiness principles (non-interactive, structured
  output, progressive help, actionable errors, safe retries, composable structure, bounded responses), Rust/clap
  implementation patterns, project structure requirements, and an automated compliance checker (24 checks across 9
  groups). Use when designing a new CLI tool, reviewing an existing tool for agent-readiness, or running compliance
  checks. Triggers on agentic CLI, agent-native, CLI design, CLI standard, agent-first, CLI for agents, agent-friendly
  CLI, CLI compliance.
---

# Agent-Native CLI Standard

The north-star standard for CLI tools designed to be operated by AI agents. Defines what an agent-native CLI must look
like — from interface design through project structure — and provides an automated compliance checker that produces
deterministic pass/warn/fail scorecards (24 checks across 9 groups).

This skill is **prescriptive** ("what to build"). Its complement, the `cli-agent-readiness-reviewer` agent, is
**evaluative** ("how well did you build it"). For release infrastructure (CI/CD, distribution, Homebrew), see the
`rust-tool-release` skill.

## The 7 Principles

Every agent-native CLI tool must satisfy these seven principles. Each principle below gives the key requirements; for
full MUST/SHOULD/MAY specifications, see `references/principles-deep-dive.md`.

### P1: Non-Interactive by Default

All automation paths work without human input. Interactive prompts (dialoguer, inquire) are gated behind a
`--no-interactive` flag. Every flag has an env var override via clap's `env` attribute for scriptability.

**Key requirements:**

- No interactive prompts on the default code path
- `--no-interactive` global flag if any prompt exists
- Boolean env vars use `FalseyValueParser` so `TOOL_QUIET=0` correctly disables
- If the CLI has auth, it MUST support headless auth via `--no-browser` (canonical flag name, RFC 8628 device
  authorization grant). Agents cannot open browsers for OAuth.

### P2: Structured, Parseable Output

Agents consume output programmatically. Data goes to stdout, diagnostics to stderr. Output format is selectable.

**Key requirements:**

- `--output text|json|jsonl` global flag with env override
- `OutputConfig` struct threaded through all command handlers — never naked `println!`
- Errors print as structured JSON when `--output json`
- Exit codes are structured: 0=success, 1=command error, 77=auth, 78=config

See `templates/output-format.rs` and `templates/error-types.rs` for canonical implementations.

### P3: Progressive Help Discovery

Agents scan help text to learn how to use a tool. Examples must be findable after the flags section.

**Key requirements:**

- Both `after_help` AND `long_about` are required (not just one) — `after_help` for examples, `long_about` for extended
  description
- `about` alone is insufficient — agents scan past flags to find examples in `after_help`
- Env vars visible in `--help` output via clap's `env` attribute
- `--version` flag MUST be present (clap `#[command(version)]`)

### P4: Fail Fast with Actionable Errors

When something goes wrong, agents need structured error output to decide their next action.

**Key requirements:**

- `try_parse()` not `parse()` — parse() calls `process::exit()`, bypassing custom error handlers
- Structured error enum with `exit_code()` mapping (agents parse exit codes to decide: retry, re-auth, or report)
- Error messages include: what failed, why, and what to do next
- No `process::exit()` outside of main()

See `templates/clap-main.rs` for the try_parse pattern and `templates/error-types.rs` for structured errors.

### P5: Safe Retries and Explicit Mutation Boundaries

Agents retry commands. Every CLI MUST support `--dry-run` regardless of command type — agents need a safe way to verify
behavior before committing to actions.

**Key requirements:**

- `--dry-run` MUST be supported on all CLIs (not just write-heavy ones)
- Destructive operations MUST require `--force` or `--yes`
- Idempotent design where possible

### P6: Composable and Predictable Structure

Agents pipe, redirect, and compose CLI tools. The tool must behave predictably in pipelines.

**Key requirements:**

- SIGPIPE fix as first line of `main()` (prevents panics when piping to `head`)
- TTY detection via `std::io::IsTerminal` respecting `NO_COLOR` and `TERM=dumb`
- Shell completions via `clap_complete`
- `--no-pager` or pager disable mechanism if the CLI uses a pager
- `--timeout` for network CLIs
- `global = true` on all agentic flags (`--output`, `--quiet`, `--dry-run`, `--no-interactive`) when subcommands are
  used
- Three-tier dependency gating: meta-commands (no deps) -> local commands (config only) -> network commands (auth
  required)

**Flags vs. subcommands guidance:** Use subcommands for distinct operations (`list`, `get`, `delete`), flags for
modifiers (`--output`, `--limit`), and global flags for cross-cutting concerns (`--quiet`, `--dry-run`, `--output`).

See `templates/clap-main.rs` for the three-tier pattern.

### P7: Bounded, High-Signal Responses

Agents have finite context windows. Output must be controllable and bounded.

**Key requirements:**

- `--quiet` flag suppresses non-essential output (diagnostics, progress)
- `diag!` macro gates all non-essential stderr output
- `--limit`/`--max-results` on endpoints returning lists
- `.clamp()` on pagination values to prevent runaway responses

See `templates/output-format.rs` for the diag! macro and OutputConfig patterns.

## Project Structure Requirements

Beyond the CLI interface, agent-native tools need proper project structure. See `references/project-structure.md` for
full details.

**Required:**

- `AGENTS.md` at repo root — build commands, test commands, architecture, exit codes, conventions
- Error types in a dedicated module with exit code mapping
- Output config in a dedicated module with format-aware printing
- Integration tests using wiremock (API mocking) and TestEnv pattern (XDG isolation)
- README showing both human and agent usage

See `templates/agents-md-template.md` for the AGENTS.md template.

## What Would You Like to Do?

| Intent | Resource |
| ------ | -------- |
| Design a new CLI tool from scratch | `checklists/new-tool.md` |
| Understand the 7 principles in depth | `references/principles-deep-dive.md` |
| Implement principles in Rust/clap | `references/rust-clap-patterns.md` |
| Set up project structure | `references/project-structure.md` |
| Get Rust/clap framework idioms | `references/framework-idioms.md` |
| Get idioms for other languages | `references/framework-idioms-other-languages.md` |
| Run compliance checks on a repo | See "Compliance Checker" below |
| Copy template files into a new project | `templates/` directory |

## Compliance Checker

The automated compliance checker scans a Rust CLI repo using static analysis (rg patterns) and produces a deterministic
scorecard. 24 checks across 9 groups: P1-P7 (one group per principle), Code Quality, and Project Structure.

### Run all checks

```text
agent-native-cli/scripts/check-compliance.sh /path/to/repo
```

### Run a single principle

```text
agent-native-cli/scripts/check-compliance.sh /path/to/repo --principle 3
```

### Interpret results

Each check gets PASS, WARN, or FAIL with evidence. Results are grouped by section.

**Exit codes:**

- 0 = all PASS
- 1 = any WARN, no FAIL (acceptable for most tools)
- 2 = any FAIL (action needed)

**Example scorecard:**

```text
╔══════════════════════════════════════════════════════════╗
║  Agent-Native CLI Compliance — bird
╚══════════════════════════════════════════════════════════╝

  P1: Non-Interactive
  ──────────────────────────────────────────────────────
  WARN  Headless auth            Auth delegated to subprocess
  PASS  Non-interactive          No interactive prompts found

  P2: Structured Output
  ──────────────────────────────────────────────────────
  PASS  Structured output        OutputFormat enum + serde_json present

  P3: Progressive Help
  ──────────────────────────────────────────────────────
  FAIL  Progressive help         No after_help or long_about
  PASS  Version flag             #[command(version)] found

  P4: Actionable Errors
  ──────────────────────────────────────────────────────
  WARN  Error types              Manual Error impl — migrate to thiserror
  PASS  Exit codes               Named exit code constants found
  PASS  No process::exit leaks   Confined to main.rs
  WARN  try_parse                from_arg_matches() — migrate to try_parse()

  P5: Safe Retries
  ──────────────────────────────────────────────────────
  WARN  Safe retries (--dry-run) Write commands present without --dry-run

  P6: Composable Structure
  ──────────────────────────────────────────────────────
  PASS  Shell completions        clap_complete found in Cargo.toml
  PASS  Global flags             global = true on agentic flags
  PASS  NO_COLOR support         NO_COLOR env check found
  PASS  No pager blocking        No pager invocation found
  PASS  SIGPIPE fix              reset_sigpipe() found in main
  FAIL  Network timeout          No --timeout flag found
  PASS  TTY detection            IsTerminal trait found

  P7: Bounded Responses
  ──────────────────────────────────────────────────────
  PASS  Output clamping          .clamp() found on pagination
  PASS  Quiet flag               --quiet flag found

  Code Quality
  ──────────────────────────────────────────────────────
  PASS  Env flag overrides       env = attributes found on flags
  FAIL  No naked println!        println! found outside output module
  PASS  No unwrap() in prod      No unwrap() in src/ (excluding tests)

  Project Structure
  ──────────────────────────────────────────────────────
  PASS  AGENTS.md                AGENTS.md found at repo root
  PASS  Dependencies             Required crates present

════════════════════════════════════════════════════════════
  Score: 18/24 PASS, 3 WARN, 3 FAIL
```

### Adding new checks

Drop a new `check-*.sh` script in `scripts/checks/`. Follow the output protocol: emit one line
`STATUS|LABEL|EVIDENCE` to stdout, exit 0/1/2. Name checks with a group prefix — `check-p1-*`, `check-p4-*`,
`check-code-*`, `check-project-*` — the orchestrator groups them automatically by prefix. The orchestrator
auto-discovers new checks via glob.

## Reference Index

**Principles:** `references/principles-deep-dive.md` — full MUST/SHOULD/MAY specification for all 7 principles

**Implementation:**

- `references/rust-clap-patterns.md` — Rust/clap-specific implementation guidance per principle
- `references/project-structure.md` — required files and project layout
- `references/framework-idioms.md` — Rust/clap idioms (primary)
- `references/framework-idioms-other-languages.md` — Click, argparse, Cobra, Commander, yargs, oclif, Thor

**Templates:** `templates/clap-main.rs`, `templates/error-types.rs`, `templates/output-format.rs`,
`templates/agents-md-template.md`

**Checklists:** `checklists/new-tool.md` — phased checklist for new tool creation or retrofit

**Scripts:** `scripts/check-compliance.sh` (orchestrator), `scripts/checks/` (individual checks)

## Sources

- Eric Zakariasson, "Building CLIs for agents" — concise overview of agent-friendly CLI patterns
- `cli-agent-readiness-reviewer` agent (compound-engineering plugin) — evaluative 7-principle rubric
- Institutional learnings from bird and xurl-rs in `docs/solutions/` — battle-tested patterns
- "The Emerging Harness Engineering" (ignorance.ai) — AGENTS.md as living doc, architecture as guardrails
