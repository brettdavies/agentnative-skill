---
status: draft
created: 2026-05-01
owner: brett
target_repo: agentnative-skill
related: docs/brainstorms/2026-05-01-002-anc-determinism-feature-asks-requirements.md
---

# `agent-native-cli` skill — determinism & runbook hardening

Closes the gaps surfaced by the 2026-05-01 SKILL.md self-review against `create-agent-skills`. Two-agent variance is the
headline problem: two competent agents reading SKILL.md today can produce two different correct-looking-but-wrong
handlers for the same `anc audit` output. This document scopes the skill-side fixes that close that variance. Cross-repo
`anc` feature requests are tracked separately in
[`2026-05-01-002-anc-determinism-feature-asks-requirements.md`](./2026-05-01-002-anc-determinism-feature-asks-requirements.md).

## Problem

Today's `SKILL.md`:

- Describes the `anc audit` JSON envelope in prose only (no sample, no shape).
- Names the `results[].status` enum once in passing without enumerating values.
- Does not document `anc audit`'s exit-code contract.
- Mentions "schema 0.5" once with no pinning guidance and no behaviour-on-bump.
- Names four `--audit-profile` categories without a selection rule.
- Stops the iteration loop on `summary.fail == 0` + `must.verified == must.total`, with no termination rule for `warn`s
  once the badge floor is cleared.
- Gives no fallback for spec-version skew between bundle (`spec/VERSION` = 0.3.0) and `anc` releases.
- Provides no first-action precondition for "is `anc` even installed?".
- Leaves `badge.embed_markdown` placement, scorecard diffability, `--binary`/`--source` scoping, hybrid-language
  audit-profile selection, `json` vs `text` choice, and scorecard commit policy unresolved.

The mechanical rubric items pass (frontmatter, line count, headings, references one level deep). The gaps are content,
not structure.

## Goals

1. Make `anc`'s observable contract explicit in the skill so agents stop inferring it from prose.
2. Eliminate the highest-frequency situational dead-ends that don't have answers in `SKILL.md` or `getting-started.md`.
3. Stay under the 500-line SKILL.md ceiling. New material that doesn't pull weight in the entry-point file lives in
   `references/`.
4. Tighten the SKILL.md / `getting-started.md` / `references/` boundary so each file owns one job and there is no
   cross-file content duplication.
5. Broaden starter coverage so non-Rust paths and JSON-envelope authoring have first-class scaffolding.

## Non-goals

- Rewriting prose for Haiku-tier readability (separate brainstorm if pursued).
- Spec-text changes in the `agentnative` repo.
- Anything that requires `anc` to ship a new flag or output field — those are tracked in the sibling brief.
- Renaming the skill itself (`agent-native-cli`) — discoverability cost outweighs gerund-form rubric preference; see R10
  for which frontmatter changes ARE in scope.

## Requirements

### R1. Worked scorecard samples — three placements, three roles

**What.** Three coordinated samples, each sized for its location:

1. **`SKILL.md` inline** — minimal snippet (~12–15 lines) right after the "1. Check." paragraph. Shows the envelope's
   top-level shape (`summary`, `coverage_summary`, `badge`, `results[]`). Always-loaded; pays for ~150 tokens.
2. **`getting-started.md`** — even shorter snippet (3–5 lines) right after the `anc audit --output json . >
   scorecard.json` recipe in the "existing CLI" loop. Shows just `coverage_summary` + `badge` so an agent reading the
   recipe sees invocation→output side by side without scrolling. Pattern-match level only; not a parser spec.
3. **`references/scorecard-shape.md`** — exhaustive sample (~50–60 lines) covering every top-level field, one
   `results[]` entry per status value, every `audit_profile` category, full `tool` / `anc` / `run` / `target` metadata.
   Loaded only when an agent writes a parser.

**Must include (exhaustive sample):** one entry per top-level field — `summary`, `coverage_summary`, `badge`, one
`results[]` entry per status value, `audit_profile`, `tool`, `anc`, `run`, `target`. Real field names taken from a live
`anc audit --output json` run.

**Must show (exhaustive sample):** `summary.fail` (int), `coverage_summary.must.verified` (int), `badge.eligible`
(bool), `badge.embed_markdown` (string|null), `results[].requirement_id` (kebab-case string), `results[].status` (one of
pass / warn / fail / skip / error), `results[].evidence` (object).

**Acceptance.**

- An agent that reads only the exhaustive sample can write a parser handling all five status values and all four
  audit-profile categories without reading `anc` source.
- An agent skimming `getting-started.md` sees an output snippet without leaving the file.
- An agent skimming `SKILL.md` sees the envelope shape without leaving the file.

### R2. `## Anc contract` section in SKILL.md

**What.** A new short section between "First action: update check" and "Start here", or as a sub-section of "The anc
loop". Documents the observable contract.

**Must include:**

- **Output flag policy.** Agents always pass `--output json`; `text` is for humans.
- **Exit codes.** Table — what `0`, non-zero values, and "couldn't run" return. Pulled from `anc`'s actual behaviour; if
  `anc` doesn't have a stable exit-code policy, this R is blocked behind an anc-side change in the sibling brief.
- **`results[].status` enum.** Explicit list: `pass`, `warn`, `fail`, `skip`, `error`.
- **Schema-version pin.** Tell agents to assert `<envelope>.<path-to-schema>` matches a pinned value before parsing;
  spec out which path that is once anc surfaces it. If the envelope doesn't currently carry a version, the assertion
  guidance falls back to "pin `anc` binary version" and the durable fix moves to the sibling brief.
- **Stable vs noise.** Tell agents which subtree to diff for CI gating (`summary.*`, `coverage_summary.*`,
  `results[*].{requirement_id, status}`) and which is timestamp-noise (`run.*`).

**Acceptance.** An agent writing a CI gate that fails on regression can do so without guessing.

### R3. `--audit-profile` decision table

**What.** A 4-row table in SKILL.md (or `references/audit-profile-selection.md` if it needs more than 4 rows). One row
per profile — `human-tui`, `posix-utility`, `diagnostic-only`, `file-traversal` (reserved). Columns: when-to-pick
(one-line rule), example tool, what gets suppressed.

**Must include:** a "hybrid project" rule — what to do when a binary mixes a TUI-rendering mode with a stdin-piped batch
mode, or a mostly-Rust binary with shell-helper subcommands. Either profiles compose, or the rule is "scope to the
primary entry-point and leave secondary surfaces uncovered."

**Acceptance.** Three different agents reading the table for the same tool pick the same profile.

### R4. Loop termination rule for warn / should

**What.** One paragraph in "The anc loop". States explicitly:

- `must` violations gate the loop. Continue until `must.verified == must.total`.
- `warn`s are advisory. Once `badge.eligible == true` (≥80%), stop iterating. Do not spend agent time pushing `warn`s to
  `pass` unless the user explicitly asks.
- `error` (the run-failure status, distinct from `fail`) means re-run — see troubleshooting.

**Acceptance.** An agent in "fix mode" stops when the badge clears, not when every `warn` clears.

### R5. `anc` install precondition

**What.** Replace or augment the current "First action: update check" so the very first action a session takes is
verifying `anc` is on `PATH`. Pseudocode:

```text
if ! command -v anc; then
  prompt user with install options (brew / cargo) and exit
fi
run bin/check-update for the skill bundle
```

The current update-check is for the skill bundle, not `anc`; the skill should not silently assume `anc` exists.

**Acceptance.** Cold-start sessions never reach `anc audit` without first verifying or installing the binary.

### R6. Spec-skew fallback

**What.** Add a single paragraph or table row to "The anc loop" step 2 ("Fix.") covering: what to do when a finding
cites a `requirement_id` that does NOT exist in the bundle's vendored `spec/principles/`.

**Must include:**

- The likely cause (anc shipped against newer spec than this bundle vendors).
- The durable fix (`anc audit --explain <id>`, **once shipped** — see sibling brief).
- The interim fix (resync via `scripts/sync-spec.sh`, or fetch `spec/principles/p<N>-*.md` from `agentnative` `main`).
- The non-fix (do not hallucinate a definition).

**Acceptance.** An agent hitting the skew case has a deterministic next step that isn't "read source".

### R7. Situational runbook (the dead-ends in C)

**What.** A new `## Common situations` section near the bottom of SKILL.md or a new `references/runbook.md` linked from
there. One paragraph per situation. Cover:

- `badge.embed_markdown` placement — top of README, replacing existing badges, ordering relative to CI badges. Adopt
  whatever convention `anc.dev/badge` recommends; if it doesn't recommend one, propose one here and push it upstream.
- Should I commit `scorecard.json`? — default no (artifact, regenerable). Override only for CI gating snapshots.
- `anc audit .` vs `--binary` vs `--source` — when each applies.
- `anc` panics or returns malformed JSON — pointer to issue tracker, do not retry blind.
- `anc skill install` host not in registry — fallback to manual `git clone` (already in `getting-started.md`; cross-link
  from here).

Each entry: ≤4 lines. The goal is a fast index, not deep prose.

**Acceptance.** Agents stop generating issues that ask FAQs already covered.

### R8. Frontmatter — `allowed-tools`

**What.** Add `allowed-tools: Bash(anc *), Read` to SKILL.md frontmatter so the skill doesn't trigger permission prompts
for the canonical commands.

**Acceptance.** Mechanical — no user prompt on `anc audit` invocations once the skill loads.

### R9. SKILL.md / getting-started.md / references/ boundary cleanup

**What.** Eliminate cross-file duplication, give each file one job, and reorder SKILL.md so the loop the skill teaches
is the first thing an agent reads — not a session-once meta-update side task.

**File ownership:**

- **SKILL.md owns:** discovery (frontmatter), preamble (what the skill is + where the three artifacts live), Quick Start
  (one runnable `anc audit` command), the `anc` contract (R2), the four-step loop overview, the principles index,
  pointer to `getting-started.md` for procedural detail, pointer to runbook (R7), sources.
- **`getting-started.md` owns:** the three working loops (existing CLI / new Rust / other language), full install steps
  for `anc` and the skill bundle, the "where things live" pointer table.
- **`references/` owns:** depth — patterns, idioms, project structure, scorecard shape, audit-profile selection,
  runbook, update-check operational details. One topic per file, no cross-file overlap.

**Reorder SKILL.md.** Today the order is: preamble → `## First action: update check` → `## Start here` → principles →
anc loop → implementation guidance → starter code → compliance auditing → sources. The update-check section is a
session-once side task; making it section #2 trains agents to read meta-update flow before they read the work flow.

New order:

1. Preamble (unchanged).
2. **Quick Start** — one runnable `anc audit --output json . > scorecard.json` line + the 12–15-line inline scorecard
   sample from R1.
3. **The `anc` contract** (R2) — exit codes, status enum, schema-version pin, stable-vs-noise.
4. **The anc loop** — four steps, conceptual (R4 termination rule folded in).
5. **The seven principles** index (unchanged).
6. **Pointer block** — links to `getting-started.md` (install, three loops), `references/` (depth), `templates/`
   (starters), `references/runbook.md` (R7).
7. **Update-check** — demoted to a one-paragraph footnote near the bottom referencing `references/update-check.md`. The
   session-once `bash bin/check-update` invocation moves to that reference file (or to `bin/README.md` if that fits the
   repo convention better).
8. Sources.

This reorder also resolves the "first runnable thing in SKILL.md is `bash bin/check-update`" issue surfaced in external
review: after the reorder, the first runnable thing is `anc audit`.

**Must remove:**

- The duplicated install block in `SKILL.md` § "Compliance auditing" (lives in `getting-started.md` already).
- The duplicated four-step loop where `SKILL.md` § "The anc loop" and `getting-started.md` "existing CLI" section both
  walk it. Canonical homes: SKILL.md for the conceptual loop; `getting-started.md` for the runnable bash.
- The two parallel index tables — SKILL.md "Implementation guidance" pointer table and `getting-started.md` "Where
  things live". Merge into one, owned by `getting-started.md`. SKILL.md retains a brief pointer paragraph.

**Must add:**

- SKILL.md `## Quick Start` section at position #2 above (after the preamble, before everything else).
- Inline scorecard sample from R1 lands inside Quick Start.

**Acceptance.**

- A grep for any of `brew install brettdavies/tap/agentnative`, `cargo install agentnative`, or `anc skill install
  claude_code` returns hits in exactly one file.
- The four-step loop appears once in SKILL.md (conceptual) and the bash recipe form appears once in
  `getting-started.md`.
- A first-time agent reading SKILL.md sees `anc audit` as the first runnable command, not `bash bin/check-update`.
- The update-check section is no longer the second top-level heading.
- SKILL.md stays under 200 lines after the cleanup.

### R10. Frontmatter audit beyond `allowed-tools`

**What.** A small structured pass over SKILL.md frontmatter, separate from R8.

**In-scope changes:**

- Confirm `description` lead clause answers "what is this" before "what does it pair with". Today: `Guide to designing,
  building, and auditing CLI tools for use by AI agents.` — passes the test, leave alone.
- Audit the `Triggers on` keyword list in the description against the rubric's "include trigger keywords" rule. Drop any
  keyword that hasn't fired discovery in practice; add ones that have come up in skill-side questions but aren't there.
  Stay under 1024 chars.
- Audit the `SKIP when` clause for collisions with adjacent skills (e.g. anything that overlaps `compound-engineering`
  or `create-agent-skills` should be sharper).
- **No** `argument-hint` — this is a background-knowledge skill, not a slash command.
- **No** `model:` pin — let the host decide.
- **No** `disable-model-invocation` — auto-load is correct here.
- **No** rename of `name`. The discoverability cost (existing references in `getting-started.md`, `AGENTS.md`,
  templates, and external badges) outweighs the rubric's gerund-form preference. Document this decision in the doc
  itself.

**Acceptance.** Frontmatter passes a fresh `create-agent-skills` audit at the "well-tuned" tier, not just "valid", and
the kept-as-is decisions have inline rationale (in this doc, not in the SKILL.md frontmatter).

### R11. New starter templates and framework idioms

**What.** Broaden `templates/` and `references/framework-idioms-other-languages.md` so non-Rust paths have first-class
scaffolding instead of "read the principles and figure it out."

**Templates to add (priority order):**

1. **`templates/cargo-toml.md`** — drop-in `[dependencies]` block for the Rust starter. Today an agent copying
   `clap-main.rs` has to know to add `clap` (with `derive` + `env`), `serde`, `serde_json`, `thiserror`, `libc` (for
   SIGPIPE), `clap_complete`. AGENTS.md template documents this in prose; a copy-paste TOML block is faster.
2. **`templates/cli-tests.rs`** — `assert_cmd` patterns covering P5 mutation boundaries (idempotency, dry-run,
   `--yes`/`--force` distinction). Encodes P5 by construction.
3. **`templates/scorecard-envelope.schema.json`** — JSON Schema for the canonical structured-output envelope authors
   should emit when implementing P2. Compounds with R1: agents write code that conforms, and `anc` (or any other linter)
   can validate against the schema directly.
4. **`templates/python-click/`** — minimal Python/Click starter (one main file + `pyproject.toml` snippet) encoding P1
   SIGPIPE handling, P2 stdout/stderr separation, P4 exit codes. Mirror of `clap-main.rs` for the Click world.
5. **`templates/go-cobra/`** — same idea, Go/Cobra. Mirrors `clap-main.rs`.
6. **`templates/agents-md-template.python.md`** and **`.go.md`** — language-flavoured AGENTS.md scaffolds, since the
   current AGENTS.md template embeds Rust-specific conventions.

**Framework idioms to add:**

- A "JSON envelope" sub-section in `references/framework-idioms-other-languages.md` showing the canonical envelope shape
  in Python/Go/JS/Ruby. Pairs with `templates/scorecard-envelope.schema.json`.
- A "testing P5 mutation boundaries" section, parallel to the Rust `assert_cmd` template, with idiomatic patterns in
  `pytest`, Go `testing`, `vitest`, and `rspec`.

**Out of scope for R11 (file kept, deferred to future work):**

- Adding new principles or new audit profiles (those originate in `agentnative-spec`, not here).
- Adding starters for languages not already covered in `framework-idioms-other-languages.md` (Rust, Python, Go, JS,
  Ruby). Adding e.g. a Swift starter is its own brainstorm.

**Acceptance.**

- A new Rust CLI can be bootstrapped with three `cp` commands and a `cargo add` that's just copy-paste from the new
  Cargo TOML template.
- A new Python CLI has a starter that encodes P1/P2/P4 by construction.
- An author implementing P2 can validate their JSON output against the schema template without writing one from scratch.

### R12. Consolidate the two Rust-idiom reference files

**What.** Merge `references/framework-idioms.md` (137 lines, "Free from clap / Must implement / Anti-patterns" framing,
Rust-only) and `references/rust-clap-patterns.md` (209 lines, denser per-principle prose) into one canonical Rust
reference — proposed name `references/rust-clap.md`. Cross-checked against both files: P1, P3, P5, P7 are heavily
overlapping; P2, P4, P6 each have one file-unique nugget worth preserving.

**File-unique content to preserve (must not be lost in the merge):**

- From `framework-idioms.md`: the **Free / Must / Anti-patterns** three-bucket organizational framing — keep this as the
  canonical structure. Also the closing pointer table to `framework-idioms-other-languages.md`.
- From `rust-clap-patterns.md`: the **subcommand-vs-flag taxonomy** in P6 (subcommands for operations, nested
  subcommands for namespaces, global flags for cross-cutting modifiers, local flags for command-specific modifiers, both
  flag and subcommand for meta-commands like `--help` / `--version`). This is real content, not duplication. Also: the
  **`kind()` method + main-only `process::exit()`** rule in P4. Also: the **Jsonl variant** of the output format enum
  (Text/Json/Jsonl) in P2. Also: the explicit references to xurl-rs / bird as exemplar codebases — keep these as
  concrete-example anchors.

**Merge strategy:**

1. Adopt `framework-idioms.md`'s Free / Must / Anti-patterns scaffold per principle.
2. For each principle's Must-implement bucket, fold in the deeper detail from `rust-clap-patterns.md` — patterns, crate
   names (FalseyValueParser, clap_complete), exit codes (sysexits 77/78), exemplar refs.
3. P2 Must-implement: explicitly enumerate Text/Json/Jsonl as the three OutputFormat variants.
4. P4 Must-implement: include both `exit_code()` and `kind()` methods, plus the "restrict `process::exit()` to `main()`"
   rule.
5. P6 gets a new sub-section before the Free/Must/Anti-patterns triplet: **Flags vs subcommands taxonomy** — five
   bullets covering the subcommand-vs-flag rules from `rust-clap-patterns.md`.
6. Delete `references/framework-idioms.md` and `references/rust-clap-patterns.md` once `rust-clap.md` is reviewed.
7. Update SKILL.md's "Implementation guidance" pointer table (or its consolidated R9 equivalent in `getting-started.md`)
   to reference the single new file.

**Estimated size:** ~250 lines for the merged file, replacing 346 lines of overlap. Net repo savings ~100 lines, plus
the cognitive savings of "one file per language family, organized identically."

**Out of scope:**

- Re-organizing `framework-idioms-other-languages.md`. That file is multi-framework by design and has a different axis
  (one section per framework, not one file per language).
- Splitting the consolidated file by clap version. If clap 5 ships with breaking changes, that's a future concern.

**Acceptance.**

- One canonical Rust idioms reference at `references/rust-clap.md`.
- Both `framework-idioms.md` and `rust-clap-patterns.md` are deleted from the repo.
- All file-unique content listed above appears in the merged file.
- SKILL.md and `getting-started.md` reference the new file (no broken links).
- A diff between "what's in the merged file" and "union of the two source files" shows no information loss other than
  prose duplication.

## Implementation surface

| Requirement | Lands in                                                                                                                                                                                                                                    | Estimated size                   |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| R1          | SKILL.md inline (minimal) + `references/scorecard-shape.md` (exhaustive)                                                                                                                                                                    | 15 + 60 lines                    |
| R2          | SKILL.md, new section                                                                                                                                                                                                                       | 25–40 lines                      |
| R3          | SKILL.md table + `references/audit-profile-selection.md` (extended)                                                                                                                                                                         | 10 + 40 lines                    |
| R4          | SKILL.md, edit existing "anc loop"                                                                                                                                                                                                          | 5–10 lines                       |
| R5          | SKILL.md, edit "First action"                                                                                                                                                                                                               | 5–10 lines                       |
| R6          | SKILL.md, edit "Fix." step                                                                                                                                                                                                                  | 5–10 lines                       |
| R7          | `references/runbook.md` (linked from SKILL.md)                                                                                                                                                                                              | 50–80 lines                      |
| R8          | SKILL.md frontmatter                                                                                                                                                                                                                        | 1 line                           |
| R9          | SKILL.md restructure + `getting-started.md` cleanup; merge index tables                                                                                                                                                                     | net ≈0 lines                     |
| R10         | SKILL.md frontmatter (description + skip clause audit)                                                                                                                                                                                      | ≤5 lines net                     |
| R11         | `templates/cargo-toml.md`, `templates/cli-tests.rs`, `templates/scorecard-envelope.schema.json`, `templates/python-click/`, `templates/go-cobra/`, two AGENTS.md variants, sub-sections in `references/framework-idioms-other-languages.md` | ~400 lines new files             |
| R12         | New `references/rust-clap.md`; delete `references/framework-idioms.md` + `references/rust-clap-patterns.md`                                                                                                                                 | ~250 new, 346 deleted (net −100) |

**SKILL.md ceiling check.** R9 deletes duplicated install + loop content (~25 lines saved), R1 + R2 + R3 + R4 + R5 + R6
add ~70 lines, R7 + R11 + R12 land outside SKILL.md, R8 + R10 are frontmatter. Net SKILL.md delta is roughly +45 lines,
taking it from 146 to ~190 — well under the 200-line target in R9 and the 500-line rubric ceiling.

**Repo-wide delta.** ~400 lines in new template files, ~150 lines in new reference files (R7 runbook + R3
audit-profile-selection + R1 scorecard-shape), ~250 lines in the merged R12 file, 346 lines deleted in the R12 merge,
~45 lines net into SKILL.md, ~20 lines net into `getting-started.md` after de-duplication. Net repo: ~520 lines added,
~25 lines deleted in SKILL.md/getting-started.md de-dup, ~346 lines deleted in R12 merge.

## Dependencies / assumptions

- **Soft dependency on sibling brief.** R2's schema-pin guidance and R6's `--explain` reference both work better once
  `anc` ships matching features. They're not blocked — interim guidance is documentable today, but the docs become
  stable when anc lands the features. See sibling brief for which features.
- **`scripts/sync-spec.sh` works.** R6's interim fix relies on the existing sync script. If it's broken or stale, fix
  that as a precondition.
- **`anc.dev/badge` convention.** R7's badge-placement guidance defers to the live convention. If the convention page
  doesn't yet specify placement, this requirement triggers a content addition there too.

## Success criteria

- Two independently-prompted agents asked "parse this scorecard and report failures" produce structurally identical
  handlers.
- An agent given a tool to audit and asked to pick `--audit-profile` arrives at the same answer as the human reviewer.
- Cold-start sessions never call `anc audit` against a missing binary.
- An agent finishing a remediation loop stops when `badge.eligible == true`, not when every warn clears.
- A finding citing a `requirement_id` not in the local vendored spec resolves deterministically.
- A first-time agent reading SKILL.md sees a runnable `anc audit` command before scrolling, and can find install
  instructions, the three working loops, and reference depth without re-reading SKILL.md (R9).
- A new Python or Go CLI author has a starter that encodes P1/P2/P4 by construction (R11).
- A grep across the repo for any single canonical command (e.g. `anc skill install claude_code`) returns hits in exactly
  one canonical location (R9).
- One canonical Rust idioms reference exists (R12). `framework-idioms.md` and `rust-clap-patterns.md` are gone; no links
  in SKILL.md or `getting-started.md` are broken.
- The first runnable command an agent encounters in SKILL.md is `anc audit`, not `bash bin/check-update` (R9 reorder).

## Open questions

1. **R1** — inline in SKILL.md or in `references/scorecard-shape.md`? Resolved: inline a minimal sample (~15 lines) AND
   link `references/scorecard-shape.md` for the exhaustive one. Recorded in the implementation table.
2. **R2** — does `anc` currently have a stable exit-code policy worth documenting, or does this R block on the sibling
   brief? Verify against `agentnative-cli` source before drafting R2 prose.
3. **R7** — `## Common situations` in SKILL.md vs `references/runbook.md`? Resolved: `references/runbook.md`. SKILL.md
   gets a one-paragraph pointer.
4. **R9 sequencing.** Run R9 first (de-duplicate, restructure) so R1–R7 land in their final homes the first time and
   don't have to be moved during R9. Alternative: run R9 last as a cleanup pass once R1–R7 reveal where content actually
   wants to live. Recommendation: R9 first; the boundary is clear enough today and re-homing later is more work.
5. **R10** — does the description's `Triggers on` keyword list match the queries skills actually fire on in real
   traffic? Need a short audit (sample of recent skill-discovery hits or qmd queries) before pruning/adding.
6. **R11 scope** — ship all six template additions in one PR or split per language? Recommendation: split. Rust
   additions (cargo-toml, cli-tests, scorecard-envelope.schema.json) ship together; Python and Go each ship as their own
   PR so each can be reviewed by someone fluent in that ecosystem.
7. **R12 sequencing relative to R11.** The R11 Rust starter additions (cargo-toml, cli-tests, scorecard-envelope) and
   R12 (consolidate Rust idioms) both touch the Rust documentation surface. Ship R12 first so the merged
   `references/rust-clap.md` is the link target for the new starter docs. Recommended.

## Handoff

Next step: `/ce-plan` against this document. Implementation breakdown:

- **PR 1 (skill-side determinism).** R1–R8 plus R9 (do R9 first to avoid re-homing). One commit per requirement for
  review legibility. Targets `dev`. Estimated total ~250 lines added/changed across SKILL.md, getting-started.md, and
  three new reference files.
- **PR 2 (frontmatter polish).** R10 only. Tiny PR; can land in PR 1 if it stays under ~10 lines. Split if R10's
  description audit takes more than that.
- **PR 3 (Rust idioms consolidation).** R12 only. Merge `framework-idioms.md` + `rust-clap-patterns.md` into
  `references/rust-clap.md`; delete the originals; update SKILL.md / `getting-started.md` link targets. Land before PR 4
  so the new starter docs reference the merged file.
- **PR 4 (Rust starter completion).** R11 items 1–3 — `cargo-toml.md`, `cli-tests.rs`, `scorecard-envelope.schema.json`.
  Self-contained, no skill prose changes.
- **PR 5 (Python starter).** R11 items 4 + 6a — `python-click/` template, `agents-md-template.python.md`, plus the
  Python sections in framework-idioms.
- **PR 6 (Go starter).** R11 items 5 + 6b — `go-cobra/` template, `agents-md-template.go.md`, plus the Go sections in
  framework-idioms.

Sibling brief (`2026-05-01-002-anc-determinism-feature-asks-requirements.md`) is filed separately against
`agentnative-cli`. R2 and R6 reference items there as soft dependencies; interim guidance ships in PR 1 regardless.
