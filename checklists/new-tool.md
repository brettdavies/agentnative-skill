# New Agent-Native CLI Tool Checklist

Use this checklist when creating a new Rust CLI tool or retrofitting an existing one for agent-native compliance. Each
item has a concrete verification method — no subjective judgment.

## Phase 0: Prerequisites

- [ ] Rust toolchain installed (`rustc --version`)
- [ ] `cargo init` or existing Cargo project
- [ ] `rg` (ripgrep) installed for compliance checks
- [ ] Read `agent-native-cli/SKILL.md` for principles overview
- [ ] Read `agent-native-cli/references/principles-deep-dive.md` for full specification

## Phase 1: Scaffolding

- [ ] Cargo.toml has `clap` with `derive` and `env` features
- [ ] Cargo.toml has `serde` + `serde_json`
- [ ] Cargo.toml has `thiserror`
- [ ] Cargo.toml has `libc` (for SIGPIPE fix)
- [ ] Cargo.toml has `clap_complete` (for shell completions)
- [ ] Copy `templates/clap-main.rs` structure into `src/main.rs`
- [ ] Copy `templates/error-types.rs` structure into `src/error.rs`
- [ ] Copy `templates/output-format.rs` structure into `src/output.rs`
- [ ] Verify: `cargo check` passes

## Phase 2: Agent-Native Interface

### P1: Non-interactive

- [ ] No `dialoguer`/`inquire`/`read_line` calls without `--no-interactive` guard
- [ ] If CLI has auth, support `--no-browser` for headless auth (RFC 8628 device-code grant)
- [ ] Verify: `rg "dialoguer|inquirer|read_line" --type rust src/` returns 0 matches OR all gated
- [ ] Verify: `rg "no.browser" --type rust src/` returns matches (if auth is present)

### P2: Structured output

- [ ] `OutputFormat` enum with Text/Json/Jsonl variants
- [ ] `OutputConfig` struct threaded through all command handlers
- [ ] `--output text|json|jsonl` global flag with env override
- [ ] Data to stdout, diagnostics to stderr
- [ ] Errors print as JSON when `--output json`
- [ ] Verify: `rg "OutputFormat" --type rust src/` returns matches

### P3: Progressive help

- [ ] Both `after_help` AND `long_about` required (not just one)
- [ ] `after_help` on each subcommand with subcommand-specific examples
- [ ] `--version` via `#[command(version)]`
- [ ] Env vars visible in `--help` output (via `env` attribute)
- [ ] Verify: `rg "long_about" --type rust src/` returns matches
- [ ] Verify: `rg "after_help" --type rust src/` returns matches

### P4: Actionable errors

- [ ] `try_parse()` in main, not `parse()`
- [ ] thiserror error enum (canonical) with `exit_code()` method
- [ ] Exit codes: 0=success, 1=command, 77=auth, 78=config
- [ ] Error messages include: what failed, why, what to do
- [ ] No `process::exit()` outside main
- [ ] Verify: `rg "exit_code" --type rust src/` returns matches

### P5: Safe retries

- [ ] `--dry-run` flag present
- [ ] Destructive operations have `--force`/`--yes` confirmation
- [ ] Idempotent design where possible
- [ ] Verify: `rg "dry.run|force|yes" --type rust src/` returns matches

### P6: Composable structure

- [ ] SIGPIPE fix as first line of main()
- [ ] TTY detection via `std::io::IsTerminal` (canonical, stdlib since Rust 1.70)
- [ ] `NO_COLOR` environment variable respected
- [ ] Shell completions via `clap_complete`
- [ ] Three-tier dependency gating in main()
- [ ] If CLI uses pager: `--no-pager` or PAGER disable mechanism
- [ ] If CLI makes HTTP requests: `--timeout` flag with default (e.g., 30s)
- [ ] All agentic flags (output, quiet, no-interactive, timeout) have `global = true`
- [ ] Verify: `rg "SIGPIPE|SIG_DFL" --type rust src/` returns matches

### P7: Bounded responses

- [ ] `--quiet` flag suppresses diagnostics
- [ ] `diag!` macro for all non-essential output
- [ ] `--limit`/`--max-results` on endpoints returning lists
- [ ] `.clamp()` on pagination values
- [ ] `--timeout` for network operations
- [ ] Verify: `rg "diag!|clamp|suppress_diag" --type rust src/` returns matches

### Code Quality

- [ ] No `println!` outside main.rs (use OutputConfig)
- [ ] No `.unwrap()` in src/ (use `?` or explicit error handling)
- [ ] `env = "TOOL_*"` on all agentic flags
- [ ] `FalseyValueParser::new()` on boolean env var flags
- [ ] Verify: `rg "println!" --type rust src/ --glob '!main.rs'` returns 0 matches
- [ ] Verify: `rg "\.unwrap\(\)" --type rust src/` returns 0 matches
- [ ] Verify: `rg 'env\s*=' --type rust src/` returns matches on all flag definitions
- [ ] Verify: `rg "FalseyValueParser" --type rust src/` returns matches

## Phase 3: Project Structure

- [ ] `AGENTS.md` (plural, canonical) at repo root (copy from `templates/agents-md-template.md`, fill in)
- [ ] Error types in dedicated module (`src/error.rs` or `src/errors/`)
- [ ] Output config in dedicated module (`src/output.rs`)
- [ ] Integration tests using wiremock (API tests) or TestEnv pattern
- [ ] README shows both human and agent usage
- [ ] Verify: `AGENTS.md` exists and has Build, Test, Architecture, Exit Codes sections

## Phase 4: Automated Compliance

- [ ] Run: `agent-native-cli/scripts/check-compliance.sh /path/to/repo`
- [ ] All 24 checks show PASS or acceptable WARN
- [ ] No FAIL results remain
- [ ] Address any WARN items — WARN tier flags non-canonical patterns (e.g., manual Error impl instead of thiserror,
  `is-terminal` crate instead of stdlib `IsTerminal`)
- [ ] Verify: exit code is 0 (all PASS) or 1 (WARNs only, no FAILs)
