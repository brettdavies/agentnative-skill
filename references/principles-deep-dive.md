# Agent-Readiness Principles: Deep Dive

This reference is the full specification for the 7 agent-readiness principles that define an agent-native CLI tool. Each
principle includes a definition, the cost of violation, tiered requirements using RFC 2119 language (MUST/SHOULD/MAY),
evidence patterns for code review, and anti-patterns to reject. For Rust/clap implementation details, see the template
files referenced within each principle.

---

## P1: Non-Interactive by Default

### Definition

All automation paths MUST work without human input. A CLI tool that blocks on a TTY prompt is invisible to an agent —
the agent hangs, the user sees nothing, and the operation times out silently.

### Why Agents Need It

When a tool prompts for confirmation or credentials interactively, an agent cannot respond. The agent's process stalls
until timeout, wasting tokens and wall-clock time. Worse, the agent has no structured signal that interaction was
requested — it cannot distinguish "waiting for input" from "still processing." Interactive prompts in automation paths
are the single most common cause of agent-tool deadlocks.

### Requirements

**MUST:**

- All flags MUST be settable via environment variables. Use `FalseyValueParser` for boolean env vars so that
  `TOOL_QUIET=0` correctly disables the flag rather than treating any non-empty value as truthy. See
  `templates/output-format.rs` for the canonical pattern.
- Tools that include any interactive prompts (dialoguer, inquire, `read_line`) MUST gate them behind a
  `--no-interactive` flag. When `--no-interactive` is set or the env var equivalent is truthy, the tool MUST either use
  defaults, read from stdin, or fail with an actionable error — never block.
- If the CLI includes authentication (OAuth, token management, credential flows), it MUST support a headless auth path.
  The canonical flag is `--no-browser`, which triggers the OAuth 2.0 Device Authorization Grant (RFC 8628) — the CLI
  prints a URL and code, the user authorizes on another device. Agents cannot open browsers. Non-canonical alternatives
  (`--device-code`, `--remote`, `--headless`) are acceptable but should be migrated to `--no-browser`.

**SHOULD:**

- Tools SHOULD auto-detect non-interactive contexts via TTY detection (`IsTerminal`) and suppress prompts when stderr is
  not a terminal, even without an explicit `--no-interactive` flag.
- Default values for prompted inputs SHOULD be documented in `--help` output so agents can pass them explicitly.

**MAY:**

- Tools MAY offer rich interactive experiences (spinners, progress bars, multi-select menus) when a TTY is detected and
  `--no-interactive` is not set, provided the non-interactive path remains fully functional.

### Evidence Patterns

- `--no-interactive` flag definition in the CLI struct with an env var binding
- `FalseyValueParser::new()` on all boolean flags that have env var overrides
- TTY guard wrapping any `dialoguer` or `inquire` call
- Every flag has a corresponding `env = "TOOL_..."` attribute
- `--no-browser` flag definition for headless/device-code authentication

### Anti-Patterns

- Bare `dialoguer::Confirm::new().interact()` without a `--no-interactive` check
- Boolean env var flags using clap's default string parser (where `TOOL_QUIET=false` is truthy because it is non-empty)
- `stdin().read_line()` in a code path reachable during normal operation without a TTY check
- Hard-coded credentials prompts with no env var or config file alternative
- OAuth flow that unconditionally opens a browser with no headless escape hatch

---

## P2: Structured, Parseable Output

### Definition

Tools MUST separate data from diagnostics and offer machine-readable output formats. Agents parse stdout
programmatically — mixing status messages with data forces fragile regex extraction that breaks on any format change.

### Why Agents Need It

An agent calling a CLI tool needs three things: the data, the error (if any), and the exit code. When data goes to
stdout, diagnostics go to stderr, and errors include machine-readable fields, the agent can parse output reliably
without heuristics. When these channels are mixed or output is human-formatted only, the agent must resort to
best-effort text parsing that fails unpredictably across versions, locales, and edge cases.

### Requirements

**MUST:**

- Tools MUST support `--output text|json|jsonl` for selecting the output format. Text is the default for human use; JSON
  and JSONL are the agent-facing formats. See `templates/output-format.rs` for the `OutputFormat` enum and
  `OutputConfig` struct.
- Data MUST go to stdout. Diagnostics, progress indicators, and warnings MUST go to stderr. An agent consuming JSON from
  stdout must never encounter an interleaved progress message.
- Exit codes MUST be structured and documented: 0 for success, 1 for general command errors, 2 for usage errors (bad
  arguments), 77 for authentication/permission errors, 78 for configuration errors. See `templates/error-types.rs` for
  the canonical exit code mapping.
- When `--output json` is active, errors MUST also be emitted as JSON (to stderr) with at minimum `error`, `kind`, and
  `message` fields. See `templates/error-types.rs` for the `print()` method that respects `OutputConfig`.

**SHOULD:**

- The `OutputConfig` struct SHOULD be threaded through the entire call stack so that every function producing output
  respects the chosen format. Naked `println!` calls bypass format selection and leak unstructured text into stdout.
- JSON output SHOULD include a consistent envelope: a top-level object with predictable keys that agents can rely on
  across commands.

**MAY:**

- Tools MAY support additional output formats (CSV, TSV, YAML) beyond the core three, as long as the core three are
  always available.
- Tools MAY include a `--raw` flag for unformatted output suitable for piping to other tools.

### Evidence Patterns

- `OutputFormat` enum with `Text`, `Json`, `Jsonl` variants deriving `ValueEnum`
- `OutputConfig` struct with `format`, `use_color`, and `quiet` fields
- `serde_json` in `Cargo.toml` dependencies
- No `println!` in `src/` outside of the output module (all output goes through `OutputConfig`)
- Exit code constants or match arms mapping error variants to distinct numeric codes
- `eprintln!` (or `diag!` macro) for all diagnostic output

### Anti-Patterns

- `println!` scattered across command handlers instead of routing through `OutputConfig`
- A single exit code (1) for all error types — agents cannot distinguish auth failures from config errors
- Status messages ("Fetching data...") printed to stdout where they contaminate JSON output
- `process::exit()` calls in library code that bypass structured error propagation
- Human-formatted tables as the only output mode with no JSON alternative

---

## P3: Progressive Help Discovery

### Definition

Help text MUST be layered so agents (and humans) can drill from a short summary to detailed usage examples without
reading the entire manual. The critical layer is `after_help` — the section that appears after the flags list — because
that is where agents look for concrete invocation patterns.

### Why Agents Need It

Agents discover how to use a tool by calling `--help` and scanning the output. They skip past flag definitions (which
describe what is possible) and look for examples (which describe what to do). Clap's `about` and `long_about` attributes
populate the description above the flags list — useful for orientation, but insufficient for invocation guidance. The
`after_help` attribute populates the section below the flags list, which is where usage examples belong. Without
`after_help`, an agent sees flags but no examples of how to combine them, leading to trial-and-error invocations that
waste tokens and often fail.

### Requirements

**MUST:**

- Every subcommand MUST have an `after_help` (or `after_long_help`) attribute containing at least one concrete
  invocation example showing the command with realistic arguments.
- The top-level command MUST have `after_help` showing the most common workflows (2-3 examples covering the primary use
  cases).

**SHOULD:**

- Examples in `after_help` SHOULD show both human and agent invocations side by side (e.g., a text-output example
  followed by its `--output json` equivalent).
- Help text SHOULD use short `about` for command list summaries and reserve `long_about` for detailed descriptions that
  appear with `--help` but not `-h`.

**MAY:**

- Tools MAY include a dedicated `examples` subcommand or `--examples` flag that outputs a curated set of usage patterns
  for agent consumption.

### Evidence Patterns

- `after_help` or `after_long_help` attribute on the top-level `Parser` struct
- `after_help` or `after_long_help` attribute on each subcommand enum variant or struct
- Example invocations in `after_help` text that include realistic arguments
- Both `about` (short) and `after_help` (examples) present on subcommands

### Anti-Patterns

- Relying solely on doc comments (`///`) which only populate `about` and `long_about` — no examples appear after the
  flags section
- A single `about` string serving as both summary and usage documentation
- Examples buried in a README or man page but absent from `--help` output
- `after_help` containing only prose descriptions without concrete invocation examples

---

## P4: Fail Fast with Actionable Errors

### Definition

Tools MUST detect invalid state early, exit with a structured error, and tell the caller what failed, why, and what to
do next. An error message that says "operation failed" gives the agent nothing to act on.

### Why Agents Need It

Agents operate in a retry loop: attempt, observe result, decide next action. When an error is vague ("something went
wrong") or unstructured (a stack trace on stdout), the agent cannot determine whether to retry, re-authenticate, fix
configuration, or escalate to the user. Structured errors with distinct exit codes and actionable messages let agents
make correct decisions immediately. The difference between exit code 77 (re-authenticate) and exit code 78 (fix config)
determines whether the agent retries OAuth or asks the user to check their config file — getting this wrong wastes
entire conversation turns.

### Requirements

**MUST:**

- Tools MUST use `try_parse()` instead of `parse()` for CLI argument parsing. Clap's `parse()` calls `process::exit()`
  directly, bypassing any custom error handler. When an agent passes `--output json`, it expects parse errors in JSON —
  `parse()` makes that impossible. See `templates/clap-main.rs` for the canonical pattern.
- Error types MUST map to distinct exit codes. At minimum: 0 (success), 1 (command error), 2 (usage/argument error), 77
  (auth/permission), 78 (configuration). See `templates/error-types.rs` for the `AppError` enum with `exit_code()`
  method.
- Every error message MUST include three components: what failed (the operation), why it failed (the cause), and what to
  do next (the remediation). Example: "Authentication failed: token expired (expires_at: 2026-03-25T00:00:00Z). Run
  `tool auth refresh` or set TOOL_TOKEN."

**SHOULD:**

- Error types SHOULD use a structured enum (via `thiserror`) with variant-to-kind mapping for JSON serialization, so
  agents can match on error kinds programmatically rather than parsing message text.
- Config and auth validation SHOULD happen before any network call or expensive operation. The three-tier dependency
  gating pattern (meta commands, local commands, network commands) ensures the tool fails at the earliest possible
  point. See `templates/clap-main.rs` for the tiered structure.
- Error output SHOULD respect `--output json` by emitting JSON-formatted errors to stderr when JSON output is selected.

### Evidence Patterns

- `Cli::try_parse()` in `main()` instead of `Cli::parse()`
- Error enum with `#[derive(Error)]` and distinct variants for config, auth, and command errors
- `exit_code()` method on the error type returning variant-specific codes
- `kind()` method returning a machine-readable string for JSON serialization
- `run()` function returning `Result<(), AppError>` (not calling `process::exit()` internally)
- Error messages containing remediation steps ("run X" or "set Y")

### Anti-Patterns

- `Cli::parse()` anywhere in the codebase — it silently prevents JSON error output
- `process::exit()` in library code or command handlers (only acceptable in `main()` after all error handling)
- A single catch-all error variant that maps everything to exit code 1
- Error messages that state the symptom without the cause or fix: "Error: request failed"
- Panics (`unwrap()`, `expect()`) on recoverable errors in production code paths

---

## P5: Safe Retries and Explicit Mutation Boundaries

### Definition

Every CLI MUST support `--dry-run` so agents can preview the effect of any command before committing. Write operations
MUST clearly separate destructive actions from read-only queries. An agent that cannot distinguish a safe read from a
dangerous write will either avoid the tool entirely or execute mutations blindly.

### Why Agents Need It

Agents retry failed operations by default. If a write operation is not idempotent, retrying it may create duplicates,
corrupt data, or trigger rate limits. When destructive operations require explicit confirmation (`--force`, `--yes`) and
support preview (`--dry-run`), agents can safely explore what a command would do before committing to it. Read-only
tools are inherently safe for retries, but they still benefit from clear documentation that no mutation occurs.

### Requirements

**MUST:**

- Destructive operations (delete, overwrite, bulk modify) MUST require an explicit `--force` or `--yes` flag. Without
  the flag, the tool MUST either refuse the operation or enter dry-run mode.
- The distinction between read and write commands MUST be clear from the command name and help text. An agent reading
  `--help` output should immediately know whether a command mutates state.
- All CLIs MUST support a `--dry-run` flag. When set, commands validate inputs and report what they would do without
  executing mutations. The output format MUST respect `--output json` so agents can parse the preview programmatically.

**SHOULD:**

- Write operations SHOULD be idempotent where the domain allows it — running the same command twice produces the same
  result rather than duplicating the effect.

### Evidence Patterns

- `--dry-run` flag on commands that create, update, or delete resources
- `--force` or `--yes` flag on destructive commands
- Command names that signal intent: `add`, `remove`, `delete`, `create` for writes; `list`, `show`, `get`, `search` for
  reads
- Dry-run output showing what would change without executing

### Anti-Patterns

- A `delete` command that executes immediately without `--force` or confirmation
- Write commands with the same name pattern as read commands (e.g., `sync` that silently overwrites local state)
- No `--dry-run` option on bulk operations where a preview would prevent costly mistakes
- Operations that fail on retry because the first attempt partially succeeded (non-idempotent writes without rollback)

---

## P6: Composable and Predictable Command Structure

### Definition

Tools MUST integrate cleanly with pipes, scripts, and other CLI tools. This means fixing SIGPIPE handling, detecting
TTY for color/formatting decisions, supporting stdin for piped input, and maintaining a consistent, predictable
subcommand structure.

### Why Agents Need It

Agents compose CLI tools into pipelines: `tool list --output json | jaq '.[] | .id' | xargs tool get`. Every link in
this chain must behave predictably. A tool that panics on SIGPIPE when piped to `head` breaks the pipeline. A tool that
emits ANSI color codes into a pipe pollutes downstream JSON parsing. A tool with inconsistent subcommand naming forces
the agent to memorize exceptions rather than applying patterns. Composability is what makes a CLI tool a building block
rather than a dead end.

### Requirements

**MUST:**

- The SIGPIPE fix MUST be the first executable statement in `main()`. Without it, piping output to `head`, `tail`, or
  any tool that closes the pipe early causes a panic ("broken pipe"). See `templates/clap-main.rs` for the
  `libc::signal(libc::SIGPIPE, libc::SIG_DFL)` pattern.
- Tools MUST detect TTY and respect `NO_COLOR` and `TERM=dumb` environment variables for disabling color output. When
  stdout or stderr is not a terminal, color codes MUST be suppressed automatically. See `templates/output-format.rs` for
  the TTY detection logic in `OutputConfig::new()`.
- Shell completions MUST be available via a `completions` subcommand using `clap_complete`. This is a Tier 1
  meta-command that works without config, auth, or network. See `templates/clap-main.rs` for the three-tier dependency
  gating pattern.
- Network CLIs (those depending on reqwest, hyper, ureq, or similar HTTP crates) MUST provide a `--timeout` flag with a
  sensible default (30 seconds). Agents operating under their own time budgets need to fail fast rather than block on
  slow upstreams.
- If the CLI uses a pager (less, more, PAGER env), it MUST support `--no-pager` or respect `PAGER=""` to disable. Pagers
  block headless execution indefinitely.
- When the CLI uses subcommands, all agentic flags (`--output`, `--quiet`, `--no-interactive`, `--timeout`) MUST have
  `global = true` in their clap attribute so they propagate to all subcommands automatically.

**SHOULD:**

- Commands that accept input SHOULD support reading from stdin when no file argument is provided, enabling pipeline
  composition.
- Subcommand naming SHOULD follow a consistent `noun verb` or `verb noun` convention throughout the tool. Mixing
  patterns (e.g., `list-users` alongside `user show`) forces agents to learn exceptions.
- The three-tier dependency gating pattern SHOULD be used: Tier 1 (meta-commands like `completions` and `version`) needs
  nothing; Tier 2 (local commands) needs config; Tier 3 (network commands) needs config + auth. This ensures that
  `completions` and `version` always work, even in broken environments.
- Operations SHOULD be modeled as subcommands, not flags. `tool search "query"` is correct; `tool --search "query"` is
  wrong. Flags are for behavior modifiers (`--quiet`, `--output json`), not for selecting which operation to perform.

**MAY:**

- Tools MAY support `--color auto|always|never` for explicit color control beyond TTY auto-detection.

### Evidence Patterns

- `libc::signal(libc::SIGPIPE, libc::SIG_DFL)` as the first statement in `main()`
- `IsTerminal` trait usage (either `std::io::IsTerminal` or the `is-terminal` crate)
- `NO_COLOR` environment variable check
- `TERM=dumb` check
- `clap_complete` in `Cargo.toml` dependencies
- A `completions` subcommand in the CLI enum
- Tiered match arms in `main()` separating meta-commands from config-dependent commands

### Anti-Patterns

- Missing SIGPIPE handler — `cargo run -- list | head` panics with "broken pipe"
- Hard-coded ANSI escape codes without TTY detection
- Color output in JSON mode — ANSI codes inside JSON string values break parsing
- A `completions` command that requires authentication or config to run
- No stdin support on commands where piped input is a natural use case

---

## P7: Bounded, High-Signal Responses

### Definition

Tools MUST provide mechanisms to control output volume. Agent context windows are finite and expensive — a tool that
dumps 10,000 lines of unfiltered output wastes tokens and may exceed the context limit entirely, causing the agent to
lose track of the conversation.

### Why Agents Need It

Every token of CLI output consumed by an agent has a cost — both monetary (API tokens) and cognitive (context window
capacity). A tool that returns unbounded output forces the agent to either truncate (losing potentially important data)
or consume the full response (wasting context on noise). Bounded output with `--quiet`, `--verbose`, and `--limit` flags
gives the agent precise control over how much data it receives, keeping responses high-signal and within budget.

### Requirements

**MUST:**

- Tools MUST support `--quiet` to suppress non-essential output (progress indicators, informational messages, decorative
  formatting). When `--quiet` is set, only the requested data and errors appear. See `templates/output-format.rs` for
  the `diag!` macro that gates diagnostic output behind the quiet flag.
- Tools MUST clamp unbounded list operations to a sensible default maximum. A `list` command without `--limit` MUST NOT
  return more than a configurable ceiling (e.g., 100 items). If more items exist, the output MUST indicate truncation
  (e.g., `"truncated": true` in JSON, or a stderr message in text mode).

**SHOULD:**

- Tools SHOULD support `--verbose` (or `-v` / `-vv`) for increasing diagnostic detail, useful when agents need to debug
  failures.
- Tools SHOULD support `--limit` or `--max-results` to let callers request exactly the number of items they need.
- Tools SHOULD support `--timeout` to bound execution time. An agent waiting indefinitely for a hung network call cannot
  proceed.

**MAY:**

- Tools MAY support cursor-based pagination flags (`--after`, `--before`) for efficient traversal of large result sets.
- Tools MAY automatically reduce output verbosity when detecting a non-TTY context (similar to how `--quiet` behaves in
  JSON mode).

### Evidence Patterns

- `--quiet` flag with `FalseyValueParser` and env var binding
- `diag!` macro usage for all non-essential stderr output
- `--limit` or `--max-results` flag on list/search commands
- Pagination clamping logic (e.g., `min(requested, MAX_RESULTS)`)
- `--timeout` flag with a sensible default
- `--verbose` flag for diagnostic escalation
- `suppress_diag()` method that returns true when quiet is set or output format is JSON/JSONL

### Anti-Patterns

- List commands that return all results with no default limit — an agent listing 50,000 items floods its context window
- No `--quiet` flag — agents consuming JSON output still receive interleaved diagnostic text on stderr
- `--verbose` as the only output control (no way to reduce output, only increase it)
- Progress bars or spinners that write to stderr in non-TTY contexts, adding noise to agent logs
- No `--timeout` on network operations — a stalled request blocks the agent indefinitely
