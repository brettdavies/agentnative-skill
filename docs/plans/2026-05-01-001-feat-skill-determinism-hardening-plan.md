---
title: "feat: SKILL.md determinism + runbook hardening (R1–R12)"
type: feat
status: active
date: 2026-05-01
origin: docs/brainstorms/2026-05-01-001-skill-determinism-requirements.md
sibling_brief: docs/brainstorms/2026-05-01-002-anc-determinism-feature-asks-requirements.md
---

# feat: SKILL.md determinism + runbook hardening (R1–R12)

## Summary

Rewrite `SKILL.md`, `getting-started.md`, and four reference files against `anc 0.3.0`'s live JSON envelope
(`schema_version: "0.5"`, top-level `tool/anc/run/target/badge/audience/audit_profile`, `results[].id`); add three new
reference files (`runbook.md`, `scorecard-shape.md`, `audit-profile-selection.md`) and a consolidated `rust-clap.md`;
ship six new templates (Cargo TOML, CLI tests, scorecard JSON Schema, Python/Click + Go/Cobra starters with paired
AGENTS.md scaffolds). Sequenced as seven landable PRs: R9 boundary cleanup first, then R1–R8 determinism additions, then
R10 frontmatter, then R12 Rust idioms consolidation, then three language-starter PRs, then R14 deterministic-script
hardening (the dogfood gate that makes `bin/check-update` and `scripts/sync-spec.sh` pass the audit the skill teaches).
All seven PRs ship in one consolidated `v0.4.0` release.

---

## Problem Frame

`SKILL.md` today describes the `anc` envelope in prose without samples, names `results[].status` once without
enumerating values, has no exit-code contract, no schema-version pin, no `--audit-profile` selection rule, no
termination rule for `warn`s, no fallback for spec-skew, no install precondition, no runbook, and no allowed-tools
frontmatter. Two competent agents reading it can produce two different correct-looking-but-wrong scorecard handlers —
that variance is the problem this plan closes. Full pain narrative + all twelve requirements live in
`docs/brainstorms/2026-05-01-001-skill-determinism-requirements.md`. A sibling cross-repo brief
(`docs/brainstorms/2026-05-01-002-anc-determinism-feature-asks-requirements.md`) tracks the `anc`-side feature requests
this plan soft-depends on; interim guidance ships here regardless.

---

## Requirements

- R1. Worked scorecard samples in three placements (SKILL.md inline ~15 lines, getting-started.md inline ~5 lines,
  `references/scorecard-shape.md` exhaustive).
- R2. `## Anc contract` section in SKILL.md — output flag policy, exit codes, `results[].status` enum, schema-version
  pin path, stable-vs-noise subtree.
- R3. `--audit-profile` decision table in SKILL.md + extended `references/audit-profile-selection.md`.
- R4. Loop termination rule for `warn` / `should` (must gates the loop; warn is advisory; stop on `badge.eligible`).
- R5. `anc` install precondition replaces "First action: update check" as the very first action.
- R6. Spec-skew fallback paragraph in "The anc loop" step 2 (Fix.).
- R7. `references/runbook.md` covering badge placement, scorecard commit policy, `--binary` / `--source` scoping, anc
  panics, skill-host fallback.
- R8. `allowed-tools: Bash(anc *), Read` added to SKILL.md frontmatter.
- R9. SKILL.md / `getting-started.md` / `references/` boundary cleanup + reorder so the first runnable command in
  SKILL.md is `anc check`, not `bash bin/check-update`. SKILL.md kept under 200 lines.
- R10. SKILL.md frontmatter audit beyond `allowed-tools` — description triggers, skip clause, kept-as-is decisions
  documented.
- R11. New starter templates: `cargo-toml.md`, `cli-tests.rs`, `python-click/`, `go-cobra/`,
  `agents-md-template.{python,go}.md`; new sub-sections in `references/framework-idioms-other-languages.md` for JSON
  envelope authoring and P5 mutation-boundary testing. **The `templates/scorecard-envelope.schema.json` artifact origin
  R11 enumerated is dropped:** the canonical schema is shipped by upstream `agentnative-cli` (plan
  `agentnative-cli/docs/plans/2026-04-30-002-feat-scorecard-json-schema-plan.md`) embedded in the binary and exposed via
  `anc generate scorecard-schema`; vendoring a copy here would duplicate and drift. U14 is repurposed to document the
  extraction path. The "P2 author-output template" intent of origin R11.3 (a generic envelope template tool authors emit
  *their tool's* output against, distinct from anc's audit envelope) is deferred to follow-up work.
- R12. Consolidate `references/framework-idioms.md` + `references/rust-clap-patterns.md` into a single
  `references/rust-clap.md`; delete the originals; preserve every file-unique nugget the origin enumerates.
- R13. Subcommand index + target-resolution runbook entry (**plan-introduced, not origin-traced**). A short SKILL.md
  table covering the full `anc` subcommand surface (`check`, `generate`, `skill install`, `completions`, `help`, plus
  the bare-`anc`-defaults-to-`check` shortcut), so agents stop punting to `anc --help` for basic discovery. Plus an
  expanded runbook entry covering all four target modes — `anc check .` (project mode), `--binary`, `--source`,
  `--command <name>` — with resolution rules for each. Closes the two gaps a 2026-05-01 peer review of the current
  SKILL.md surfaced ("the full subcommand surface" and "target resolution rules for `--binary` vs `--source` vs
  `--command` vs project mode").
- R14. Deterministic-script hardening (dogfood gate, **plan-introduced 2026-05-04**). `bin/check-update` and
  `scripts/sync-spec.sh` must pass `anc check --binary --audit-profile posix-utility` with `badge.eligible == true` —
  the skill audits CLIs against the agent-native spec, so the skill's own runtime scripts must pass that audit. Add
  `--output text|json`, `--quiet`, `--no-interactive`, `--timeout <s>` global flags (P1, P2, P7) to both. Add
  `--dry-run` (P5) and `--force` (P5) to `scripts/sync-spec.sh`. Move success-path status echoes from stdout to stderr
  in `sync-spec.sh` so `--output json` produces a clean envelope. Distinguish network-fail from up-to-date in
  `bin/check-update`'s output (today both branches exit 0 silently). Document the text-mode token grammar, the JSON
  envelope per status, and the env-var contract (`AGENTNATIVE_SKILL_DIR`, `AGENTNATIVE_SKILL_REMOTE_URL`,
  `AGENTNATIVE_SKILL_STATE_DIR`, `SPEC_REMOTE_URL`, `SPEC_ROOT`) in `references/update-check.md` and
  `references/runbook.md`.

(R1–R12 cited verbatim from origin §Requirements; R13 added by this plan in response to a peer review of the live
SKILL.md that surfaced two recurrent gaps the origin brainstorm did not anticipate; R14 added 2026-05-04 to make the
skill's own scripts pass the audit the skill teaches — the dogfood gate. Success criteria from origin §Success Criteria;
R13's success criterion is "an agent driving `anc` cold can enumerate the subcommand surface and pick the right target
mode without reading `anc --help` source"; R14's is "`anc check --binary --audit-profile posix-utility` against
`bin/check-update` and `scripts/sync-spec.sh` produces `badge.eligible == true` for both.")

---

## Scope Boundaries

- No `anc` binary changes (sibling brief `2026-05-01-002` covers those).
- No spec-text edits — `spec/` is vendored from `agentnative` via `scripts/sync-spec.sh`.
- No skill rename — `name: agent-native-cli` stays per origin R10's documented "no" decision.
- No Haiku-tier prose rewrite (separate brainstorm if pursued).
- No new principles, new audit profiles, or new starter languages beyond Python/Go (Rust + JS + Ruby idioms exist;
  Swift, Kotlin, etc. are their own brainstorm).

### Deferred to Follow-Up Work

- JS and Ruby rows in `references/framework-idioms-other-languages.md`'s new "JSON envelope authoring" and "Testing P5
  mutation boundaries" sub-sections — section scaffolds land in PR 5; JS / Ruby rows defer to a follow-up PR matched to
  a JS/Ruby starter ecosystem expert.
- Updating origin brainstorm's R1 "Must show" field-list to use `id` instead of `requirement_id` — origin doc is closed;
  correction lives only in this plan and in the shipped docs.
- **P2 author-output envelope template** (the half of origin R11.3 that's distinct from anc's audit envelope). A generic
  envelope authors emit *their tool's* `--output json` against — not the anc audit envelope U14 now points at. Deferred
  to a follow-up plan because (a) origin R11.3 conflated the two artifacts, and (b) "what envelope shape should a P2
  tool emit?" is its own open question that compounds with the existing `references/framework-idioms-other-languages.md`
  JSON-envelope sub-section but isn't a one-file deliverable.

---

## Context & Research

### Relevant Code and Patterns

- `SKILL.md` (146 lines today) — entry point; frontmatter + preamble + four loop steps + principles index +
  implementation guidance + starter code + compliance checking + sources. R9 reorders this.
- `getting-started.md` (85 lines) — three working loops + install + "Where things live". R9 dedupes against SKILL.md.
- `references/framework-idioms.md` (137 lines, Free / Must / Anti-patterns scaffold, Rust-only) and
  `references/rust-clap-patterns.md` (209 lines, denser per-principle prose). R12 merges.
- `references/framework-idioms-other-languages.md` (338 lines; Click, argparse, Cobra, Commander, yargs, oclif, Thor) —
  R11 adds two new cross-language sub-sections.
- `references/project-structure.md` (165 lines) — Rust-prescriptive; not touched by this plan but linked from new
  `rust-clap.md`.
- `references/update-check.md` (33 lines) — already separated; R5 + R9 demote SKILL.md's update-check section here.
- `templates/clap-main.rs`, `templates/error-types.rs`, `templates/output-format.rs`, `templates/agents-md-template.md`
  — canonical Rust patterns; R11 adds Cargo TOML + tests + JSON Schema + Python/Go siblings.
- `bin/check-update` — bash, exits 0 always, emits `UPGRADE_AVAILABLE` on divergence. Used by R5's revised first action
  (after `anc` is verified on PATH).
- `spec/principles/p1-*.md` … `p7-*.md` — vendored at `spec/VERSION = 0.3.0`. Cited by R6 spec-skew fallback.

### Live `anc 0.3.0` envelope (verified 2026-05-01 against `anc check --output json --command rg`)

Top-level keys: `schema_version` (`"0.5"`), `spec_version` (`"0.3.0"`), `summary`, `coverage_summary`, `results`,
`audit_profile`, `audience` (`"agent-optimized"` for rg), `badge`, `tool`, `anc`, `run`, `target`. Result entries carry
`id` (kebab-case, e.g. `p3-help`), `label`, `group` (`P1`–`P7`), `layer` (`behavioral` / `project` / `source`), `status`
(one of `pass` / `warn` / `fail` / `skip` / `error`), `evidence`, `confidence`. Badge block populated when `eligible:
true`: `score_pct`, `embed_markdown`, `scorecard_url`, `badge_url`, `convention_url`. Run block carries `invocation`,
`started_at` (ISO-8601), `duration_ms`, `platform.{os,arch}`. Target block: `kind` (`command` / `path`), `path`,
`command`. Tool block: `name`, `binary`, `version`. Anc block: `version`.

Observed exit codes (verified 2026-05-01 against `anc 0.3.0` for echo / true / false / cat / ls / grep / rg): `0` when
summary is fully clean (no warn / fail / skip); `1` when warn or skip are present and `summary.fail == 0` (cat, ls,
grep, rg); `2` when `summary.fail > 0` (echo, true, false — each had `fail >= 1`) **OR** for invocation errors (missing
path, bad flag, unknown command). The `2` slot is overloaded today: it means "tool gated correctly with at least one
fail" *and* "tool failed to run." Agents writing CI gates **must** switch on `summary.fail`, not on `$?`, since `$? ==
2` cannot distinguish a real fail from a missing-path. Sibling brief A3 will split these (`1` for `fail > 0`, `2`
reserved for invocation errors only); until then, R2 documents this observed-but-overloaded behavior.

### Institutional Learnings

- `~/dev/solutions-docs/best-practices/skills-2-0-structure-progressive-disclosure-20260402.md` — SKILL.md is a metadata
- branch-router; depth lives in `references/`; templates must be self-contained text, not shell-callable. Reinforces R9
  boundary cleanup.
- `~/dev/solutions-docs/architecture-patterns/anc-cli-output-envelope-pattern-2026-04-29.md` — document the envelope
  contract once in `references/` and link from SKILL.md; do not duplicate field names inline. Drives the three-placement
  strategy in R1.
- `~/dev/solutions-docs/best-practices/cli-structure-for-machines-typed-json-fields-over-display-strings-2026-04-20.md`
  — agents must switch on typed fields, never grep human-mode display strings. Drives R2's stable-vs-noise guidance.
- `~/dev/solutions-docs/best-practices/consistent-json-schema-across-success-and-error-paths-2026-04-20.md` — error
  envelopes must carry the same context fields as success envelopes. Relevant to R11.3 schema template.
- `~/dev/solutions-docs/best-practices/agentnative-version-model-2026-05-01.md` — six version concepts across four
  repos; every version mention in SKILL.md must name *which* version (skill bundle / spec / anc). Drives R2 schema-pin
  wording.

### External References

- `anc.dev/badge` — convention page referenced by R7 badge-placement entry. R7 defers placement to whatever the
  convention publishes; if the page doesn't enumerate placement values, R7 proposes one and the sibling brief A4
  surfaces it as `badge.embed_position` metadata in a future anc release.

---

## Key Technical Decisions

- **Envelope reality alignment.** Every envelope-shape claim in `SKILL.md` and `getting-started.md` is rewritten against
  `anc 0.3.0` live output. The brainstorm's R1 "Must show" field list is treated as advisory: where it says
  `requirement_id`, the docs ship `id` (the actual envelope field). **The two are different namespaces, not synonyms.**
  Envelope `results[].id` is a CHECK id (`p3-help`, `p1-flag-existence`, `p6-sigpipe`); spec frontmatter
  `requirements[].id` is a REQUIREMENT id (`p1-must-no-interactive`, `p2-must-output-flag`). One check verifies one or
  more requirements; the mapping lives in each principle file's body prose (e.g. p6's "Measured by check IDs
  `p6-sigpipe`, `p6-no-color`, `p6-completions`, `p6-timeout`, `p6-agents-md`"). The previously-claimed "1:1 mapping"
  was wrong and is retracted across U4 / U5 / U8. The brainstorm's `tool/anc/run/target/badge.*` claims now match
  reality so they ship verbatim. New top-level fields the brainstorm did not enumerate (`audience`, `audience_reason`)
  are documented in `references/scorecard-shape.md` with an explicit value enumeration captured at U5 implementation
  time.
- **Schema-pin path is concrete.** R2 pins top-level `schema_version` (which exists today as `"0.5"`). No anc-side
  change required for the pin to ship usable. Sibling brief A1 proposed `anc.schema_version` for additivity; current
  top-level placement is documented as the canonical path.
- **Exit-code documentation is interim AND overloaded.** R2's exit-code table documents observed `anc 0.3.0` behavior
  empirically: `0` = fully clean, `1` = warn/skip-only with `summary.fail == 0`, `2` = `summary.fail > 0` **or**
  invocation error (the slot is overloaded today). Verified across 7 commands. The skill **must** instruct agents to
  switch on `summary.fail`, never `$?`, since `$? == 2` cannot distinguish a real fail from a missing-path. Sibling
  brief A3 will split the slots; until then, the interim guidance is `gate on summary.fail, treat $? as advisory`. The
  earlier draft of this decision (`1` = any non-pass present, `2` = invocation error only) was empirically wrong and is
  retracted.
- **Badge runbook works against the JSON envelope.** R7's badge-placement entry references `badge.embed_markdown`
  directly (it exists in JSON now); placement convention defers to `anc.dev/badge`; soft-deps on sibling brief A4 only
  for machine-readable position metadata.
- **R9 first, R12 before R11 Rust starters.** Origin Open Question #4 chose R9 first to avoid re-homing R1–R7 content.
  Origin Open Question #7 chose R12 before the Rust starter additions (PR 4) so the merged `references/rust-clap.md` is
  the link target the new starter docs reference. This plan adopts both.
- **R12 merge scaffold.** Adopt `framework-idioms.md`'s Free / Must / Anti-patterns three-bucket structure as canonical
  (per origin's "merge strategy"); fold every file-unique nugget enumerated in origin (subcommand-vs-flag taxonomy in
  P6, `kind()` method + main-only `process::exit()` in P4, Jsonl variant in P2, exemplar references to xurl-rs / bird).
- **R10 trigger-keyword audit defers into U10.** Origin Open Question #5 asked for a recent-traffic audit before
  pruning/adding triggers. The audit happens *inside* U10 (qmd query against the skills collection + manual review of
  the existing trigger list) rather than as a planning prerequisite. Keeps the plan unblocked.
- **PR-shaped phasing.** The plan ships as six landable PRs matching origin's handoff section. Each phase = one PR. This
  means the plan doubles as a multi-PR coordination doc; reviewers can land PR 1 without waiting on the rest.
- **Cross-language idiom sub-sections split across PR 5 + PR 6.** R11's "JSON envelope authoring" and "Testing P5
  mutation boundaries" sub-sections in `references/framework-idioms-other-languages.md` cover four languages (Python,
  Go, JS, Ruby). Section scaffold + Python rows land in PR 5; Go rows append in PR 6; JS + Ruby rows defer to follow-up
  work.
- **Schema-as-pointer, not schema-as-artifact (U14 pivot).** Origin R11.3 enumerated a hand-written
  `templates/scorecard-envelope.schema.json` in this skill bundle. Upstream `agentnative-cli` plan
  `2026-04-30-002-feat-scorecard-json-schema-plan.md` ships the canonical scorecard schema embedded in the `anc` binary
  (derived from Rust types via `schemars`, exposed via `anc generate scorecard-schema`, archived at
  `https://anc.dev/scorecard-v0.5.schema.json`). Vendoring a copy in this bundle would duplicate and drift the moment
  upstream bumps. U14 is repurposed: the skill points at the upstream verb (`anc generate scorecard-schema --output -`)
  rather than shipping its own copy. The "P2 author-output template" half of origin R11.3 (a generic envelope template
  tool authors emit *their tool's* output against, not anc's audit envelope) is deferred to follow-up work — it's a
  different artifact and origin conflated the two.
- **Verification posture.** PRs 1–6 are docs + templates. Most units verify via grep checks, line-count assertions,
  cross-file link integrity, and byte-faithful comparison against `anc check --output json` output. Three units have
  executable verification: U13 (`cli-tests.rs` runs under `cargo test`), U15 + U18 (Python / Go starters compile or
  import cleanly). U14 is now docs-only (it documents the upstream `anc generate scorecard-schema` extraction path), so
  it carries no executable verification beyond grep checks and link integrity. **PR 7 is the executable-verification
  exception:** U22 / U23 modify runtime bash scripts and U25 is the empirical dogfood gate (`anc check --binary` against
  both scripts).
- **R14 dogfood gate (PR 7).** Approach is additive: new flag surfaces (`--output text|json`, `--quiet`,
  `--no-interactive`, `--timeout`, `--dry-run`, `--force`) extend the existing CLI; default behavior is preserved
  byte-for-byte when no new flags are passed (back-compat for existing consumers and the cache file at
  `~/.cache/agent-native-cli/last-update-check`). Cache file format stays in legacy `UP_TO_DATE <ver>` /
  `UPGRADE_AVAILABLE <old> <new>` shape; JSON appears at output time only. One minor breaking change in `sync-spec.sh`:
  success-path status echoes ("querying…", "vendoring…", "wrote N principle files") move from stdout to stderr so
  `--output json` produces a clean stdout envelope. PR 7's changelog calls the breaking change out explicitly. The
  dogfood claim — the skill audits CLIs against the agent-native spec and the skill's own runtime scripts pass that same
  audit at the badge-eligible bar — is non-trivial credibility for the skill itself.

---

## Open Questions

### Resolved During Planning

- **OQ-origin-#1** (R1 inline vs reference): inline minimal (~15 lines) **and** reference exhaustive (~60 lines). Both
  ship in U5.
- **OQ-origin-#3** (R7 location): `references/runbook.md`, with a one-paragraph pointer in SKILL.md. U9.
- **OQ-origin-#4** (R9 sequencing): R9 first. PR 1 leads with U1.
- **OQ-origin-#6** (R11 PR split): split per language ecosystem. PR 4 Rust, PR 5 Python, PR 6 Go.
- **OQ-origin-#7** (R12 vs R11 Rust): R12 first. PR 3 lands before PR 4.
- **Field-name drift** (`results[].id` vs origin's `requirement_id`): use `id` (actual). The earlier "maps 1:1" framing
  was wrong — envelope `id` and spec frontmatter `requirements[].id` are different namespaces (check id vs requirement
  id). U4 / U5 / U8 carry the corrected framing and the principle-prose mapping path.

### Deferred to Implementation

- **OQ-origin-#2** (R2 anc exit-code policy): empirically resolved by 2026-05-01 probing across 7 commands. Observed:
  `0` clean, `1` warn/skip with `fail==0`, `2` overloaded (`fail>0` OR invocation error). The skill ships interim
  guidance "**gate on `summary.fail`, not `$?`**" with cross-link to sibling brief A3 (which will split the overloaded
  `2` slot). The earlier draft contract (`1` for any non-pass, `2` for invocation error only) is empirically wrong and
  retracted.
- **OQ-origin-#5** (R10 trigger-keyword traffic audit): U10 runs the audit at implementation time using a qmd query
  against the skills collection and manual review of `Triggers on:` entries.
- **`anc.dev/badge` placement convention** (R7 dependency): if the page does not enumerate placement values when U9
  lands, U9 proposes one (`top-of-readme` after the H1) and the proposal is mirrored to sibling brief A4.
- **R14 CI integration**: PR 7 ships the manual dogfood gate (U25) plus a `CONTRIBUTING.md` note pinning re-runs to
  edits of either script. Wiring the audit into CI as a regression gate (`gh workflow` entry running `anc check
  --binary` on every PR touching `bin/` or `scripts/`) is **explicitly out of scope** for this plan and belongs to a
  follow-up CI-hardening PR. The manual gate is sufficient for the v0.4.0 release; CI integration is the next
  compounding step.
- **R14 audit-profile choice** (`posix-utility` vs alternatives): U25 audits both scripts under `posix-utility`. If
  either script's primary surface turns out to be more idiomatic under a different profile (unlikely — both are
  stdin-quiet, stdout-emitting, no TUI), the audit-profile selection note in `references/audit-profile-selection.md`
  (U6) is the authoritative source. Pick is empirically resolved at U25 implementation time; if a different profile is
  needed, the U25 verification section captures the rationale.

---

## Implementation Units

Units are grouped by phase (= PR). Each unit is a landable atomic commit within its PR. U-IDs are stable; reordering or
splitting preserves them.

### Phase 1 — PR 1: Skill-side determinism (R1–R9)

- U1. **R9: SKILL.md restructure + getting-started.md dedup**

**Goal:** Reorder SKILL.md so the first runnable command is `anc check` (not `bash bin/check-update`). Eliminate
cross-file duplication (install block, four-step loop, parallel index tables). Land the new section skeleton so U2–U9
fill in their own slots without re-homing.

**Requirements:** R9.

**Dependencies:** None. (Runs first per OQ-origin-#4.)

**Files:**

- Modify: `SKILL.md`
- Modify: `getting-started.md`

**Approach:**

- New SKILL.md section order: Preamble → `## Quick Start` (placeholder for U5's inline scorecard sample + the canonical
  `anc check --output json . > scorecard.json` line) → `## Subcommand index` (placeholder for U21) → `## Anc contract`
  (placeholder for U4) → `## The anc loop` (conceptual four steps; U7 folds in termination rule, U8 folds in spec-skew)
  → `## The seven principles` index → `## Audit profile selection` (placeholder for U6) → `## Common situations`
  (one-paragraph pointer to `references/runbook.md`, U9 + U21 fill) → Pointer block → `## Update-check` (demoted to
  one-paragraph footnote pointing at `references/update-check.md`) → Sources.
- Delete the duplicated install block in SKILL.md `## Compliance checking` (lives in `getting-started.md` already).
- Delete the duplicated four-step loop where SKILL.md and `getting-started.md` both walk it. Canonical homes: SKILL.md
  for the conceptual loop; `getting-started.md` for the runnable bash recipe.
- Merge SKILL.md's `## Implementation guidance` pointer table and `getting-started.md`'s `## Where things live` table
  into one canonical table in `getting-started.md`. SKILL.md keeps a short pointer paragraph.
- Keep SKILL.md under 200 lines after the cleanup (origin R9 acceptance).

**Patterns to follow:** Existing SKILL.md tone and table formatting (kept consistent with `agentnative-spec` skill).
`getting-started.md`'s "Where things live" table format.

**Test scenarios:**

- Verification: `grep -c 'brew install brettdavies/tap/agentnative' SKILL.md getting-started.md` returns 0 in
  `SKILL.md`, ≥1 in `getting-started.md` (origin R9 acceptance).
- Verification: `grep -c 'anc skill install claude_code' SKILL.md getting-started.md` returns hits in exactly one file
  (`getting-started.md`).
- Verification: First runnable command in SKILL.md (first fenced block after the preamble) is `anc check`, not `bash
  bin/check-update`.
- Verification: `wc -l SKILL.md` ≤ 200 after the full PR 1 lands (re-checked at end of PR 1, not at U1 alone since U2–U9
  add ~70 lines).
- Verification: `## Update-check` is no longer the second top-level heading; appears near the bottom.
- Verification: `markdownlint-cli2 SKILL.md getting-started.md` passes.

**Verification:** Reordered SKILL.md presents Quick Start as section #2; install + four-step loop appear in exactly one
canonical location each; markdownlint clean.

---

- U2. **R8: SKILL.md `allowed-tools` frontmatter**

**Goal:** Add `allowed-tools: Bash(anc *), Read` to SKILL.md frontmatter so canonical `anc check` invocations don't
trigger permission prompts on hosts that honor the field.

**Requirements:** R8.

**Dependencies:** U1 (so U2's frontmatter edit doesn't conflict with U1's body restructure).

**Files:**

- Modify: `SKILL.md` (frontmatter only)

**Approach:** Single-line addition to YAML frontmatter. Place after `description:` and before the closing `---`. Use the
exact string `Bash(anc *), Read` so Claude Code's matcher accepts both bare `anc` and any `anc <subcommand>` invocation.

**Patterns to follow:** Skills 2.0 frontmatter convention surfaced in
`~/dev/solutions-docs/best-practices/skills-2-0-structure-progressive-disclosure-20260402.md` — `allowed-tools` is
advisory in interactive mode, enforced under headless `claude -p`.

**Test scenarios:**

- Verification: `grep -A1 '^name: agent-native-cli$' SKILL.md` shows the description; `grep '^allowed-tools:' SKILL.md`
  returns one match.
- Verification: YAML frontmatter parses (`python3 -c "import yaml,sys;
  yaml.safe_load(open('SKILL.md').read().split('---')[1])"`).

**Verification:** Frontmatter is well-formed; `allowed-tools` line present and exactly matches the canonical string.

---

- U3. **R5: anc install precondition replaces "First action: update check"**

**Goal:** First action in any session is verifying `anc` is on `PATH`. Update-check (which is for the skill bundle, not
`anc`) demotes to a referenced sub-flow.

**Requirements:** R5.

**Dependencies:** U1 (uses U1's restructured section layout — `## Update-check` as bottom footnote).

**Files:**

- Modify: `SKILL.md` (replace current `## First action: update check` content; add precondition pseudocode)
- Modify: `references/update-check.md` (only if U1 didn't already absorb the demoted bash; otherwise unchanged)

**Approach:**

- Replace SKILL.md's current `## First action: update check` body with: a one-paragraph "anc precondition" + the
  pseudocode block from origin R5 (`if ! command -v anc; then prompt user; exit; fi`) + a one-line pointer to the
  demoted update-check footnote.
- Pseudocode is markdown-fenced shell-pseudo (not literal bash), so agents read it as logic, not as a command to execute
  verbatim. Origin's exact pseudocode shape preserved.
- The demoted update-check section runs the existing `bash bin/check-update` after the precondition gate clears.

**Patterns to follow:** Existing `references/update-check.md` voice + structure for the demoted footnote.

**Test scenarios:**

- Verification: `grep -B2 -A8 '^## ' SKILL.md | head` shows the install precondition section appears before any other
  procedural section.
- Verification: SKILL.md contains the `command -v anc` pseudocode and the brew + cargo install fallback options.
- Verification: Update-check guidance in SKILL.md is a single paragraph referencing `references/update-check.md` (no
  full procedural body).

**Verification:** Cold-start agent reading SKILL.md top-to-bottom encounters the anc precondition before any `anc check`
invocation.

---

- U4. **R2: `## Anc contract` section in SKILL.md**

**Goal:** Document `anc`'s observable contract once, so agents stop inferring it from prose. Output flag policy, exit
codes (interim), `results[].status` enum, schema-version pin, stable-vs-noise subtree.

**Requirements:** R2.

**Dependencies:** U1 (placeholder section exists). Soft-dep on U5 (the inline scorecard sample lands in adjacent Quick
Start; cross-link).

**Files:**

- Modify: `SKILL.md` (add `## Anc contract` body, ~25–40 lines per origin estimate)

**Approach:**

- **Output flag policy.** One paragraph: agents always pass `--output json`; `text` is for humans (and appends a badge
  embed hint after the summary line when `badge.eligible == true`).
- **Exit codes.** Three-row table covering observed `anc 0.3.0` behavior: `0` = fully clean (no warn/fail/skip), `1` =
  warn/skip present with `summary.fail == 0`, `2` = `summary.fail > 0` **OR** invocation error (missing path, bad flag,
  unknown command). The `2` slot is overloaded — same exit code for "tool gated correctly with at least one fail" and
  "tool failed to run." Imperative gating rule: **agents writing CI gates must switch on `summary.fail`, not on `$?`**,
  since `$? == 2` cannot distinguish a real fail from an invocation error today. Footnote: "Interim contract — sibling
  brief A3 (`docs/brainstorms/2026-05-01-002`) will split the slots so `1` means `fail > 0` and `2` is reserved for
  invocation errors. Until then, treat `$?` as advisory; the gating signal is `summary.fail`."
- **`results[].status` enum.** Bulleted list naming all five values: `pass`, `warn`, `fail`, `skip`, `error`. One-line
  gloss per value.
- **Schema-version pin.** Imperative paragraph: assert `envelope.schema_version == "0.5"` before parsing. If the
  assertion fails, do not fall back to silent parse — fail explicit and prompt the user to upgrade `anc` or this skill
  bundle. Footnote naming sibling brief A1 as the durable additive replacement (`anc.schema_version` proposed).
- **Stable vs noise.** Two-list paragraph. Stable-for-CI-diffing: `summary.*`, `coverage_summary.*`, `results[*].{id,
  status, evidence}`, `audience`, `audit_profile`, `badge.eligible`, `badge.score_pct`. Timestamp/run-noise (don't
  diff): `run.started_at`, `run.duration_ms`, `run.invocation`, `tool.version`, `anc.version`. Sibling brief A5 will
  eventually offer `--stable` flag.

**Patterns to follow:** Stable-vs-noise framing from
`~/dev/solutions-docs/best-practices/cli-structure-for-machines-typed-json-fields-over-display-strings-2026-04-20.md`.

**Test scenarios:**

- Verification: `grep -c '^## Anc contract' SKILL.md` returns 1.
- Verification: Section enumerates all five status values (`pass`, `warn`, `fail`, `skip`, `error`).
- Verification: Section names `schema_version` as the pin path (not `tool.schema_version` or `anc.schema_version`).
- Verification: Exit-code table has three rows, footnoted as interim with cross-link to sibling brief.
- Verification: Exit-code table is empirically validated at unit time by running `anc check --output json --command
  <cmd>` against at least three commands covering `summary.fail == 0` and `summary.fail > 0` cases (e.g. `rg`, `cat`,
  `echo`); the documented `$?` value matches observed behavior, the imperative `gate on summary.fail, not $?` line is
  present.
- Verification: The schema-pin example (`envelope.schema_version == "0.5"`) matches the live `anc 0.3.0` value.

**Verification:** An agent writing a CI gate that fails on regression can do so without guessing — exit codes
documented, status enum complete, schema-pin path concrete, stable subtree enumerated.

---

- U5. **R1: Three-placement worked scorecard samples**

**Goal:** Three coordinated samples sized to their location: SKILL.md inline (~12–15 lines top-level shape),
`getting-started.md` inline (~3–5 lines invocation→output), `references/scorecard-shape.md` (~50–60 lines exhaustive,
every top-level field, one `results[]` entry per status value, every audit-profile category, full metadata). All taken
from a live `anc 0.3.0 check --output json` run, byte-faithful where possible.

**Requirements:** R1.

**Dependencies:** U1 (Quick Start placeholder), U4 (links to anc contract section). Soft-dep on U6 (audit-profile
decision table is adjacent).

**Files:**

- Create: `references/scorecard-shape.md`
- Modify: `SKILL.md` (Quick Start fenced block)
- Modify: `getting-started.md` ("existing CLI" loop section, after the canonical `anc check --output json . >
  scorecard.json` line)

**Approach:**

- **`references/scorecard-shape.md` (exhaustive).** One H1 + short preamble + a single fenced JSON block of the full
  envelope with every top-level field populated. Use a synthesized but realistic envelope (start from `anc check
  --output json --command rg`, then construct extra `results[]` entries to cover all five status values, all four
  audit-profile categories, and an `audience: agent-optimized` example). Below the JSON block, a per-field gloss table:
  `field path → type → semantics → stable for CI?`. Note that `audience` and `audience_reason` are top-level (not inside
  `audit_profile`).
- **SKILL.md inline (~15 lines).** Truncated envelope showing only `summary`, `coverage_summary`, `badge`, and one
  `results[]` entry. Placed immediately after the Quick Start `anc check ...` line. Comment ellipses (`/* ... */`) where
  fields are elided.
- **`getting-started.md` inline (~5 lines).** Even shorter — just `coverage_summary` + `badge.eligible` +
  `badge.embed_markdown`. Placed right after the `anc check --output json . > scorecard.json` recipe.
- **Field-name discipline.** All three samples use `results[].id` (the actual envelope field). The per-field gloss table
  in `references/scorecard-shape.md` carries an explicit "**check id vs requirement id**" note: envelope `results[].id`
  is a CHECK identifier (`p3-help`, `p1-flag-existence`, `p6-sigpipe`); spec frontmatter `requirements[].id` is a
  REQUIREMENT identifier (`p1-must-no-interactive`, `p2-must-output-flag`). The two are different namespaces. Each
  principle file's body prose maps check ids to the requirements they verify (e.g. p6's "Measured by check IDs
  `p6-sigpipe`, …"). To resolve a finding's spec text, read principle prose, not frontmatter alone. Sibling brief A2
  (`anc explain <id>`) is the durable resolver once it ships.
- **Live envelope capture at unit time.** Implementer runs `anc check --output json --command rg` at U5 implementation
  time and uses that output as the byte-faithful base for the exhaustive sample. Do not rely on a snapshot from this
  plan — `anc` may have moved between plan-write and unit-implementation; live capture is the freshness guarantee.
- **`audience` semantic capture.** Before the per-field gloss table goes final, run `anc check --output json` against at
  least four targets covering the observed `audience` values (sampled today: `agent-optimized`; null cases also
  observed). Enumerate the value set in the gloss row and document when `audience_reason` is present (today: when
  `audience == null`). If the value space is open-ended or not stable enough to enumerate, the gloss row says so
  explicitly rather than implying enumeration completeness.

**Patterns to follow:** `references/update-check.md`'s preamble + fenced-block voice. Origin R1 sample-sizing rules.

**Test scenarios:**

- Verification: `references/scorecard-shape.md` JSON block parses (`python3 -c "import json;
  json.load(open('references/scorecard-shape.md'))"` after extracting the block, or `python3
  scripts/extract-fenced-json.py references/scorecard-shape.md`).
- Verification: Exhaustive sample contains at least one `results[]` entry per `status` value (`pass`, `warn`, `fail`,
  `skip`, `error`).
- Verification: `audit_profile` is a scalar field — only one value per envelope. The exhaustive sample shows ONE
  `audit_profile` value plus a prose annotation (under the per-field gloss row) enumerating all four possible values
  (`human-tui`, `posix-utility`, `diagnostic-only`, `file-traversal`) and noting the field is set per-invocation by
  `--audit-profile <category>`.
- Verification: Per-field gloss row for `audience` enumerates the observed value set (sampled `agent-optimized`; null
  cases) and notes when `audience_reason` is populated. If the value space is intentionally open, the row says so.
- Verification: All three samples use `id` (not `requirement_id`) for result entries.
- Verification: Field path table in `references/scorecard-shape.md` enumerates `summary, coverage_summary, badge,
  results, audit_profile, audience, audience_reason, tool, anc, run, target, schema_version, spec_version` (13 top-level
  fields).
- Verification: SKILL.md inline sample fits in ~15 lines.
- Verification: `getting-started.md` inline sample fits in ~5 lines.
- Covers AE: An agent reading only `references/scorecard-shape.md` can write a parser handling all five status values
  and all four audit-profile categories without reading `anc` source (origin R1 acceptance).

**Verification:** Three samples present at three locations; each sized for its job; all field names match `anc 0.3.0`
reality; JSON parses; exhaustive sample is the canonical one for parser authors.

---

- U6. **R3: `--audit-profile` decision table + extended reference**

**Goal:** A 4-row decision table in SKILL.md (one row per profile) + an extended `references/audit-profile-selection.md`
covering the hybrid-tool rule.

**Requirements:** R3.

**Dependencies:** U1 (placeholder section).

**Files:**

- Modify: `SKILL.md` (`## Audit profile selection` section, ~10 lines)
- Create: `references/audit-profile-selection.md` (~40 lines)

**Approach:**

- **SKILL.md table.** Four rows: `human-tui`, `posix-utility`, `diagnostic-only`, `file-traversal` (reserved). Columns:
  when to pick (one-line rule), example tool, what gets suppressed. Glosses paraphrased from `anc check --help`'s value
  list — but agents are pointed at `--help` for the authoritative description.
- **SKILL.md `### Worked examples` sub-section** (added immediately under the 4-row table, ~10 lines). Three concrete
  hybrid-tool worked examples with explicit profile picks, addressing the determinism-acceptance concern that one-line
  rules in 4 rows won't converge agents on hybrid cases:
- *Example 1 — `lazygit` (pure TUI):* pick `human-tui`. Reason: the binary's primary entry-point is the interactive TTY
  interface; no batch / stdin-piped mode exists.
- *Example 2 — `cat` with optional TUI mode:* pick `posix-utility`. Reason: stdin-primary is the documented main use;
  any TUI rendering is a secondary surface, scope-out per the primary-entry-point rule.
- *Example 3 — A diagnostic CLI with one TUI rendering subcommand (e.g. `mytool dashboard`) and otherwise read-only
  introspection:* pick `diagnostic-only`. Reason: the tool's documented main use is read-only diagnosis; the dashboard
  subcommand is a secondary surface, scope-out and document the suppression in the README's Limitations section.
- **`references/audit-profile-selection.md` (extended).** Restate the four profiles with deeper one-paragraph
  descriptions, then a "**Hybrid project rule**" sub-section: when a tool mixes a TUI-rendering subcommand with a
  stdin-piped batch mode (or a Rust binary with shell-helper subcommands), the rule is: scope the audit profile to the
  primary entry-point and leave secondary surfaces uncovered. Cross-link to sibling brief A6 (proposed `--audit-profile
  <subcmd>=<profile>` repeatable flag) as the durable composition path.
- "Three different agents reading the table for the same tool pick the same profile" (origin R3 acceptance) — frame the
  rule deterministically: "primary entry-point" defined as the subcommand documented as the tool's main use in its
  README, or the bare invocation behavior if no README clarifies. The worked-examples sub-section is the empirical
  determinism test — three different agents reading the table + the three worked examples for a fourth hybrid tool
  should converge on the same pick.

**Patterns to follow:** Existing `references/framework-idioms-other-languages.md` table-with-paragraph-context style.

**Test scenarios:**

- Verification: SKILL.md `## Audit profile selection` section contains exactly four rows (one per profile) plus a `###
  Worked examples` sub-section with three hybrid-tool examples and explicit profile picks.
- Verification: `references/audit-profile-selection.md` contains a `### Hybrid project rule` (or equivalent)
  sub-section.
- Verification: Cross-link to sibling brief A6 present in the extended file.
- Verification: The four profile names in the table match `anc check --help`'s `--audit-profile` value list
  (`human-tui`, `posix-utility`, `diagnostic-only`, `file-traversal`).
- Verification (empirical determinism): give the SKILL.md `## Audit profile selection` section (table + worked examples)
  to 3 agents on a fourth hybrid tool not in the worked examples (e.g. `nvtop` — TUI by default but supports stdin-piped
  data); record their picks. If any disagreement, revise the worked examples or the rule before merge.

**Verification:** Decision table renders cleanly; hybrid-tool rule is explicit and deterministic; cross-links hold.

---

- U7. **R4: Loop termination rule for warn / should**

**Goal:** Folded into `## The anc loop` (placed by U1): one paragraph explicitly stating that `must` violations gate the
loop, `warn`s are advisory, stop iterating when `badge.eligible == true`.

**Requirements:** R4.

**Dependencies:** U1.

**Files:**

- Modify: `SKILL.md` (`## The anc loop` step 3 / 4 boundary)

**Approach:**

- One paragraph (~5–10 lines) inserted at the end of step 3 (Re-check) or as a short coda before step 4 (Claim the
  badge). Three bullets: (1) `must` gates the loop — continue until `must.verified == must.total`. (2) `warn`s are
  advisory — once `badge.eligible == true` (≥80%), stop iterating; do not push warns to pass unless the user explicitly
  asks. (3) `error` (the run-failure status, distinct from `fail`) means re-run — see runbook (U9).

**Patterns to follow:** Existing imperative voice in `## The anc loop`.

**Test scenarios:**

- Verification: `## The anc loop` section contains the words `advisory` and `badge.eligible` near step 3 / 4.
- Verification: The termination rule explicitly distinguishes `error` (run-failure) from `fail` (gating-violation).

**Verification:** An agent in "fix mode" reading SKILL.md stops when the badge clears, not when every warn clears.

---

- U8. **R6: Spec-skew fallback paragraph**

**Goal:** Step 2 of `## The anc loop` (Fix.) carries a short paragraph or table row explaining the **two** failure modes
agents hit when looking up a finding's `id`: (a) the namespace mismatch (envelope `id` is a check id, not a requirement
id), and (b) actual spec drift when the bundle's vendored `spec/principles/` is older than `anc`.

**Requirements:** R6.

**Dependencies:** U1, U4 (the check-id-vs-requirement-id namespace note from U4 is referenced).

**Files:**

- Modify: `SKILL.md` (`## The anc loop` step 2 — Fix.)

**Approach:**

- ~8–12 line paragraph inserted at the end of step 2. Two-part structure:
- **Part A — namespace, not skew (always check this first).** The envelope's `results[].id` is a CHECK id (e.g.
  `p3-help`, `p1-flag-existence`, `p6-sigpipe`). The spec's `requirements[].id` is a REQUIREMENT id (e.g.
  `p1-must-no-interactive`, `p2-must-output-flag`). They are different namespaces. To resolve the spec text the check
  references, read the matching principle file's body prose (e.g. `spec/principles/p6-*.md`'s "Measured by check IDs
  `p6-sigpipe`, …" mapping line) — NOT the principle's frontmatter `requirements[]` block alone. If `anc explain <id>`
  is available (sibling brief A2), prefer it as the authoritative resolver.
- **Part B — actual spec skew (only if Part A's principle file doesn't reference the check id).** (1) Likely cause —
  `anc` shipped against a newer spec than this bundle vendors. (2) Interim fix — re-run `scripts/sync-spec.sh` to
  refresh the vendored spec, or fetch the missing `spec/principles/p<N>-*.md` from `agentnative` `main`. (3) Non-fix —
  do not hallucinate a spec definition; better to surface the gap to the user.

**Patterns to follow:** Existing `## The anc loop` step prose voice; `references/update-check.md` voice for the
cross-link footnote.

**Test scenarios:**

- Verification: SKILL.md step 2 contains both `scripts/sync-spec.sh` (interim fix) and the cross-link to sibling brief
  A2 (`anc explain`).
- Verification: The paragraph explicitly says "do not hallucinate" or equivalent (origin R6 non-fix bullet).
- Verification: Part A (namespace) appears before Part B (skew) and uses concrete examples — `p3-help` as a check id,
  `p1-must-no-interactive` as a requirement id — to make the namespace distinction unambiguous.
- Verification: The paragraph names "principle file body prose" (NOT "frontmatter alone") as the resolution path.

**Verification:** An agent hitting the spec-skew case has a deterministic next step that isn't "read source".

---

- U9. **R7: `references/runbook.md` (common situations)**

**Goal:** A new reference file with one-paragraph entries (≤4 lines each) per common situational dead-end. Linked from
SKILL.md `## Common situations` (the placeholder U1 created).

**Requirements:** R7.

**Dependencies:** U1 (SKILL.md pointer in place), U4 (anc contract referenced from runbook entries).

**Files:**

- Create: `references/runbook.md`
- Modify: `SKILL.md` (`## Common situations` paragraph, links to runbook)

**Approach:**

- Five entries from origin R7:

1. **`badge.embed_markdown` placement.** Default convention: top of README, after the H1 title, alongside CI badges.
   Override only if `anc.dev/badge` publishes a different convention (check the page; if it doesn't enumerate placement,
   this entry's default applies and the proposal mirrors to sibling brief A4).
2. **Should I commit `scorecard.json`?** Default no (artifact, regenerable from `anc check`). Override only for CI
   gating snapshots. If you commit, gitignore `run.*` fields by post-processing or use the eventual `anc check --stable`
   (sibling brief A5).
3. **`anc check .` vs `--binary` vs `--source`.** `anc check .` runs both source and behavioral analysis; `--binary`
   skips source (use when scoring a pre-built binary that isn't in this repo); `--source` skips behavioral (use when
   source-only feedback is wanted, e.g. PR review on a code-only diff).
4. **`anc` panics or returns malformed JSON.** Pointer to `<https://github.com/brettdavies/agentnative-cli/issues>` with
   the `anc --version` + invocation. Do not retry blind; retrying a panicking `anc` will produce the same panic with
   timestamp churn and waste agent time.
5. **`anc skill install <host>` host not in registry.** Cross-link to `getting-started.md`'s manual `git clone --depth
   1` fallback.

- Each entry: ≤4 lines body + a one-line "see also" pointer to the relevant origin requirement, sibling brief item, or
  other reference file. Goal is fast index, not deep prose.

**Patterns to follow:** `references/update-check.md` short-section voice; `getting-started.md` Q&A table for
cross-links.

**Test scenarios:**

- Verification: `references/runbook.md` contains all five entries; each entry body is ≤4 lines (excluding heading and
  "see also" pointer).
- Verification: SKILL.md `## Common situations` section is one paragraph containing the link to `references/runbook.md`.
- Verification: Markdownlint clean; cross-links resolve (no broken `[text](path)` pointers).
- Verification: Entry 1's badge-placement default cross-references `anc.dev/badge` and sibling brief A4.

**Verification:** Agents stop generating issues that ask FAQs already covered (origin R7 acceptance).

---

- U21. **R13: Subcommand index + target-resolution runbook entry**

**Goal:** Document the full `anc` subcommand surface in SKILL.md so agents stop punting to `anc --help` for basic
discovery; expand `references/runbook.md`'s target-resolution entry to cover all four target modes (`.`, `--binary`,
`--source`, `--command <name>`) with resolution rules.

**Requirements:** R13.

**Dependencies:** U1 (placeholder `## Subcommand index` section in place), U9 (`references/runbook.md` exists; U21
expands its target-resolution entry).

**Files:**

- Modify: `SKILL.md` (`## Subcommand index` section, ~10 lines)
- Modify: `references/runbook.md` (replace U9's entry 3 with an expanded version, ~10–15 lines)

**Approach:**

- **SKILL.md `## Subcommand index`.** A 5-row table placed between `## Quick Start` and `## Anc contract` (U1's section
  order). Columns: subcommand, one-line description, when to use. Rows:

1. `check` — audit a CLI for agent-readiness (the canonical workflow; default when bare `anc <path>` is invoked).
2. `generate` — produce build artifacts (e.g., coverage matrix); not part of the agent loop.
3. `skill install <host>` — install this skill bundle into a host's canonical skills directory (six hosts supported; see
   `getting-started.md`).
4. `completions` — emit shell completions for bash / zsh / fish / PowerShell.
5. `help [subcommand]` — print help; equivalent to `--help`.

- Footnote under the table: `anc <path>` (no subcommand) is shorthand for `anc check <path>` — see `anc --help` for the
  exact aliasing rules. Bare `anc` (no arguments) prints help and exits 2.
- Subcommand list **must** be verified at unit time by running `anc --help` and reconciling the table against the live
  `Commands:` block. If `anc` ships a new subcommand between plan-write and U21 implementation, add it (or trim) so the
  table stays current.
- **`references/runbook.md` target-resolution entry (replaces U9's entry 3).** Four-mode coverage:
- **Project mode** (`anc check .`) — runs both source analysis (Rust-only today) and behavioral checks. Default when a
  path argument is given.
- **`--binary`** — runs only behavioral checks against a pre-built binary at the given path. Use when scoring a binary
  that isn't built from source you control, or when source analysis would surface noise irrelevant to runtime behavior.
- **`--source`** — runs only source analysis (Rust source-tree scanning). Use when source-only feedback is wanted (e.g.,
  PR review on a code-only diff before a binary is rebuilt).
- **`--command <name>`** — resolves a binary from `PATH` and runs behavioral checks against it. The cross-repo audit
  mode the skill's actual audience uses (auditing someone else's tool). Behavioral checks only — `anc` doesn't analyze
  source it didn't find via path resolution.
- Cross-link the entry to `anc check --help` for the authoritative flag list.

**Patterns to follow:** Existing `getting-started.md` "Where things live" table format for the SKILL.md subcommand
index; existing `references/update-check.md` short-section voice for the runbook entry.

**Test scenarios:**

- Verification: SKILL.md `## Subcommand index` section contains a 5-row table covering at minimum `check`, `generate`,
  `skill install`, `completions`, `help`.
- Verification: Table content matches `anc --help` `Commands:` block at unit time (`diff` between table subcommand names
  and live `anc --help` output shows zero unexpected omissions).
- Verification: `references/runbook.md` target-resolution entry names all four modes (`.`, `--binary`, `--source`,
  `--command <name>`) and gives at least one concrete use case per mode.
- Verification: `--command <name>` is named explicitly as the cross-repo audit mode (the skill's primary audience per
  origin §Problem framing).
- Verification: SKILL.md stays under 200 lines after U21 lands (R9 ceiling preserved).
- Verification: Markdownlint clean; cross-links resolve.

**Verification:** A first-time agent reading SKILL.md cold can enumerate the subcommand surface without running `anc
--help` and pick the right `--binary` / `--source` / `--command` mode for the audit task at hand.

---

### Phase 2 — PR 2: Frontmatter polish (R10)

- U10. **R10: SKILL.md frontmatter audit**

**Goal:** Audit `description`, `Triggers on` keyword list, and `SKIP when` clause; document kept-as-is decisions; ensure
no `argument-hint` / `model:` / `disable-model-invocation` fields are added.

**Requirements:** R10.

**Dependencies:** U2 (frontmatter already touched for `allowed-tools`; U10 edits adjacent fields without conflict).

**Files:**

- Modify: `SKILL.md` (frontmatter `description` only)

**Approach:**

- **Triggers audit (resolves OQ-origin-#5).** Run `qmd query "agent-native" --collection skills` and `qmd query "anc
  CLI" --collection skills` to surface what queries the skill actually fires on in real traffic. Manual review of
  existing `Triggers on:` list; drop any keyword that hasn't fired discovery in practice; add ones that have come up in
  skill-side questions but aren't there. Stay under 1024 chars total.
- **SKIP clause sharpening.** Audit for collisions with `compound-engineering` and `create-agent-skills`. Today's clause
  excludes TUI-app authoring and non-CLI library work; sharpen to also explicitly exclude general "skill authoring"
  (route to `create-agent-skills`) and general "compound engineering workflows" (route to `compound-engineering`).
- **Kept-as-is decisions** (per origin R10 in-scope notes): document in this plan (not in SKILL.md frontmatter) that
  `name` stays, `argument-hint` is not added (background-knowledge skill), `model:` is not pinned (let host decide),
  `disable-model-invocation` is not added (auto-load is correct).

**Patterns to follow:** `~/dev/solutions-docs/best-practices/skills-2-0-structure-progressive-disclosure-20260402.md` —
frontmatter discoverability rules.

**Test scenarios:**

- Verification: `description` field is ≤1024 chars (`python3 -c "import yaml;
  d=yaml.safe_load(open('SKILL.md').read().split('---')[1]); assert len(d['description']) <= 1024,
  len(d['description'])"`).
- Verification: `Triggers on:` keyword list in description does not contain `Slack`, `email`, or other unrelated noise
  (sample sanity check).
- Verification: `SKIP when` clause names `compound-engineering` and `create-agent-skills` as explicit redirects.
- Verification: `name`, `description`, `allowed-tools` are the only frontmatter keys; no `argument-hint`, `model`, or
  `disable-model-invocation`.

**Verification:** Frontmatter passes a fresh `create-agent-skills` audit at the "well-tuned" tier; kept-as-is decisions
documented in this plan's Key Technical Decisions or U10 commit message.

---

### Phase 3 — PR 3: Rust idioms consolidation (R12)

- U11. **R12: Merge `framework-idioms.md` + `rust-clap-patterns.md` → `references/rust-clap.md`**

**Goal:** One canonical Rust idioms reference. Adopt `framework-idioms.md`'s Free / Must / Anti-patterns scaffold; fold
every file-unique nugget from `rust-clap-patterns.md` into the appropriate principle's bucket.

**Requirements:** R12.

**Dependencies:** U1 (SKILL.md's pointer table merged into `getting-started.md`'s Where things live; U11 updates that
single table). Independent of all PR 1 + PR 2 unit content otherwise.

**Files:**

- Create: `references/rust-clap.md`
- Delete: `references/framework-idioms.md`
- Delete: `references/rust-clap-patterns.md`
- Modify: `getting-started.md` (Where things live table — point at the new file)
- Modify: `SKILL.md` (any pointer paragraph referencing the old files — update or delete)

**Approach:**

- One H2 per principle (P1–P7). Within each, three H3 buckets in this order: **Free from clap**, **Must implement**,
  **Anti-patterns**. Per-bucket prose folds in:
- **P1 Must-implement:** the FalseyValueParser detail, four-flag `--output / --quiet / --no-interactive / --timeout`
  global pattern (xurl-rs / bird precedent), `cli.no_interactive || !std::io::stdin().is_terminal()` gate.
- **P2 Must-implement:** explicitly enumerate Text / Json / **Jsonl** as the three OutputFormat variants (preserves the
  file-unique Jsonl nugget). OutputConfig threading; format-aware error printing.
- **P3 Must-implement:** `after_help` (not `about` or `long_about`); env vars surface automatically via `env` attribute;
  per-subcommand `after_help`.
- **P4 Must-implement:** `try_parse()` not `parse()`; `thiserror` enum; `exit_code()` method **and** `kind()` method
  (preserves file-unique nugget); main-only `process::exit()` (preserves file-unique rule); sysexits 77 / 78 / 74
  mappings.
- **P5 Must-implement:** `--dry-run` on every write subcommand; `--force` / `--yes` on destructive ops; idempotent
  design; read/write categorization rule.
- **P6 Must-implement:** SIGPIPE fix; `IsTerminal`; `NO_COLOR` + `TERM=dumb`; clap_complete; three-tier dependency
  gating. Plus a new H3 sub-section before the Free/Must/Anti-patterns triplet: **Flags vs subcommands taxonomy** — five
  bullets: subcommands for operations, nested subcommands for namespaced operations, global flags for cross-cutting
  modifiers, local flags for command-specific modifiers, both flag and subcommand for universal meta-commands like
  `--help` / `--version`. (Preserves the largest file-unique nugget.)
- **P7 Must-implement:** `diag!` macro; `--quiet`; `--limit` / `--max-results` with `clamp()`; `--timeout`; output
  clamping with truncation diagnostic.
- Closing pointer table: link to `references/framework-idioms-other-languages.md` (preserved from `framework-idioms.md`)
- new pointer to `templates/cargo-toml.md` (which lands in PR 4).
- Concrete-example anchors: explicit references to xurl-rs and bird as exemplar codebases (preserved from
  `rust-clap-patterns.md`).
- Estimated final size ~250 lines, replacing 346 lines (origin R12 estimate).

**Patterns to follow:** `framework-idioms.md` three-bucket scaffold; `rust-clap-patterns.md` per-principle paragraph
density.

**Test scenarios:**

- Verification: `git status` after the unit shows `references/framework-idioms.md` and
  `references/rust-clap-patterns.md` as deleted, `references/rust-clap.md` as new.
- Verification: `wc -l references/rust-clap.md` is between 200 and 300 (origin estimate ~250).
- Verification: `grep -c '^## P[1-7]' references/rust-clap.md` returns 7 (one per principle).
- Verification: P6 section contains both the **Flags vs subcommands taxonomy** sub-section and the SIGPIPE / IsTerminal
  / clap_complete coverage.
- Verification: P4 section contains both `exit_code()` and `kind()` method names.
- Verification: P2 section enumerates `Text`, `Json`, `Jsonl` (all three OutputFormat variants).
- Verification: `grep -rn 'framework-idioms\.md\|rust-clap-patterns\.md' SKILL.md getting-started.md references/
  templates/` returns 0 hits (no broken links).
- Verification: `grep -n 'rust-clap\.md' SKILL.md getting-started.md` returns ≥1 hit each (new pointers in place).
- Verification: `markdownlint-cli2 references/rust-clap.md` passes.
- **Verification (token-set diff — pre-deletion gate).** Before deleting the source files, compute the symmetric
  difference between merged-file content tokens and source-file content tokens, and review every loss explicitly:

```sh
# Extract H3 + H4 headings, named identifiers (function/method/crate names),
# and code-fenced spans from both source files; compare against merged file.
extract_tokens() {
  rg -oE '^####? .+|`[A-Za-z_][A-Za-z0-9_:!]+`|`#\[[^]]+\]`' "$1" \
    | sort -u
}
extract_tokens references/framework-idioms.md      > /tmp/src-a.tokens
extract_tokens references/rust-clap-patterns.md    > /tmp/src-b.tokens
extract_tokens references/rust-clap.md             > /tmp/merged.tokens
sort -u /tmp/src-a.tokens /tmp/src-b.tokens        > /tmp/source-union.tokens
# Tokens present in source union but absent in merged (with paraphrase tolerance):
comm -23 /tmp/source-union.tokens /tmp/merged.tokens > /tmp/lost.tokens
wc -l /tmp/lost.tokens
```

  Review every line in `/tmp/lost.tokens`. For each lost token: either confirm it was an intentional drop (prose
  duplication, redundant phrasing) AND record the rationale in the PR description, OR add the missing content to the
  merged file before merge. Token-set difference of zero is not the goal (paraphrase tolerance is real); reviewed-loss
  is the goal — every loss is a deliberate choice with a recorded reason.

**Verification:** A diff between "what's in the merged file" and "union of the two source files" shows no information
loss other than prose duplication; SKILL.md and `getting-started.md` link to the merged file; both originals are
deleted.

---

### Phase 4 — PR 4: Rust starter completion (R11.1, R11.2, R11.3)

- U12. **R11.1: `templates/cargo-toml.md`**

**Goal:** Drop-in `[dependencies]` block for the Rust starter. Today an agent copying `clap-main.rs` has to know to add
clap (with `derive` + `env`), serde, serde_json, thiserror, libc, clap_complete. A copy-paste TOML is faster.

**Requirements:** R11 (item 1).

**Dependencies:** U11 (`rust-clap.md` cross-link from this template).

**Files:**

- Create: `templates/cargo-toml.md`

**Approach:**

- File starts with a one-paragraph preamble: "Drop-in `[dependencies]` and `[features]` for a greenfield Rust CLI built
  from `templates/clap-main.rs`. Append to your `Cargo.toml` after `cargo init`."
- A single fenced TOML block with: clap (`features = ["derive", "env"]`), serde (`features = ["derive"]`), serde_json,
  thiserror, libc (`#[cfg(unix)]` only — annotated), clap_complete. Pin version constraints loosely (`"4"` for clap,
  `"1"` for serde) per Cargo convention.
- Followed by a "Why each crate" bulleted list — one line per crate naming the principle it serves (clap → P3, serde +
  serde_json → P2, thiserror → P4, libc → P6 SIGPIPE, clap_complete → P6 completions).
- Closes with a one-line pointer to `references/rust-clap.md` and `references/project-structure.md`.

**Patterns to follow:** Existing `templates/agents-md-template.md` voice (preamble + fenced block + "why" prose).

**Test scenarios:**

- Verification: TOML block parses (`python3 -c "import tomllib; tomllib.loads(open('templates/cargo-toml.md').read())"`
  after extracting the fenced block, or just `cargo init /tmp/test-toml && (cd /tmp/test-toml && python3 ... extract
  block ... append to Cargo.toml && cargo metadata --format-version 1)`).
- Verification: Pasting the block into a fresh `cargo init` repo and running `cargo metadata` resolves all dependencies
  without errors.
- Verification: The "Why each crate" list names every principle (P1–P7) at least once across crates.

**Verification:** A new Rust CLI can be bootstrapped with three `cp` commands and a copy-paste from this file (origin
R11 acceptance).

---

- U13. **R11.2: `templates/cli-tests.rs`**

**Goal:** `assert_cmd` patterns covering P5 mutation boundaries (idempotency, dry-run, `--yes` / `--force` distinction).
Encodes P5 by construction.

**Requirements:** R11 (item 2).

**Dependencies:** U11.

**Files:**

- Create: `templates/cli-tests.rs`

**Approach:**

- File header comment block (matching `templates/clap-main.rs` voice): what this template demonstrates, principle
  mapping, where to drop it (`tests/cli.rs` in the consumer repo).
- Test functions covering at minimum:

1. **`--dry-run` does not mutate.** Run a write subcommand twice with `--dry-run`; assert side-effect (file existence,
   exit, JSON-reported state) is unchanged.
2. **`--dry-run` reports what it would do.** Same write subcommand with `--dry-run --output json`; assert the JSON
   envelope contains a `would_*` field or equivalent indicating the mutation is described.
3. **Idempotent create.** Run a create subcommand twice without `--force`; second call succeeds without error and
   reports "already exists" rather than failing.
4. **`--force` overrides confirmation gate.** Run a destructive subcommand with `--no-interactive` (no `--force`);
   assert exit code != 0 and a clear error in JSON. Re-run with `--force --no-interactive`; assert exit 0.
5. **`--yes` accepts implicit confirmation.** Run a destructive subcommand with `--yes`; assert exit 0 and the
   destructive op completed.

- Use `assert_cmd::Command` with `.assert().success()` / `.failure()`. Use `tempfile::tempdir` for filesystem isolation.
- `// TODO: replace 'mytool' with your binary name` markers throughout.

**Patterns to follow:** xurl-rs and bird `tests/` conventions (cited in `references/rust-clap.md`); `assert_cmd`
documentation idioms.

**Test scenarios:**

- Verification: `cargo init --name dummy /tmp/dummy-cli && cp templates/cli-tests.rs /tmp/dummy-cli/tests/cli.rs && (cd
  /tmp/dummy-cli && cargo check --tests)` succeeds (compile-only smoke; tests will fail without a binary, but the file
  should compile).
- Verification: File contains all five test functions named distinctly.
- Verification: File header comment names P5 explicitly.

**Verification:** Compile-only smoke passes; an author can copy this file, replace `mytool` with their binary, and have
a working P5-covering test suite.

---

- U14. **R11.3 (repurposed): Document the embedded-schema extraction path**

**Goal:** Tell agents how to obtain the canonical scorecard JSON Schema from the `anc` binary itself (via `anc generate
scorecard-schema`), rather than vendoring a hand-written copy that would drift the moment upstream bumps. Cross-link to
the upstream plan so readers see where the canonical schema lives.

**Requirements:** R11 item 3, repurposed away from "ship a vendored schema" to "document the canonical extraction path"
after upstream `agentnative-cli` plan
[`2026-04-30-002-feat-scorecard-json-schema-plan.md`](../../agentnative-cli/docs/plans/2026-04-30-002-feat-scorecard-json-schema-plan.md)
established that the schema is shipped embedded in the binary, derived from Rust types via `schemars`, exposed via `anc
generate scorecard-schema`.

**Dependencies:** U5 (`references/scorecard-shape.md` exists), U9 (`references/runbook.md` exists), U21 (subcommand
index calls out the `generate` family of verbs).

**Files:**

- Modify: `references/scorecard-shape.md` (new sub-section: "Validating against the canonical schema")
- Modify: `references/runbook.md` (new entry 6: "How do I validate a scorecard against the schema?")

**Approach:**

- **`references/scorecard-shape.md` sub-section** (~10 lines). Three paragraphs:
- (1) The canonical, authoritative JSON Schema for the scorecard envelope is **embedded in the `anc` binary** — derived
  from Rust struct definitions via `schemars`, regenerated at compile time, exposed via `anc generate scorecard-schema`.
  The skill bundle does **not** vendor a copy — vendoring would duplicate and drift.
- (2) Usage: `anc generate scorecard-schema --output -` writes the schema to stdout; `anc generate scorecard-schema
  --output schema.json` writes to a file; `anc generate scorecard-schema --check --output schema.json` exits non-zero if
  the file disagrees with the embedded copy (CI-friendly drift gate).
- (3) Public archival URL: `https://anc.dev/scorecard-v0.5.schema.json` (published by the `agentnative-site` archive,
  cross-repo plumbing per upstream plan). Use the verb when validating against the binary actually installed; use the
  archive URL when pinning to a specific schema version across consumers.
- **`references/runbook.md` entry 6.** ≤4-line entry: "How do I validate a scorecard against the schema? — run `anc
  generate scorecard-schema --output -` to get the schema embedded in your installed `anc`. For a published archive,
  fetch `https://anc.dev/scorecard-v{X.Y}.schema.json`. Do not vendor a copy in your repo — it will drift."
- **Soft-dep on upstream verb shipping.** When U14 lands, the `anc generate scorecard-schema` verb may not yet exist in
  the `anc` release the consumer has installed (upstream plan is `status: active` as of 2026-05-01). U14's prose handles
  this with a one-line caveat: "If your `anc` version doesn't yet ship `generate scorecard-schema`, upgrade via `brew
  upgrade brettdavies/tap/agentnative` or pin to the published archive URL."

**Patterns to follow:** `references/update-check.md`'s short-section voice; `getting-started.md` Q&A table for
cross-links.

**Test scenarios:**

- Verification: `references/scorecard-shape.md` contains a sub-section naming `anc generate scorecard-schema`.
- Verification: `references/runbook.md` contains a 6th entry on schema validation.
- Verification: Cross-link to upstream plan
  `agentnative-cli/docs/plans/2026-04-30-002-feat-scorecard-json-schema-plan.md` is present.
- Verification: Cross-link to `https://anc.dev/scorecard-v0.5.schema.json` is present.
- Verification: No file is created at `templates/scorecard-envelope.schema.json` (the vendored artifact origin R11.3
  enumerated is explicitly NOT shipped).
- Verification: Markdownlint clean.

**Verification:** An agent needing to validate a scorecard against the canonical schema runs the verb (no skill bundle
files updated when upstream bumps the schema); the skill teaches the path, the binary owns the artifact.

---

### Phase 5 — PR 5: Python starter (R11.4, R11.6a, cross-language idiom scaffolds)

- U15. **R11.4: `templates/python-click/`**

**Goal:** Minimal Python/Click starter (one main file + `pyproject.toml` snippet) encoding P1 SIGPIPE handling, P2
stdout/stderr separation, P4 exit codes. Mirror of `clap-main.rs` for the Click world.

**Requirements:** R11 (item 4).

**Dependencies:** None within PR 5.

**Files:**

- Create: `templates/python-click/main.py`
- Create: `templates/python-click/pyproject.toml.snippet`

**Approach:**

- **`main.py`** structure:
- Header comment block matching `templates/clap-main.rs` voice — what the template demonstrates, principle mapping,
  copy-paste instructions.
- SIGPIPE fix: `import signal; signal.signal(signal.SIGPIPE, signal.SIG_DFL)` in `if __name__ == '__main__':` guard,
  wrapped `try / except AttributeError` for Windows compatibility. (P6.)
- Click CLI scaffold with one read subcommand (`status`) and one write subcommand (`apply`) demonstrating `--dry-run`
  (`@click.option('--dry-run', is_flag=True, ...)`). (P5.)
- `--output text|json|jsonl` global option using `click.Choice`. (P2.)
- `--quiet`, `--no-interactive`, `--timeout` global options. (P1, P7.)
- Custom exit codes: `EX_USAGE = 2`, `EX_AUTH = 77`, `EX_CONFIG = 78`, `EX_IOERR = 74` (sysexits). (P4.)
- JSON-aware error printing: when `--output json` is set and an error occurs, emit `{"error": true, "kind": ...,
  "message": ..., "code": ...}` to stderr; exit with the right code.
- Diagnostic output gated behind `--quiet` and `--output != text`: `def diag(msg, ctx): if not ctx.quiet and ctx.format
  == 'text': click.echo(msg, err=True)`. (P7.)
- **`pyproject.toml.snippet`** is a partial pyproject.toml fragment authors append: `[project] name = "mytool"`,
  `[project.scripts] mytool = "mytool.main:cli"`, `[project.dependencies] click >= 8.1, < 9`. Comment header notes the
  snippet structure (drop-in for `[project]` section).

**Patterns to follow:** `templates/clap-main.rs` structural shape (header comment + tiered sections + TODO markers);
xurl-rs and bird global-flag conventions translated to Click idioms.

**Test scenarios:**

- Verification: `python3 -c "import ast; ast.parse(open('templates/python-click/main.py').read())"` parses cleanly
  (syntax check; doesn't execute).
- Verification: With `click` installed in a temp venv, `python3 templates/python-click/main.py --help` prints help text
  and exits 0.
- Verification: `python3 templates/python-click/main.py status --output json` emits valid JSON to stdout (parses with
  `json.loads`).
- Verification: `python3 templates/python-click/main.py apply --dry-run --output json` reports the would-be action and
  does not mutate.
- Verification: `pyproject.toml.snippet` is valid TOML when wrapped in a minimal pyproject (`tomllib.loads(...)`
  parses).

**Verification:** A new Python CLI has a starter that encodes P1/P2/P4 by construction (origin R11 acceptance).

---

- U16. **R11.6a: `templates/agents-md-template.python.md`**

**Goal:** Python-flavoured AGENTS.md scaffold paired with U15. Mirrors the existing `templates/agents-md-template.md`
(Rust-prescriptive) for the Python world.

**Requirements:** R11 (item 6a).

**Dependencies:** U15.

**Files:**

- Create: `templates/agents-md-template.python.md`

**Approach:**

- Direct adaptation of `templates/agents-md-template.md` (the Rust version):
- **Build & Run** uses `pip install -e .` / `python -m mytool` instead of `cargo`.
- **Test** uses `pytest` instead of `cargo test`; covers single-test (`pytest -k name`), output (`pytest -s`).
- **Lint & Format** uses `ruff` (`ruff check . && ruff format .`).
- **Architecture** module overview names `mytool/main.py`, `mytool/cli/` (Click commands), `mytool/errors.py` (exception
  classes with exit-code mapping), `mytool/output.py` (output mode + diag logic).
- **Exit Codes** table identical to Rust template (sysexits 0/1/2/77/78).
- **Conventions** translated to Click idioms: "Output goes through `OutputContext` — never naked `print()` or
  `click.echo()` outside the helper"; "Errors raise typed exceptions — never `sys.exit()` except in `main`"; "`--output
  text|json|jsonl`, `--quiet`, `--no-interactive`, `--timeout` are global flags via Click context".
- **Common pitfalls** translated: forgetting `signal.SIGPIPE = SIG_DFL` causes broken-pipe noise; using `print()`
  directly breaks `--quiet` and `--output json`; `sys.exit()` outside main skips Click's cleanup.

**Patterns to follow:** `templates/agents-md-template.md` (Rust) structure exactly; placeholder format identical
(`[Binary name]`, `[add modules]`, etc.).

**Test scenarios:**

- Verification: File contains the same eight H2 sections as the Rust template (Build & Run, Test, Lint & Format,
  Architecture, Quality Bar, Conventions, Common Pitfalls, Known Debt, References).
- Verification: All commands referenced are Python-ecosystem commands, not Rust (`grep -i 'cargo\|rustc'
  templates/agents-md-template.python.md` returns 0 hits).
- Verification: Markdownlint clean.

**Verification:** A Python CLI author copies this template and gets an AGENTS.md that mirrors the Rust version's
structure with idiomatic Python tooling.

---

- U17. **Cross-language idiom sub-sections in `references/framework-idioms-other-languages.md` (scaffold + Python
  rows)**

**Goal:** Add two new sub-sections to the existing four-language idioms file: "JSON envelope authoring (P2)" and
"Testing P5 mutation boundaries". Section scaffolds + Python rows land here. Go rows append in U20. JS + Ruby rows
defer.

**Requirements:** R11 ("framework idioms to add" — JSON envelope sub-section + P5 testing section).

**Dependencies:** U14 (the JSON envelope schema is the canonical reference for shape; the Python row points at it).

**Files:**

- Modify: `references/framework-idioms-other-languages.md`

**Approach:**

- **`## JSON envelope authoring (P2)`** — new section near the bottom of the file, before any closing pointer table.
  Intro paragraph: when implementing P2, your `--output json` mode should emit envelopes that follow the canonical shape
  documented in `references/scorecard-shape.md` (and validated by `anc`'s embedded schema, extractable via `anc generate
  scorecard-schema --output -`). Per-language rows show idiomatic envelope construction:
- **Python (Click + stdlib `json`):** `json.dumps({"data": result, "meta": {"version": __version__}})` → `click.echo` to
  stdout.
- **Go (Cobra + `encoding/json`):** appended in PR 6 (U20). Until then, this row is **absent from the shipped doc** —
  not a "deferred" stub.
- **JS / Ruby:** **not present in this section.** JS / Ruby authors continue to use the existing per-framework sections
  (Click, Commander, yargs, oclif, Thor) already in this file. Cross-language coverage for JS / Ruby is tracked in this
  plan's `### Deferred to Follow-Up Work` and lands in a follow-up PR matched to a JS / Ruby ecosystem expert. Absent
  rows ship cleaner than visible "deferred" markers — readers interpret an absent row as "the existing per-framework
  section covers this" rather than "I'm missing instructions."
- **`## Testing P5 mutation boundaries`** — new section parallel to `references/rust-clap.md`'s implicit P5 testing
  coverage. Same row policy:
- **Python (pytest + `subprocess`/`click.testing.CliRunner`):** show a CliRunner-based dry-run-doesn't-mutate test,
  idempotent-create test, force-flag-overrides-gate test. Reference `templates/cli-tests.rs` as the Rust analog.
- **Go (testing + `os/exec`):** appended in PR 6 (U20). Absent until then.
- **JS / Ruby:** not present (deferred per the rationale above; same row policy).

**Patterns to follow:** Existing `references/framework-idioms-other-languages.md` per-language section structure (Click
section, argparse section, Cobra section…).

**Test scenarios:**

- Verification: File contains both new H2 sections (`## JSON envelope authoring (P2)`, `## Testing P5 mutation
  boundaries`).
- Verification: Python rows present in both sections; Go rows absent (added in PR 6 / U20); JS + Ruby rows absent (no
  visible "deferred" marker in the shipped doc).
- Verification: Envelope section closes with a pointer to `references/scorecard-shape.md` (canonical envelope shape) +
  `anc generate scorecard-schema` (machine-readable schema extraction). Testing section closes with a pointer to
  `templates/cli-tests.rs` (Rust analog).
- Verification: Markdownlint clean.

**Verification:** Section scaffolds in place; Python rows complete and idiomatic; explicit deferral signals where Go /
JS / Ruby content lives or will live.

---

### Phase 6 — PR 6: Go starter (R11.5, R11.6b, Go cross-language rows)

- U18. **R11.5: `templates/go-cobra/`**

**Goal:** Minimal Go/Cobra starter mirroring `clap-main.rs`.

**Requirements:** R11 (item 5).

**Dependencies:** None within PR 6.

**Files:**

- Create: `templates/go-cobra/main.go`
- Create: `templates/go-cobra/go.mod.snippet`

**Approach:**

- **`main.go`** structure (Cobra-idiomatic):
- Header comment block matching `templates/clap-main.rs` voice.
- `cobra.Command` root with one read sub (`status`) and one write sub (`apply`) demonstrating `--dry-run`. (P5.)
- Persistent flags (Cobra's "global" equivalent): `--output text|json|jsonl`, `--quiet`, `--no-interactive`,
  `--timeout`. (P1, P2, P7.)
- Custom exit codes via `os.Exit` only in main; subcommand handlers return errors that `main` maps to exit codes.
  Mapping: 0 success, 1 command error, 2 usage error, 77 auth, 78 config, 74 IO. (P4.)
- JSON-aware error printing: when `--output json` is set, marshal errors as `{"error": true, "kind": ..., "message":
  ..., "code": ...}` to stderr.
- Diagnostic output via a `diag(ctx context.Context, format string, args ...any)` helper that gates on `quiet || output
  != "text"`. (P7.)
- Note: Go does NOT install a custom SIGPIPE handler (the runtime's default is acceptable), so no SIGPIPE fix needed —
  header comment notes this difference vs Rust/Python.
- **`go.mod.snippet`** is a partial go.mod fragment: `module github.com/example/mytool`, `go 1.22`, `require (
  github.com/spf13/cobra v1.8.0 )`. Header comment explains the snippet is appended to `go mod init` output.

**Patterns to follow:** `templates/clap-main.rs` structural shape; Cobra's official examples for persistent flags +
exit-code patterns; `~/dev/solutions-docs/architecture-patterns/anc-cli-output-envelope-pattern-2026-04-29.md` for
envelope shape.

**Test scenarios:**

- Verification: `go vet templates/go-cobra/main.go` passes (syntax + basic semantics).
- Verification: With Cobra in a temp module, `go run templates/go-cobra/main.go --help` exits 0 and prints help text.
- Verification: `go run templates/go-cobra/main.go status --output json` emits valid JSON.
- Verification: `go run templates/go-cobra/main.go apply --dry-run --output json` reports the would-be action and does
  not mutate.
- Verification: `go.mod.snippet` is valid go.mod syntax (parses with `go mod download` after stitching to a minimal
  module).

**Verification:** A new Go CLI has a starter that encodes P1/P2/P4 by construction (origin R11 acceptance, mirrored from
Python).

---

- U19. **R11.6b: `templates/agents-md-template.go.md`**

**Goal:** Go-flavoured AGENTS.md scaffold paired with U18.

**Requirements:** R11 (item 6b).

**Dependencies:** U18.

**Files:**

- Create: `templates/agents-md-template.go.md`

**Approach:**

- Direct adaptation of `templates/agents-md-template.md` (Rust):
- **Build & Run** uses `go build ./...`, `go run ./cmd/mytool`, `go install ./cmd/mytool`.
- **Test** uses `go test ./...`; single-test `go test -run TestName ./...`; output `go test -v ./...`.
- **Lint & Format** uses `gofmt -w .` and `go vet ./...` (and optionally `golangci-lint run`).
- **Architecture** module overview names `cmd/mytool/main.go`, `internal/cli/` (Cobra commands), `internal/errors/`
  (typed errors with exit-code mapping), `internal/output/` (output mode + diag logic).
- **Exit Codes** table identical to Python/Rust templates.
- **Conventions** translated to Go idioms: "Output goes through `OutputContext` — never naked `fmt.Println`"; "Errors
  are typed and bubble up — never `os.Exit` except in `main`"; "`--output`, `--quiet`, `--no-interactive`, `--timeout`
  are persistent flags".
- **Common pitfalls**: missing `--no-interactive` gate before stdin read; using `fmt.Println` directly breaks `--quiet`;
  `os.Exit` outside main skips deferred cleanup; forgetting `--output json` errors must be JSON.

**Patterns to follow:** `templates/agents-md-template.md` (Rust) structure exactly.

**Test scenarios:**

- Verification: Same eight H2 sections as the Rust template.
- Verification: All commands are Go-ecosystem (`grep -i 'cargo\|pip\|rustc' templates/agents-md-template.go.md` returns
  0 hits).
- Verification: Markdownlint clean.

**Verification:** A Go CLI author copies this template and gets an AGENTS.md that mirrors the Rust version's structure
with idiomatic Go tooling.

---

- U20. **Go rows in `references/framework-idioms-other-languages.md`**

**Goal:** Append Go content to the two cross-language sub-sections U17 scaffolded.

**Requirements:** R11 (Go portion of "framework idioms to add").

**Dependencies:** U17 (sections + scaffolds exist), U18 (Go starter is the canonical link target).

**Files:**

- Modify: `references/framework-idioms-other-languages.md`

**Approach:**

- **JSON envelope authoring (P2) → Go row.** Replace U17's stub paragraph with a real Go example: `encoding/json`
  marshalling, write to `os.Stdout`, error envelope variant on `os.Stderr`, link to `references/scorecard-shape.md` for
  the canonical envelope shape and `anc generate scorecard-schema` for machine-readable schema extraction.
- **Testing P5 mutation boundaries → Go row.** Replace U17's stub paragraph with a `go test` + `os/exec` pattern:
  dry-run-doesn't-mutate test, idempotent-create test, force-flag-overrides-gate test. Reference
  `templates/cli-tests.rs` as the Rust analog and `templates/go-cobra/main.go` as the implementation.

**Patterns to follow:** U17's Python row structure (parallel composition).

**Test scenarios:**

- Verification: Both Go rows are now substantive paragraphs (not absent, not stub-marked).
- Verification: Both rows link to `templates/go-cobra/` (implementation) or `references/scorecard-shape.md` + `anc
  generate scorecard-schema` (envelope shape).
- Verification: JS + Ruby rows remain absent from the new sub-sections (per U17's row policy — no visible "deferred"
  markers in the shipped doc; cross-language JS / Ruby coverage continues to be tracked in this plan's `### Deferred to
  Follow-Up Work`).
- Verification: Markdownlint clean.

**Verification:** Cross-language sub-sections cover Python + Go fully; JS + Ruby coverage remains in their existing
per-framework sections (Click / Commander / yargs / oclif / Thor) elsewhere in the file; cross-language deferral tracked
in this plan only, not in the shipped doc.

---

### Phase 7 — PR 7: Deterministic-script hardening (R14)

- U22. **R14: `bin/check-update` agent-native upgrade**

**Goal:** Make `bin/check-update` pass `anc check --binary --audit-profile posix-utility` with `badge.eligible == true`.
Add agent-native flag surface (`--output text|json`, `--quiet`, `--no-interactive`, `--timeout <s>`); distinguish
network-fail from up-to-date in JSON mode; preserve text-mode output and cache-file format byte-for-byte.

**Requirements:** R14.

**Dependencies:** None within PR 7.

**Files:**

- Modify: `bin/check-update`

**Approach:**

- **Flag surface (additive).** `--output text|json` (default `text` — current single-line token grammar preserved);
  `--quiet` (suppress all output; cache-file write side-effect still runs); `--no-interactive` (no-op — script is
  already non-interactive; flag added for P1 conformance and explicit semantics); `--timeout <s>` (overrides the
  hard-coded `--max-time 5` curl timeout; min 1, max 60).
- **JSON envelope shape.** Single-line JSON to stdout, one of: `{"status": "up_to_date", "version": "<ver>"}`,
  `{"status": "upgrade_available", "local": "<old>", "remote": "<new>"}`, `{"status": "snoozed", "remote": "<ver>",
  "expires_at": <epoch>}`, `{"status": "disabled"}`, `{"status": "network_unavailable", "reason": "<curl rc>"}`,
  `{"status": "cache_only", "cached": "<token>"}`. Stderr stays empty in success paths; non-zero curl rc no longer
  collapses to silent-exit-0 in JSON mode — agents get a typed signal.
- **Default behavior unchanged.** Without flags, output is byte-faithful to today: nothing on up-to-date, nothing on
  snooze/disabled/network-fail, single line `UPGRADE_AVAILABLE <old> <new>` on stale. Cache file format unchanged.
- **Exit code policy.** Always 0 (degrades silently per the existing contract — periodic update check must not break
  user shells if curl fails). Failure semantics surface only in JSON mode via the `status` field. Documented in the
  script header as "exit code is intentionally non-meaningful for this script — gate on `status` in JSON mode" and
  cross-linked to `## Anc contract`'s "switch on typed fields, never `$?`" guidance from U4.

**Patterns to follow:** Existing `bin/check-update` voice; `templates/output-format.rs` `OutputFormat` enum shape for
the JSON envelope (Text / Json / Jsonl with format-aware printing);
`~/dev/solutions-docs/best-practices/cli-structure-for-machines-typed-json-fields-over-display-strings-2026-04-20.md`.

**Test scenarios:**

- Verification: `bin/check-update --help` exits 0, prints flag list including `--output`, `--quiet`, `--no-interactive`,
  `--timeout`.
- Verification: `bin/check-update` (no flags) byte-matches today's output across the six branches (up-to-date, stale,
  snoozed, disabled, network-fail, cache-hit) — capture today's output to fixtures pre-edit, diff against post-edit
  output.
- Verification: `bin/check-update --output json` emits parseable JSON for each of the six status cases (`status` field
  enumerates `up_to_date | upgrade_available | snoozed | disabled | network_unavailable | cache_only`).
- Verification: `bin/check-update --quiet` produces zero output regardless of branch; cache file is still written.
- Verification: `bin/check-update --timeout 0` rejected with non-zero exit + clear error (text mode) or `{"status":
  "error", "kind": "invalid_timeout", ...}` (JSON mode); `--timeout 60` accepted.
- Verification: Cache file at `~/.cache/agent-native-cli/last-update-check` retains legacy format (`UP_TO_DATE <ver>` /
  `UPGRADE_AVAILABLE <old> <new>`) — verified by parsing the file after a JSON-mode invocation.
- Verification: `shellcheck bin/check-update` clean.

**Verification:** Output contract is documented (U24 covers docs); JSON mode produces typed envelopes; default text mode
is byte-faithful to today; cache file is back-compat.

---

- U23. **R14: `scripts/sync-spec.sh` agent-native upgrade**

**Goal:** Make `scripts/sync-spec.sh` pass `anc check --binary --audit-profile posix-utility`. Add full P1 / P2 / P5 /
P7 flag surface; move success-path status prose from stdout to stderr; emit JSON envelope for the success path; report
idempotency when no work is needed; gate destructive overwrites of dirty `spec/`.

**Requirements:** R14.

**Dependencies:** None within PR 7.

**Files:**

- Modify: `scripts/sync-spec.sh`

**Approach:**

- **Flag surface.** `--output text|json` (default `text`); `--quiet` (suppress stderr status; final result still emitted
  in selected output mode); `--no-interactive` (script is already non-interactive; flag added for conformance);
  `--timeout <s>` (wraps `git ls-remote` and `git clone` invocations via `timeout <s> ...` or `git -c
  http.lowSpeedTime=...`); `--dry-run` (resolve the upstream tag, report what would be vendored, do not touch `spec/`);
  `--force` (override the new dirty-spec gate).
- **Stderr discipline.** Move success-path echoes ("querying $SPEC_REMOTE_URL…", "vendoring $spec_tag…", "wrote $copied
  principle files") from stdout to stderr. Errors already go to stderr; this just unifies the success path. Stdout in
  text mode now contains only the final result line (e.g., `synced v0.3.0 abc1234 7-files` or `already_in_sync v0.3.0`).
- **JSON envelope.** Success: `{"status": "synced", "tag": "<tag>", "sha": "<short>", "source": "remote|local",
  "files_written": <n>, "files": ["VERSION", "CHANGELOG.md", "principles/p1-…", …]}`. No-op: `{"status":
  "already_in_sync", "tag": "<tag>", "sha": "<short>"}`. Dry-run: `{"status": "would_sync", "tag": "<tag>", "sha":
  "<short>", "files": [...]}`. Error envelopes: `{"status": "error", "kind": "remote_unreachable | no_tags | dirty_spec
  | invalid_timeout", "message": "<msg>", ...}`.
- **Idempotency report.** Before extracting, compare resolved `$spec_tag` to current `$DEST_DIR/VERSION`. If equal AND
  `git -C "$REPO_ROOT" diff --quiet spec/` (no local edits), emit the `already_in_sync` envelope and exit 0 without
  writing.
- **Dirty-spec gate.** If `git -C "$REPO_ROOT" status --porcelain spec/` reports non-empty, refuse to overwrite without
  `--force`. Error envelope: `{"status": "error", "kind": "dirty_spec", "files": [...]}`. P5 (every write op gates
  destructive overwrites) verbatim.
- **`--dry-run`.** Resolve tag + enumerate files via `git ls-tree --name-only $spec_tag principles/`; emit `would_sync`
  envelope; do not call `git show`, do not write to `$DEST_DIR`.
- **Exit code policy.** 0 on success / no-op / dry-run; 2 on dirty-spec without `--force` (usage error); 74 on remote
  unreachable + no local fallback (sysexits IOERR); 78 on missing local tags (sysexits CONFIG); 1 on any other failure.
  Documented in the script header.

**Patterns to follow:** `templates/error-types.rs` for the `kind` enum naming; existing `sync-spec.sh` cleanup-trap +
remote-first-then-local resolution pattern;
`~/dev/solutions-docs/best-practices/consistent-json-schema-across-success-and-error-paths-2026-04-20.md` for envelope
shape parity across success / error paths.

**Test scenarios:**

- Verification: `scripts/sync-spec.sh --help` exits 0, prints all six new flags.
- Verification: `scripts/sync-spec.sh` (no flags) with clean `spec/` and remote reachable produces text-mode output
  matching the new contract (single human-readable result line on stdout; status prose on stderr).
- Verification: `scripts/sync-spec.sh --output json` produces parseable JSON; `status` field is one of `synced |
  already_in_sync | would_sync | error`.
- Verification: `scripts/sync-spec.sh --dry-run --output json` resolves the tag without writing; `git status spec/`
  unchanged after invocation.
- Verification: With dirty `spec/` (touch a principle file), `scripts/sync-spec.sh` exits 2 and emits `{"status":
  "error", "kind": "dirty_spec", …}`; `--force` overrides and proceeds.
- Verification: With `SPEC_REMOTE_URL=https://invalid.example.com` and no `SPEC_ROOT`, exits 74 with `{"status":
  "error", "kind": "remote_unreachable", …}`.
- Verification: Re-running against an already-vendored tag emits `already_in_sync` and writes no files (`stat -c %Y` on
  `spec/VERSION` unchanged across two consecutive runs).
- Verification: `shellcheck scripts/sync-spec.sh` clean.

**Verification:** Script passes the dogfood audit (U25); idempotency reports correctly; dirty-spec is gated; JSON
envelope shape matches the documented contract.

---

- U24. **R14: Output + env-var contract documentation**

**Goal:** Document `bin/check-update`'s and `scripts/sync-spec.sh`'s output contract (text grammar + JSON envelope per
status) and env-var overrides in the references; cross-link from SKILL.md's update-check footnote and U8's spec-skew
fallback paragraph.

**Requirements:** R14.

**Dependencies:** U22, U23 (the contract is what U22 / U23 actually ship; docs follow the implementation).

**Files:**

- Modify: `references/update-check.md` (expand to cover text grammar + JSON envelope + env vars for `bin/check-update`)
- Modify: `references/runbook.md` (new entry 7: "When and how to run `scripts/sync-spec.sh`")

**Approach:**

- **`references/update-check.md` expansion.** Add three sub-sections under existing content:

1. **Output contract — text mode.** The single-line token grammar (`UPGRADE_AVAILABLE <old> <new>` on stale; nothing
   otherwise). Documented as a stable interface; consumers may parse via `awk '{print $1, $2, $3}'`.
2. **Output contract — JSON mode.** Full envelope shape with one example per `status` value (six total).
3. **Env-var overrides.** Three-row table: `AGENTNATIVE_SKILL_DIR`, `AGENTNATIVE_SKILL_REMOTE_URL`,
   `AGENTNATIVE_SKILL_STATE_DIR` — purpose + default + when to override (testing, mirrored install).

- **`references/runbook.md` entry 7.** ~10-line entry: when to run `sync-spec.sh` (after every `agentnative-spec` v* tag
  bump; SKILL.md U8 spec-skew fallback is the in-loop trigger); env-var overrides (`SPEC_REMOTE_URL`, `SPEC_ROOT`);
  `--dry-run` for previewing; `--force` for dirty-spec override; the idempotency-report behavior; cross-link to
  `bin/check-update` (sibling) and `references/update-check.md`.
- **SKILL.md cross-links.** Update the `## Update-check` footnote (created in U1, refined in U3) and U8's spec-skew
  fallback paragraph to mention "`--output json` is available — see `references/update-check.md`" and "see
  `references/runbook.md` entry 7" respectively.

**Patterns to follow:** `references/update-check.md` existing voice; `references/runbook.md` short-section voice from
U9.

**Test scenarios:**

- Verification: `references/update-check.md` enumerates all six JSON `status` values matching U22's implementation.
- Verification: `references/update-check.md` env-var table covers all three `AGENTNATIVE_SKILL_*` vars.
- Verification: `references/runbook.md` entry 7 names `--dry-run`, `--force`, `SPEC_REMOTE_URL`, `SPEC_ROOT`.
- Verification: SKILL.md update-check footnote references `references/update-check.md`'s JSON envelope; U8 spec-skew
  paragraph references `references/runbook.md` entry 7.
- Verification: Markdownlint clean; cross-links resolve.

**Verification:** An agent reading `references/update-check.md` and `references/runbook.md` cold can parse both scripts'
output and pick the right invocation flags without reading the script source.

---

- U25. **R14: Dogfood gate via `anc check --binary`**

**Goal:** Empirically verify both scripts pass `anc check --binary --audit-profile posix-utility` with `badge.eligible
== true`. Document the audit invocation so contributors can re-run the gate after future edits.

**Requirements:** R14 (acceptance gate).

**Dependencies:** U22, U23, U24 (everything else in PR 7).

**Files:**

- Modify: `references/runbook.md` (new entry 8: "How do I re-run the dogfood audit?")
- Modify: `CONTRIBUTING.md` (one-paragraph note pointing at the runbook entry)

**Approach:**

- **Empirical gate at unit time.** Run `anc check --binary bin/check-update --audit-profile posix-utility --output json`
  and `anc check --binary scripts/sync-spec.sh --audit-profile posix-utility --output json`. Capture both envelopes.
  Assert `badge.eligible == true` for both. If either fails, the failure modes from `results[]` are the punch list — fix
  in U22 / U23 and re-run before PR 7 merges.
- **`references/runbook.md` entry 8.** Document the canonical audit invocation (the exact two commands above), the
  expected `badge.eligible == true` outcome, and the punch-list workflow when one fails. Note that CI integration is
  deferred to a follow-up PR.
- **`CONTRIBUTING.md` update.** Add one paragraph in the existing "Before merging" or equivalent section pointing at the
  runbook entry, so a contributor editing either script can't merge without re-running the gate.
- **Out of scope for this unit (deferred to follow-up CI-hardening PR):** wiring the dogfood audit into CI as a
  regression gate. PR 7 ships the manual gate + documentation; CI integration is the next compounding step.

**Patterns to follow:** `references/runbook.md` short-section voice; `CONTRIBUTING.md` existing tone.

**Test scenarios:**

- Verification: `anc check --binary bin/check-update --audit-profile posix-utility --output json | jq .badge.eligible`
  returns `true`.
- Verification: `anc check --binary scripts/sync-spec.sh --audit-profile posix-utility --output json | jq
  .badge.eligible` returns `true`.
- Verification: `references/runbook.md` entry 8 contains both audit commands verbatim.
- Verification: `CONTRIBUTING.md` references the runbook entry.

**Verification:** The dogfood claim is empirically true: the skill audits CLIs against the agent-native spec; under PR 7
the skill's own runtime scripts pass that same audit at the badge-eligible bar.

---

## System-Wide Impact

- **Interaction graph.** `SKILL.md` is the entry-point host hosts read; `getting-started.md` is its first link;
  `references/*.md` are loaded on triggered read. Reordering in U1 must keep this load order intact — agents reading
  SKILL.md top-to-bottom must reach Quick Start before any deeper file is referenced.
- **Error propagation.** PRs 1–6 are docs + templates; the only "errors" are markdownlint failures, broken cross-links,
  and JSON Schema parse failures; each unit's verification catches them locally. **PR 7 (R14) is the exception:** U22 /
  U23 modify two runtime-callable bash scripts; new failure modes are surfaced as typed JSON statuses in the new
  `--output json` mode (`network_unavailable`, `dirty_spec`, `remote_unreachable`, `invalid_timeout`) and gated by
  `--dry-run` / `--force` for the destructive `sync-spec.sh` overwrite path. Default text-mode behavior is byte-faithful
  to today; back-compat for existing consumers and the cache file at `~/.cache/agent-native-cli/last-update-check`.
- **State lifecycle risks.** PRs 1–6 only touch git history of docs / templates. PR 7 adds two new pieces of agent-
  observable state: (1) the cache file format at `~/.cache/agent-native-cli/last-update-check` is preserved as legacy
  (no migration needed); (2) `spec/` overwrite is now gated by a dirty-check (`--force` required to override). Plans
  live on `dev`; SKILL.md / getting-started.md / references / templates / scripts land on `dev` via PR and propagate to
  `main` via `release/*` cherry-pick (per `RELEASES.md`).
- **API surface parity.** The skill's "API" is its frontmatter (`name`, `description`, `allowed-tools`) read by hosts
  during discovery. U2 + U10 are the surface-touching units; U2 adds `allowed-tools`, U10 audits `description`. Both are
  additive — no rename, no removal of existing fields.
- **Integration coverage.** Live `anc 0.3.0` integration is exercised by U5 (samples), U14 (schema validates real
  envelope), U6 (audit-profile values match `anc check --help`). If `anc` ships a schema bump (sibling brief A1) before
  this plan lands, U4's pin path may need to update from top-level `schema_version` to `anc.schema_version` — plan
  revision required at that point.
- **Unchanged invariants.** `name: agent-native-cli` (R10's documented "no" — discoverability). The seven principle
  files in `spec/principles/` (vendored, not edited here). The four-step `## The anc loop` shape (U1 reorders SKILL.md
  but the four steps stay; U7 + U8 fold rules into existing steps). `bin/check-update`'s default text-mode output and
  cache-file format (R5 demotes its SKILL.md position; R14 adds new flags but preserves default behavior byte-for-byte).
- **Cross-repo.** Sibling brief `2026-05-01-002` carries A1 / A2 / A3 / A4 / A5 / A6 / A7 against `agentnative-cli`.
  This plan's R2 / R6 / R7 reference those items as soft-dependencies but ship interim guidance independently. PR 1's
  commit message naming `[A1, A2, A3, A4]` cross-references is recommended for traceability.

---

## Risks & Dependencies

| Risk                                                                                                              | Likelihood | Impact | Mitigation                                                                                                                                                                                                                                                                                                                               |
| ----------------------------------------------------------------------------------------------------------------- | ---------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `anc` ships schema 0.6 (or renames `id` to `requirement_id`) mid-plan, invalidating U4 / U5 pinned values.        | Low        | Med    | U4 footnote names the interim contract explicitly; if a bump lands, U4 + U5 need a follow-up PR. Sibling brief A1 is additive, not breaking, so the most likely shape is a new `anc.schema_version` field alongside the top-level one — both pin paths stay valid.                                                                       |
| `anc.dev/badge` convention page does not exist or doesn't enumerate placement, leaving U9 entry 1 underspecified. | Med        | Low    | U9 entry 1's open-question note: if convention page lacks placement, U9 proposes a default (`top-of-readme` after H1) and the proposal mirrors to sibling brief A4 as a feature ask.                                                                                                                                                     |
| R12 merge loses a file-unique nugget that nobody notices until post-merge.                                        | Low        | Med    | U11 verification specifically checks for the four enumerated nuggets (Flags-vs-subcommands taxonomy, `kind()` method, main-only `process::exit()`, Jsonl variant) **plus a token-set diff pre-deletion gate** that surfaces every lost token for explicit reviewed-loss disposition.                                                     |
| Upstream `anc generate scorecard-schema` verb (the path U14 points at) hasn't shipped when PR 4 lands.            | Med        | Low    | U14 prose carries a one-line caveat naming the upstream plan and the upgrade path (`brew upgrade brettdavies/tap/agentnative` or pin to `https://anc.dev/scorecard-v0.5.schema.json` archive). Until the verb ships, parser authors use U5's prose form. No skill-side rework needed when the verb lands — the path is verb-name-stable. |
| SKILL.md exceeds 200 lines after PR 1 lands (R9 ceiling violated).                                                | Low        | Low    | U1 verification checks line count at end of PR 1. Origin estimate is +45 lines net; budget is +54 lines, so margin exists. If exceeded, deferred guidance moves to `references/runbook.md` (U9) or extends `references/scorecard-shape.md` (U5).                                                                                         |
| Trigger-keyword audit (U10 / OQ-origin-#5) finds the existing keyword list is fine and U10 has no work.           | Low        | Low    | OK — U10 commits only the kept-as-is rationale documentation in that case. Frontmatter remains unchanged. The unit still ships (one-paragraph commit).                                                                                                                                                                                   |
| PR 5 / PR 6 reviewers (Python / Go specialists) push back on starter idioms.                                      | Med        | Low    | Each PR is intentionally scoped to one ecosystem so review is fast and targeted. Iterate within PR; do not block the rest of the plan.                                                                                                                                                                                                   |
| Live `anc check` envelope used by U5 examples drifts before PR 1 lands.                                           | Low        | Low    | U5 verification re-runs `anc check --output json` at unit time and checks samples against current output. If drift detected, regenerate the samples — they're cheap.                                                                                                                                                                     |
| `bin/check-update` cache file format compat breaks under PR 7 (cache consumed across an upgrade boundary).        | Low        | Low    | U22 keeps the cache file format unchanged (legacy `UP_TO_DATE <ver>` / `UPGRADE_AVAILABLE <old> <new>`); JSON appears at output time only. Verified by post-edit cache-file inspection in U22's test scenarios.                                                                                                                          |
| `scripts/sync-spec.sh` stderr-discipline change breaks an unknown consumer that captured the success-path stdout. | Low        | Low    | Searched for callers; only invocation today is direct human run + this plan's U8 spec-skew fallback (which doesn't capture stdout). PR 7 changelog calls out the breaking change explicitly so any external consumer sees the migration note.                                                                                            |
| `anc check --binary` against bash scripts surfaces unexpected gaps (e.g., missing P3 `after_help`, P6 SIGPIPE).   | Med        | Low    | U25 is the empirical gate; if either script fails, U22 / U23 absorb the punch list before merge. Acceptable to iterate within PR 7. If a finding requires an `anc`-side feature (e.g., bash-script-aware audit profile), defer with a sibling-brief item and document the suppression in U25's verification note.                        |

---

## Phased Delivery

Seven PRs, sequenced. Each phase = one PR. Origin's handoff section is the canonical sequencing source for PRs 1–6; PR 7
is plan-introduced (R14, the dogfood gate). All seven PRs ship in one consolidated `v0.4.0` release.

### Phase 1 — PR 1: Skill-side determinism (R1–R9, R13)

Lands U1–U9 + U21 (R9 first; U21 last so it can absorb U1's section skeleton and expand U9's runbook entry). One commit
per unit for review legibility. Targets `dev`. Estimated total ~280 lines added/changed across `SKILL.md`,
`getting-started.md`, and three new reference files (`runbook.md`, `scorecard-shape.md`, `audit-profile-selection.md`).
Largest PR; contains the load-bearing reorder.

Acceptance gate: SKILL.md ≤ 200 lines, first runnable command is `anc check`, all five `results[].status` values
enumerated in `## Anc contract`, exhaustive scorecard sample parses as JSON, exit-code table empirically matches live
`anc 0.3.0` behavior across at least three commands (one with `summary.fail == 0`, one with `summary.fail > 0`, one
invocation error), R6 spec-skew paragraph distinguishes namespace-mismatch from actual-spec-drift, **subcommand index
matches live `anc --help` `Commands:` block** (U21), **target-resolution runbook entry names all four modes (`.`,
`--binary`, `--source`, `--command <name>`)** (U21). U14 (formerly the hand-written JSON Schema; now docs-only — pivots
to documenting the upstream `anc generate scorecard-schema` extraction path) lands in PR 4; PR 1's gate has no
schema-related criterion.

### Phase 2 — PR 2: Frontmatter polish (R10)

Lands U10. Tiny PR; can be folded into PR 1 if R10 stays under ~10 lines after the trigger-keyword audit.

Acceptance gate: `description` ≤ 1024 chars; SKIP clause names `compound-engineering` and `create-agent-skills`
redirects.

### Phase 3 — PR 3: Rust idioms consolidation (R12)

Lands U11. Self-contained; deletes two files, creates one, updates SKILL.md and `getting-started.md` link targets. Lands
before PR 4 so the new Rust starter docs reference `references/rust-clap.md`.

Acceptance gate: `framework-idioms.md` and `rust-clap-patterns.md` deleted; `rust-clap.md` exists, ~250 lines, all four
file-unique nuggets present; no broken links anywhere in the repo.

### Phase 4 — PR 4: Rust starter completion + scorecard-schema extraction docs (R11.1, R11.2, R11.3-repurposed)

Lands U12 + U13 + U14. U12 + U13 are Rust-starter additions (cargo-toml.md, cli-tests.rs); U14 is docs-only (modifies
`references/scorecard-shape.md` + `references/runbook.md` to document the upstream `anc generate scorecard-schema`
extraction path). Cross-references `references/rust-clap.md` (PR 3).

Acceptance gate: Cargo TOML resolves dependencies; `cli-tests.rs` compiles cleanly when copied into a fresh `cargo
init`; `references/scorecard-shape.md` contains the `anc generate scorecard-schema` sub-section with cross-link to
upstream plan; `references/runbook.md` contains the schema-validation entry; **no file is created at
`templates/scorecard-envelope.schema.json`** (the vendored artifact is explicitly NOT shipped — upstream binary is
canonical).

### Phase 5 — PR 5: Python starter (R11.4, R11.6a, cross-language scaffolds)

Lands U15 + U16 + U17. Cross-language idiom sub-section scaffolds + Python rows ride here.

Acceptance gate: Python starter parses + runs `--help`; pyproject snippet is valid TOML;
framework-idioms-other-languages section scaffolds present; Python rows substantive; Go / JS / Ruby rows are explicitly
deferred markers.

### Phase 6 — PR 6: Go starter (R11.5, R11.6b, Go cross-language rows)

Lands U18 + U19 + U20.

Acceptance gate: Go starter `go vet` clean, runs `--help`; AGENTS.md mirrors Rust template structure; Go rows in
cross-language sub-sections substantive (no longer stubs).

### Phase 7 — PR 7: Deterministic-script hardening (R14)

Lands U22 + U23 + U24 + U25. The dogfood gate: makes `bin/check-update` and `scripts/sync-spec.sh` pass `anc check
--binary --audit-profile posix-utility` with `badge.eligible == true`. Additive flag surfaces (no removals); cache-file
format unchanged; one minor breaking change in `sync-spec.sh` (success-path status prose moves from stdout to stderr,
called out in PR 7's changelog).

Acceptance gate: `bin/check-update --help` and `scripts/sync-spec.sh --help` print the new flag surfaces; both scripts
pass `anc check --binary --audit-profile posix-utility` with `badge.eligible == true` (the empirical gate, U25);
`references/update-check.md` documents both modes' output contract and env-var overrides; `references/runbook.md`
carries entries 7 (sync-spec runbook) and 8 (re-run-the-dogfood-audit); `CONTRIBUTING.md` references the audit gate;
`shellcheck` clean on both scripts.

---

## Documentation / Operational Notes

- **CHANGELOG.** Each PR's `## Changelog` section in the body is the source of truth (per repo convention;
  `scripts/generate-changelog.sh` extracts it). PR 1's changelog is user-facing-large: "SKILL.md restructure with anc
  contract, scorecard samples, audit-profile selection, loop termination rule, install precondition, spec-skew fallback,
  and runbook." PR 2–6 changelogs scoped per-PR. PR 7's changelog calls out two user-facing additions and one minor
  breaking change: (1) `bin/check-update` and `scripts/sync-spec.sh` gain `--output json|text`, `--quiet`,
  `--no-interactive`, `--timeout` flags; `sync-spec.sh` additionally gains `--dry-run` and `--force`; (2) both scripts
  pass the dogfood audit (`anc check --binary --audit-profile posix-utility`) at the badge-eligible bar; (3) **breaking
  change:** `sync-spec.sh` success-path status prose ("querying…", "vendoring…", "wrote N files") moves from stdout to
  stderr — consumers capturing the success-path stdout will see only the new single-line result token instead.
- **VERSION bump.** All seven PRs ship in one consolidated release: `v0.4.0` from `v0.3.0`. The release covers the R9
  reorder + R2 anc contract + R10 frontmatter + R12 Rust idioms + R11 starter templates + R13 subcommand index + R14
  deterministic-script hardening. Minor bump (additive surface, no removals beyond R12's two deleted reference files
  which had explicit redirects, and PR 7's stdout→stderr re-routing in `sync-spec.sh`'s success path which is called out
  as breaking in the changelog). Cut the tag after PR 7 lands and the dogfood gate (U25) is green. Per-PR commit
  messages remain as the audit trail; the consolidated `RELEASES.md` entry summarizes against the seven PRs.
- **`anc skill install` consumers.** When PR 1 ships, hosts that have already installed the skill via `anc skill
  install` will see the restructured SKILL.md after re-running install or `git pull`. R5's install-precondition is the
  new first action — agents that cached the old "First action: update check" wording will encounter the precondition on
  next session. This is intentional and correct (the precondition is more important than the bundle update-check).
- **Cross-repo.** Sibling brief PRs land independently in `agentnative-cli`. This plan does NOT block on any of them.
- **`spec/` resync.** Not required for this plan — `spec/VERSION = 0.3.0` matches `anc 0.3.0`'s `spec_version: "0.3.0"`.
  If the spec moves, run `scripts/sync-spec.sh` as a separate commit before PR 1 lands.
- **Markdownlint configuration.** `.markdownlint-cli2.yaml` enforces 120-char line length. Per global instructions, do
  not manually wrap markdown lines — the auto-format hook handles it.

---

## Sources & References

- **Origin document:**
  [`docs/brainstorms/2026-05-01-001-skill-determinism-requirements.md`](../brainstorms/2026-05-01-001-skill-determinism-requirements.md)
- **Sibling brief (cross-repo, anc-side):**
  [`docs/brainstorms/2026-05-01-002-anc-determinism-feature-asks-requirements.md`](../brainstorms/2026-05-01-002-anc-determinism-feature-asks-requirements.md)
- **Upstream plan (anc-side schema, the canonical artifact U14 points at):**
  `agentnative-cli/docs/plans/2026-04-30-002-feat-scorecard-json-schema-plan.md` — derives the scorecard JSON Schema
  from Rust types via `schemars`, embeds it in the binary, exposes it via `anc generate scorecard-schema`, archives
  versioned URLs under `https://anc.dev/scorecard-v{X.Y}.schema.json` via the `agentnative-site` repo. This skill's U14
  pivot from "ship a vendored schema" to "document the extraction path" is grounded in this plan being the
  single-source-of-truth.
- **Repo files referenced:** `SKILL.md`, `getting-started.md`, `AGENTS.md`, `references/framework-idioms.md`,
  `references/framework-idioms-other-languages.md`, `references/project-structure.md`,
  `references/rust-clap-patterns.md`, `references/update-check.md`, `templates/clap-main.rs`,
  `templates/error-types.rs`, `templates/output-format.rs`, `templates/agents-md-template.md`, `bin/check-update`,
  `scripts/sync-spec.sh`, `spec/principles/p[1-7]-*.md`, `spec/VERSION`.
- **Live `anc` integration:** `anc 0.3.0` (verified 2026-05-01); envelope at top-level keys `anc, audience,
  audit_profile, badge, coverage_summary, results, run, schema_version, spec_version, summary, target, tool`; result
  keys `confidence, evidence, group, id, label, layer, status`; `schema_version: "0.5"`, `spec_version: "0.3.0"`.
- **Solutions:**
- `~/dev/solutions-docs/best-practices/skills-2-0-structure-progressive-disclosure-20260402.md`
- `~/dev/solutions-docs/architecture-patterns/anc-cli-output-envelope-pattern-2026-04-29.md`
- `~/dev/solutions-docs/best-practices/cli-structure-for-machines-typed-json-fields-over-display-strings-2026-04-20.md`
- `~/dev/solutions-docs/best-practices/consistent-json-schema-across-success-and-error-paths-2026-04-20.md`
- `~/dev/solutions-docs/best-practices/agentnative-version-model-2026-05-01.md`
- **External:**
- [`anc.dev/badge`](https://anc.dev/badge) — badge convention reference for U9 entry 1
- [`agentnative-cli`](https://github.com/brettdavies/agentnative-cli) — sibling repo for cross-repo brief
- [`agentnative`](https://github.com/brettdavies/agentnative) — spec repo (not edited here)
- **Prior plans (this repo, dev):**
- `docs/plans/2026-04-27-001-bootstrap-agentnative-skill-plan.md` (bootstrap)
- `docs/plans/2026-04-28-001-feat-update-check-mechanism-plan.md` (update-check, U3 demotes its SKILL.md placement)
