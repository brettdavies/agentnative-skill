---
status: draft
created: 2026-05-01
owner: brett
target_repo: agentnative-cli
related: docs/brainstorms/2026-05-01-001-skill-determinism-requirements.md
---

# `anc` — feature asks for deterministic agent consumption

Cross-repo brief. Lives in `agentnative-skill` next to its sibling because the asks were surfaced by the skill-side
review on 2026-05-01, but the durable fixes ship in `anc` itself. This document is the source for an issue (or set of
issues) to be filed against [`brettdavies/agentnative-cli`](https://github.com/brettdavies/agentnative-cli). The
skill-side requirements document
([`2026-05-01-001-skill-determinism-requirements.md`](./2026-05-01-001-skill-determinism-requirements.md)) references
several items here as soft dependencies — interim skill-side guidance is shippable today, but stabilises once these
land.

## Problem

Agents consuming `anc audit` output today must infer details that should be self-describing in the binary's contract:

- The JSON envelope's schema version is internal documentation, not a field agents can assert against. A bump from 0.5
  to 0.6 with renamed fields breaks consumers silently.
- A finding cites a `requirement_id` (e.g. `p1-must-no-interactive`) but resolving its text requires the consumer to
  read a vendored copy of the spec, which can drift from the version `anc` was built against.
- The `text` mode appends a badge embed hint, but the embed string itself doesn't declare *where* in a README it should
  land — every consumer reinvents that.
- `audit_profile` exemptions are documented at four named categories, but nothing encodes how to pick one for a hybrid
  tool (TUI rendering + stdin batch mode + a shell wrapper).
- Scorecard envelopes contain timestamp / run-id metadata mixed in with the gating payload, so CI gates that diff the
  whole envelope see false churn.
- `anc audit`'s exit-code semantics aren't part of the documented contract, so agents can't `&&`-chain it reliably.

Each of these is fixable in the skill via prose, but the durable fix is for `anc` to make the contract self-describing.

## Goals

1. Make `anc`'s observable contract robust against version drift.
2. Eliminate the runbook items where the skill is currently papering over a missing `anc` feature.
3. Keep changes additive — no breaking changes to schema 0.5 consumers.

## Non-goals

- Restructuring `anc`'s internals or check pipeline.
- Spec-text changes (those go to `agentnative`).
- Anything that would prevent JSON envelopes from being consumed by an existing schema-0.5 parser (i.e. additions are
  tolerated, renames are not — gate any rename behind a schema bump).

## Asks

Each ask is sized small enough to ship independently. Priorities reflect the skill-side benefit; `anc` may have other
priorities.

### A1. Self-describing schema version in the envelope (highest priority)

**What.** Surface the schema version on every `anc audit --output json` envelope at a stable, top-level path — proposed
`anc.schema_version` (sits alongside `anc.version`) or `run.schema_version`. String, semver-shaped (`"0.5"`, `"0.6.0"`).

**Why.** Lets every agent assert `envelope.anc.schema_version == "0.5"` (or whatever they pinned against) before
parsing. Today the only fingerprint is the binary version. Schema and binary versions diverge; one is the contract, the
other is the implementation.

**Acceptance.**

- Field present in every JSON envelope from `anc audit`.
- Documented in the README and the `anc` man page (or equivalent).
- Bumping the schema bumps this field. Adding fields without rename does not.

### A2. `anc explain <requirement_id>` (closes spec-skew gap)

**What.** A new subcommand or flag that prints the spec text + machine-readable metadata for one `requirement_id` *from
the version of the spec `anc` was built against*. Output: `--output text` (default, human-readable) and `--output json`
(envelope with the full requirement record from spec frontmatter).

**Why.** Today, an agent sees a finding citing `p1-must-no-interactive` and goes to `spec/principles/p1-*.md` — but the
bundle vendors a snapshot, and that snapshot can lag the `anc` build. `anc explain` is the only authoritative source:
it's whatever this specific binary was compiled against. Eliminates the spec-skew dead-end (R6 in the skill-side doc) at
its root.

**Acceptance.**

- `anc explain p1-must-no-interactive` returns spec text and structured metadata for a valid id.
- `anc explain bogus-id` returns a non-zero exit and a structured error envelope.
- `anc explain --list` (or `anc list-requirements`) enumerates every id the binary knows about.

### A3. Stable exit-code policy

**What.** Document and stabilise the exit-code contract for `anc audit` and other subcommands. Proposed:

| Exit | Meaning                                                                   |
| ---- | ------------------------------------------------------------------------- |
| 0    | Ran successfully; `summary.fail == 0` and the run is gating-clean.        |
| 1    | Ran successfully; one or more `fail`s present (gating violation).         |
| 2    | Invocation error — bad flags, target not found, profile name unknown.     |
| 3    | Internal error — panic, malformed input, schema version mismatch on read. |

**Why.** Lets agents and CI scripts use `anc audit && next-step` reliably, and lets agents distinguish "tool said no"
from "tool couldn't run." Closes R2's exit-code row in the skill-side doc.

**Acceptance.**

- Behaviour documented in README and CLI `--help`.
- Tested in CI for each exit class.
- The skill-side doc R2 references this table directly.

### A4. Embed-position metadata on the badge block

**What.** Add an optional field — proposed `badge.embed_position` — that names the recommended placement convention.
String enum, e.g. `"top-of-readme"`, `"under-title"`, `"in-badges-row"`, `null` if no convention applies. Defer to
whatever [`anc.dev/badge`](https://anc.dev/badge) publishes; anc just surfaces it.

**Why.** Today four agents pasting `badge.embed_markdown` into the same README put it in four places. Convention belongs
at the source, not in every consumer's head.

**Acceptance.**

- Field present whenever `badge.eligible == true`.
- Skill-side R7 (badge placement runbook entry) defers to this field instead of duplicating the convention.
- Convention page at `anc.dev/badge` enumerates the values.

### A5. Stable-output mode for CI diffability

**What.** Either:

- **(a)** Split the envelope into a stable subtree (gating-relevant: `summary`, `coverage_summary`, `results`,
  `audit_profile`, `badge`) and a metadata subtree (`tool`, `anc`, `run`, `target`) that consumers can ignore for diff
  purposes. This may already be the layout — confirm and document it.
- **(b)** Add `--stable` (or `--no-timestamps`) that elides volatile fields entirely, producing a byte-stable output for
  identical input.

**Why.** CI gates that diff scorecards across runs see false churn from `run.*` timestamps. Diffing only `summary` is
the workaround; native support eliminates it.

**Acceptance.**

- Document the stable subtree in the README. OR
- `anc audit --stable .` produces byte-identical output for byte-identical input.

### A6. Profile composition for hybrid tools

**What.** Either allow `--audit-profile` to take a comma-separated list, OR add a `--audit-profile-for-subcommand
<subcmd>=<profile>` repeatable flag, so a tool with a TUI mode + a batch mode can scope profiles per surface.

**Why.** Today the four categories (`human-tui`, `posix-utility`, `diagnostic-only`, `file-traversal` reserved) don't
compose. Real tools mix shapes — e.g. an agent-native CLI with one rendering subcommand. Forcing a single profile either
suppresses real findings (if the user picks `human-tui`) or surfaces irrelevant ones (if they don't).

**Acceptance.**

- Hybrid tool case has a deterministic incantation.
- Skill-side R3 ("hybrid project rule") points to this rather than inventing a workaround.

### A7. `anc` self-audit / `anc doctor`

**What.** A subcommand that prints `anc.version`, `anc.schema_version`, the spec version it was built against, the
registered audit-profile names, and the registered hosts for `anc skill install`. JSON output supported.

**Why.** Replaces a half-dozen "what does my install actually know about" questions that today require reading source.
Also supports the skill-side R5 install precondition — the agent can run `anc doctor --output json` to confirm health,
not just `command -v anc`.

**Acceptance.**

- One subcommand returns everything needed to validate an install.
- Output stable enough for an agent to assert against.

## Priority and sequencing

Ranked by skill-side benefit:

1. **A1** (schema version) — unblocks future schema bumps without breaking consumers. Smallest change, largest leverage.
2. **A3** (exit codes) — unblocks CI gating and `&&` chaining.
3. **A2** (`anc explain`) — closes the spec-skew dead-end at its root.
4. **A5** (stable output) — closes CI diff churn.
5. **A6** (profile composition) — closes the hybrid-tool dead-end.
6. **A4** (embed position) — closes the badge placement question. Lowest urgency because the skill can document a
   convention as a stop-gap.
7. **A7** (`anc doctor`) — convenience; not blocking anything.

A1 and A3 are the two that the skill-side document treats as soft dependencies. The rest are independent improvements.

## Filing plan

Each ask becomes its own GitHub issue against `agentnative-cli`, labelled `agent-determinism` and cross-referencing this
brief and the skill-side sibling. The issue body is the corresponding `### Aₙ` block from this document (roughly
verbatim) plus a "Surfaced by" link to the skill-side review thread.

A1 and A3 should land in the same `anc` release if possible — they pair naturally and together unblock the
highest-impact skill-side requirements.

## Open questions

1. A1 — does `tool.schema_version` already exist somewhere in the envelope? If yes, this ask collapses to "document and
   stabilise"; if no, it's a small additive change.
2. A5 — confirm whether the current envelope already segregates stable from volatile fields cleanly. If so, the ask is
   purely documentation.
3. A2 — is the spec already embedded in the binary at compile time, or is it loaded from a vendored snapshot at runtime?
   The implementation strategy depends on the answer.
