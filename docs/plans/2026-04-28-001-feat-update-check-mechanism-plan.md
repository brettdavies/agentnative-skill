---
title: "feat: gstack-style update-check mechanism + drop install.json SHA pin"
type: feat
status: complete
completed_date: 2026-05-03
skill_scope_status: complete
skill_scope_completed_date: 2026-04-29
site_scope_status: complete
site_scope_completed_date: 2026-05-03
date: 2026-04-28
parent: ~/.gstack/projects/brettdavies-agentnative/brett-dev-design-show-hn-launch-inversion-20260427-144756.md
---

# feat: gstack-style update-check mechanism + drop install.json SHA pin

> **Parent:** `~/.gstack/projects/brettdavies-agentnative/brett-dev-design-show-hn-launch-inversion-20260427-144756.md`
> — central Show HN launch tracker. This plan sequences as part of step 3a of the launch wave (skill v0.2.0 cherry-pick
> scope) and step 4 (site `release/launch` cherry-pick scope).
>
> **Multi-repo:** plan lives in `agentnative-skill` (where the load-bearing change ships) but covers coordinated work in
> `agentnative-skill` AND `agentnative-site`. Each unit carries a `Target repo:` annotation. All file paths are
> repo-relative to the unit's target repo.

## Overview

Replace the consumer-facing SHA-pin advisory in `agentnative-site/src/data/install.json` with a native git-based
update-check mechanism that lives in the skill bundle itself. Mirrors the [garrytan/gstack][gstack] pattern: a small
bash script in the skill bundle compares the consumer's local `VERSION` against the repo's raw GitHub `VERSION` on
demand, emits `UPGRADE_AVAILABLE` when they diverge, and the agent surfaces the result via `AskUserQuestion`. Drop the
`source.commit`, `verify`, and `version` fields from `install.json` along with the supporting validators, prose, and
tests in the site repo.

This is the audit-driven follow-up to the question "if `install.json` advertises a SHA pin but the install command
clones HEAD-of-`main`, what work is the SHA actually doing?" Answer: it was an advisory probe whose semantics nobody was
actually consuming. Replacing it with the gstack pattern keeps update-detection working (in fact, more reliably, since
the check uses git's native upstream-tracking instead of an HTTP round-trip through a third-party site) while shrinking
`install.json`'s schema surface and removing the misleading "pinned at commit X" prose.

[gstack]: https://github.com/garrytan/gstack

---

## Problem Frame

`install.json` currently advertises a `source.commit: <40-char-SHA>` field and a `verify` block whose stated semantics
are *"advisory freshness probe; mismatch means upstream has moved past the site's pin."* The accompanying prose at
`src/build/install.mjs:196` says *"Clones … (pinned at commit X)."*

In reality:

- The install command does **not** pin: it's `git clone --depth 1 https://github.com/brettdavies/agentnative-skill.git
  <dest>`, which lands on HEAD of `main` at clone time.
- `source.commit` is hand-bumped during a coordinated site `release/launch` cherry-pick (per
  `agentnative-site/RELEASES.md` line 211) to match the skill's latest release-commit SHA.
- The daily `skill-availability.yml` probe checks repo *reachability* (`git ls-remote --exit-code … HEAD`), not whether
  the advertised SHA is current.
- No first-class consumer of `verify.expected` exists. The e2e test at `agentnative-site/tests/e2e/install.e2e.ts`
  asserts `local HEAD == manifest.source.commit` after install, which is trivially true when both come from `git clone
  main` at the same moment, but says nothing about staleness afterward.

The intended consumer-side question — *"is this skill out of date and should I `git pull`?"* — has no implemented
mechanism today. The SHA pin was a placeholder for it.

The gstack pattern solves this directly: the skill bundle ships a small script that compares local `VERSION` against raw
GitHub `VERSION` and emits a status string. The agent runs it on first invocation per session and prompts the user via
`AskUserQuestion` when an upgrade is available. No SHA round-trip, no third-party site dependency, no schema field that
gets out of sync between releases.

---

## Requirements Trace

- R1. **Drop SHA-pin advisory from `install.json`.** Remove `source.commit`, `verify`, and `version` fields and their
  validators / prose / tests in the site repo. (Audit Q4 of 2026-04-28 cross-repo audit.)
- R2. **Ship a working consumer-side update-check** as part of skill `v0.2.0` so the launch-day install path doesn't
  silently lose the staleness-detection capability the SHA pin was a placeholder for.
- R3. **Keep the launch-eve cherry-pick scope tight.** No new abstractions, no telemetry, no auto-upgrade config — port
  only the load-bearing pieces of the gstack pattern. Anything more polished defers post-launch.
- R4. **Retroactively scrub** the SHA-pin language from this session's already-landed plan-doc edits (central-tracker
  SoT section, site plan SoT pointer, gstack site cross-repo pointer, skill plan task #15 cherry-pick notes) so the
  artifacts are coherent before launch.

---

## Scope Boundaries

- **Not in scope (this plan):**
- Auto-upgrade configuration (gstack's `auto_upgrade: true` setting via `gstack-config`). Defer to a future plan if the
  manual prompt becomes annoying.
- Telemetry / Supabase ping on update check. Defer; not load-bearing for staleness detection.
- Multi-host install-type detection (gstack's `global-git` / `local-git` / `vendored` branching). The skill is always a
  `git clone` install in `~/<host>/skills/agent-native-cli/`. Single-path code.
- Migration scripts (gstack's `gstack-upgrade/migrations/` pattern). Skill v0.2.0 has no state to migrate.
- Update-mechanism beyond `git pull --ff-only`. No `git stash + reset --hard origin/main` for users with local
  modifications. If the consumer has uncommitted changes in a skill bundle, they're holding it wrong; the script
  surfaces the failure and exits.
- Pinning the `git clone` install command to a specific tag (`--branch v0.2.0`). The roll-forward model stays.
- **Not in scope (other plans):**
- Bumping the skill's own `VERSION` from `0.1.0` to `0.2.0`. Owned by the skill bootstrap plan's task #15 cherry-pick
  scope (`docs/plans/2026-04-27-001-bootstrap-agentnative-skill-plan.md`).
- Re-vendoring `bundle/spec/` against `agentnative-spec` `v0.3.0`. Same — task #15 scope.
- The `agentnative-site/scripts/sync-coverage-matrix.sh` rename drift. Already shipped 2026-04-28 (`2467e5c`) per the
  site launch plan.

### Deferred to Follow-Up Work

- **Bats unit tests for `bundle/bin/check-update`.** Manual smoke testing per U1's verification suffices for v0.2.0; add
  formal tests post-launch if drift surfaces.
- **Snooze duration tuning** based on actual user feedback. v0.2.0 ships gstack's defaults (24h / 48h / 7d escalation);
  revisit if too noisy or too quiet.
- **The "Coordinated cross-repo releases" paragraph** previously queued for `agentnative-skill/RELEASES.md` (in skill
  task #15) becomes simpler when the SHA-pin reference goes away. New scope: a brief paragraph noting that the bundle
  ships a vendored snapshot of `agentnative-spec` (re-vendored on each release) — no site-side coordination needed.

---

## Context & Research

### Relevant Code and Patterns

- **gstack reference implementation** (read directly during planning):
- `~/.claude/skills/gstack/bin/gstack-update-check` (~150 lines bash) — the load-bearing script. Reads local `VERSION`,
  curls remote, compares, emits `UPGRADE_AVAILABLE`/`UP_TO_DATE`/empty. Includes cache TTL (60min up-to-date, 720min
  upgrade-available), snooze with 3-level escalation, and a "JUST_UPGRADED" marker. Strip telemetry, install-type
  detection, and migration logic; keep the comparison + cache + snooze core.
- `~/.claude/skills/gstack-upgrade/SKILL.md` (~280 lines) — the inline upgrade flow with `AskUserQuestion` (4 options:
  Yes upgrade now / Always keep up-to-date / Not now / Never ask again). Strip the `auto_upgrade` config branch and the
  install-type detection; keep the AskUserQuestion + snooze-write pattern.
- The skill preamble pattern: every gstack skill's `## Preamble (run first)` section invokes `bin/gstack-update-check`
  early and routes the agent into the inline upgrade flow on `UPGRADE_AVAILABLE`. Mirror in `bundle/SKILL.md`.

- **agentnative-site install pipeline:**
- `agentnative-site/src/data/install.json` — manifest source of truth.
- `agentnative-site/src/build/install.mjs` — validator (`loadInstallData`), JSON emitter, markdown body builder
  (`buildInstallMarkdown`), HTML renderer.
- `agentnative-site/tests/build.test.ts` lines ~860–930 — install.json shape + validator tests.
- `agentnative-site/tests/regression.test.ts` lines ~131–146 — `dist/install.json` byte-equivalence + source.commit
  shape assertions.
- `agentnative-site/tests/e2e/install.e2e.ts` — Playwright e2e: every host clones, lands SKILL.md, `local HEAD ==
  manifest.source.commit`. The third assertion goes; the first two stay.
- `agentnative-site/.github/workflows/skill-availability.yml` — daily reachability probe. **No SHA references — keep
  verbatim.**

- **agentnative-skill bundle structure:**
- `bundle/` currently contains `SKILL.md`, `getting-started.md`, `references/`, `spec/`, `templates/`.
- No `bin/` or `scripts/` directory exists. U1 introduces `bundle/bin/check-update` (no `.sh` extension, mirrors gstack
  convention).
- `bundle/spec/VERSION` is the *vendored spec version* (separate concern from skill's own `VERSION` at repo root).
- The skill's own `VERSION` at repo root is the SoT for the update-check comparison.

### Institutional Learnings

- `agentnative-spec/docs/solutions/sot-contract-for-spec-repos-with-downstream-consumers-2026-04-22.md` — informs the
  general posture: downstream consumers should pull canonical state directly rather than relying on intermediary
  pinning. This change brings the install-flow story into alignment with that posture (consumer pulls from GitHub raw,
  not from anc.dev).

### External References

- gstack repo: `https://github.com/garrytan/gstack`. Source of the pattern. License compatible with skill bundle.

---

## Key Technical Decisions

- **Script location:** `bundle/bin/check-update` — ships with bundle, consumers can invoke directly without finding the
  install root. Mirrors gstack's `bin/gstack-update-check`. No `.sh` extension; shebang declares interpreter.

- **Remote VERSION URL:** `https://raw.githubusercontent.com/brettdavies/agentnative-skill/main/VERSION`. Same model as
  gstack. No site dependency, no third-party advertised SHA, single round-trip to GitHub.

- **State directory:** `$HOME/.cache/agent-native-cli/` (XDG cache spec). Holds `last-update-check` (cache file) and
  `update-snoozed` (snooze state). Single user-level directory; works regardless of which host (`~/.claude/skills/...`
  vs `~/.codex/skills/...`) the bundle is installed in.

- **Cache TTL:** 60min for `UP_TO_DATE`, 720min (12h) for `UPGRADE_AVAILABLE`. Mirrors gstack. Prevents excessive
  network round-trips while keeping the upgrade signal fresh on a workday cadence.

- **Snooze:** 3-level escalating backoff (24h → 48h → 7d). Mirrors gstack. Keeps the prompt from becoming a constant nag
  for users who deliberately deferred.

- **No telemetry, no auto-upgrade config, no install-type detection.** Strip gstack's surface to the load-bearing
  minimum for v0.2.0. Each of these is independently re-introducible later.

- **Update mechanism:** `git -C <skill-dir> pull --ff-only`. Simpler than gstack's `stash + fetch + reset --hard
  origin/main`. The skill bundle is meant to be read-only on consumer machines; if a consumer has uncommitted edits,
  they're explicitly opting out of the roll-forward update path and the `--ff-only` failure is the right signal.

- **`install.json` schema delta:** drop `version`, `source.commit`, `verify`. Keep `schema_version` (about install.json
  itself, unchanged), `type`, `name`, `description`, `principles_url`, `license`, `source.type`, `source.url`,
  `install`, `update`, `uninstall`, `install_page_html`. The `update` field stays as `cd <install-dir> && git pull
  --ff-only` (consumers can still update manually; the in-bundle script wraps the same command after a prompt).

- **install.mjs validator delta:** drop `SEMVER_RE`, `COMMIT_RE`. Drop `version` from `REQUIRED_TOP_LEVEL`. Drop
  `commit` from `REQUIRED_SOURCE`. Drop `verify` from `REQUIRED_TOP_LEVEL`. Drop `REQUIRED_VERIFY` array entirely. Keep
  install-command shape validators (must start with `git clone --depth 1`; explicit destination required).

- **buildInstallMarkdown delta:** drop the "Clones … (pinned at commit X)" prose, drop the entire `## Verify` section,
  drop the SHA reference in `## Trust model`, drop the "To pin a specific release: `git checkout <tag>`" line under `##
  Update`. Add a brief `## Stay current` section pointing at the bundled `bin/check-update` script as the recommended
  way to detect updates.

- **`bundle/SKILL.md` structure:** add a `## Update check` section near the top (before `## Layout` or wherever the
  agent's first read of SKILL.md naturally resolves the preamble). Section invokes `bundle/bin/check-update`, documents
  the `UPGRADE_AVAILABLE`/`UP_TO_DATE` outputs, and inlines the AskUserQuestion-based upgrade flow with the 4 standard
  options.

---

## Open Questions

### Resolved During Planning

- **Where does `bin/check-update` live?** `bundle/bin/check-update` (ships with bundle).
- **Does the SHA-pin removal break `skill-availability.yml`?** No. The workflow does `git ls-remote --exit-code … HEAD`
  — reachability check, no SHA references. Keep verbatim.
- **Does the install command change?** No. Still `git clone --depth 1 …`. Only the `install.json` schema and surrounding
  prose / validators / tests change.
- **Site `release/launch` `install.json` re-pin step?** Removed. The site no longer needs to re-pin on each skill
  release. The site `release/launch` PR for tonight's cuts becomes a smaller diff.
- **Inline upgrade flow location?** Inside `bundle/SKILL.md` itself as a subsection. Self-contained; no separate
  `agent-native-cli-upgrade/SKILL.md` mirror file.

### Deferred to Implementation

- **Exact AskUserQuestion option labels** in the SKILL.md preamble. Mirror gstack's wording verbatim unless implementer
  finds a better fit. Placeholder: "Yes, upgrade now" / "Not now" / "Never ask again". Drop "Always keep me up to date"
  since v0.2.0 has no auto-upgrade config to enable.
- **Whether `bundle/SKILL.md`'s `## Update check` section should be the *first* section after frontmatter** or sit below
  an introductory paragraph. Implementer reads existing SKILL.md flow and decides — the gstack precedent is
  preamble-first, but skill bundles have different conventions for first-impression content.
- **Whether `bundle/bin/check-update` needs to be `chmod +x` in git.** It does. Verify via `git ls-files --stage
  bundle/bin/check-update` showing `100755` after commit.
- **`install.mjs` validator strictness on extra fields:** does `loadInstallData` reject manifests with unknown keys
  (e.g., a stale `source.commit` field surviving in someone's local manifest), or accept-and-ignore? Reading the current
  code suggests it doesn't reject extras (it iterates `REQUIRED_*` lists rather than walking `Object.keys`). Confirm at
  implementation time and decide if behavior should change.
- **Whether `agentnative-site/RELEASES.md` `## Skill releases` runbook** keeps a (now-different) runbook step or drops
  the section entirely. Decision: drops (no skill-side coordination needed); fold any retained operator notes into a
  brief one-liner.

---

## Implementation Units

> **Status legend:** `not-started` (default) · `in-progress` · `done`. Unchecked `- [ ]` means the unit is not closed
> for launch. Each unit's `Target repo:` line names which repo's PR this work lands in.

---

- [x] U1. **Implement `bundle/bin/check-update` script** — done 2026-04-29 via PR #8 (`feat(bundle): consumer-side
  update-check mechanism (U1+U2)`). Path flattened to `bin/check-update` by PR #9 in the same launch wave; runtime
  contract unchanged. 40-test battery (unit + integration + e2e + red-team) shipped against the v0.3.0 layout: 40 pass /
  0 fail. Shipped to `main` via `release/v0.2.0` PR #12 squash-merge 2026-04-29 ~16:38 PT.

**Target repo:** `agentnative-skill`

**Goal:** A small bash script in the skill bundle that compares the consumer's local `VERSION` (the file at the
*producer-repo root*, vendored alongside the bundle when consumers `git clone`) against the raw GitHub `VERSION` on
`main` and emits a single-line status output.

**Requirements:** R2, R3.

**Dependencies:** None.

**Files:**

- Create: `bundle/bin/check-update` (executable shebang script, mode `100755`)
- Create: `bundle/bin/.gitkeep` if needed for empty-dir behavior — likely not needed since the script populates the
  directory.

**Approach:**

- Adapt `~/.claude/skills/gstack/bin/gstack-update-check` to agentnative-skill's context. Strip:
- Telemetry / Supabase POST in the slow path.
- Migration logic (the "codex-desc-healed" marker block).
- `gstack-config` integration. No `update_check` disable flag for v0.2.0; if a consumer truly wants to silence the
  check, they remove the script or override its PATH.
- The `--force` flag (defer; manual cache invalidation via `rm` works).
- Keep:
- VERSION read from `<bundle-root>/../VERSION` — i.e., the producer-repo root. The script's location at
  `bundle/bin/check-update` puts the repo root two levels up.
- Remote curl with `-sf --max-time 5`. Same URL pattern as gstack:
  `https://raw.githubusercontent.com/brettdavies/agentnative-skill/main/VERSION`.
- Validation that remote response looks like a version string (regex
  `^[0-9]+\.[0-9.]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$`). Reject HTML error pages.
- Cache TTL gating (60min `UP_TO_DATE`, 720min `UPGRADE_AVAILABLE`).
- 3-level snooze with escalating backoff (24h, 48h, 7d). Snooze file format: `<version> <level> <epoch>`.
- Output format: single line, one of `UPGRADE_AVAILABLE <local> <remote>` / `UP_TO_DATE` / empty. Empty is the
  silent-success case (cache hit on UP_TO_DATE within TTL). The agent reads the line and routes via the SKILL.md
  preamble.
- State directory: `$HOME/.cache/agent-native-cli/`. Auto-created on first run.
- Env overrides for testing: `AGENTNATIVE_SKILL_DIR` (override script's auto-detected bundle root),
  `AGENTNATIVE_SKILL_REMOTE_URL` (override raw GitHub URL), `AGENTNATIVE_SKILL_STATE_DIR`.

**Patterns to follow:**

- `~/.claude/skills/gstack/bin/gstack-update-check` — the source pattern. Comment header documents the contract;
  preserve that style with agentnative-skill-specific paths.
- skill repo's existing shell script conventions (`set -euo pipefail`, narrow disables in `.shellcheckrc`).

**Test scenarios:**

Test expectation: manual smoke testing per Verification below. Formal `bats` tests deferred per Scope Boundaries.

- Happy path: `VERSION=0.2.0` locally, remote returns `0.2.0` → stdout empty, exit 0, cache file written with
  `UP_TO_DATE 0.2.0`.
- Happy path: `VERSION=0.1.0` locally, remote returns `0.2.0` → stdout `UPGRADE_AVAILABLE 0.1.0 0.2.0`, exit 0, cache
  file written.
- Edge case: VERSION file missing → stdout empty, exit 0 (graceful degrade — no agent prompt on broken install).
- Edge case: remote curl fails (network down, DNS error, 5s timeout exceeded) → stdout empty, exit 0, no cache write (so
  next invocation retries).
- Edge case: remote returns garbage (HTML 404 page) → version-string regex rejects, stdout empty, exit 0, cache written
  with `UP_TO_DATE` to suppress retry storm.
- Edge case: snooze active for the current remote version → stdout empty (suppressed), exit 0. Re-emit when snooze
  expires or remote version moves past the snoozed value.
- Edge case: cache hit, `UP_TO_DATE` < 60min → fast path, no curl, stdout empty, exit 0.
- Edge case: cache hit, `UPGRADE_AVAILABLE` < 720min, not snoozed → stdout = cached line, no curl, exit 0.
- Error path: `$HOME` unset → script fails closed (exit 0, no output) rather than crashing; user-level cache is
  unavailable so behavior degrades to "always-fetch" silently.

**Verification:**

- `chmod -x bundle/bin/check-update && git ls-files --stage bundle/bin/check-update` reports mode `100755` after stage.
  (Verify the mode bit is committed.)
- `bash bundle/bin/check-update` from the skill repo root with no env overrides → empty output, exit 0 (assumes local
  VERSION matches remote main; if they differ at runtime, output is `UPGRADE_AVAILABLE` instead).
- `AGENTNATIVE_SKILL_REMOTE_URL=file:///tmp/fake-version-file bash bundle/bin/check-update` (with
  `/tmp/fake-version-file` containing `99.0.0`) → stdout `UPGRADE_AVAILABLE 0.2.0 99.0.0`.
- `shellcheck bundle/bin/check-update` clean (or only narrow disables documented inline).
- `bash -n bundle/bin/check-update` (syntax check) passes.

**Production smoke (post-v0.2.0 launch, 2026-04-29 ~17:25 PT):** end-to-end verification against the real
`raw.githubusercontent.com/brettdavies/agentnative-skill/main/VERSION` after the v0.2.0 tag was published. Path is now
`bin/check-update` (post-flatten via PR #9), not `bundle/bin/check-update`.

- Fresh clone via `git clone --depth 1 https://github.com/brettdavies/agentnative-skill.git` into `/tmp/`: 18 entries at
  install root including `SKILL.md`, `bin/`, `spec/`, `references/`, `templates/`, `VERSION=0.2.0`; `bin/check-update`
  mode `100755`. Confirms the flat-layout install model from PR #9.
- `rm -rf $HOME/.cache/agent-native-cli/ && echo '0.1.0' > VERSION && bash bin/check-update` → `UPGRADE_AVAILABLE 0.1.0
  0.2.0` (exact). Exercises the upgrade-detection path against the live remote.
- `rm -rf $HOME/.cache/agent-native-cli/ && echo '0.2.0' > VERSION && bash bin/check-update` → empty stdout, exit 0;
  cache file `$HOME/.cache/agent-native-cli/last-update-check` written with `UP_TO_DATE 0.2.0` (17 bytes incl. newline).
  Exercises the silent-success cold-start path.
- Re-run within 60min TTL → empty stdout, exit 0, no second cache write. Exercises the cache-hit fast path.

---

- [x] U2. **Update `bundle/SKILL.md` preamble + drop "pinned ref" prose from bundle docs** — done 2026-04-29 via PR #8
  (same squash as U1). `SKILL.md` (post-flatten path) carries the `## Update check` section with the
  `AskUserQuestion`-driven upgrade flow as the first non-frontmatter section. Adjacent "pinned ref" prose drops in
  `SKILL.md`/`getting-started.md`/`spec/README.md` shipped in #8; the broader pin-vocabulary scrub across
  `RELEASES.md`/`AGENTS.md`/`README.md`/`CONTRIBUTING.md` shipped separately as PR #11 (added to launch-wave scope
  mid-execution; see U6 below). Shipped to `main` via PR #12 squash-merge.

**Target repo:** `agentnative-skill`

**Goal:** `bundle/SKILL.md` instructs the agent to invoke `bundle/bin/check-update` early in any session and route the
output through an `AskUserQuestion`-driven inline upgrade flow when an upgrade is available. Adjacent bundle docs that
describe the spec vendoring as "pinned at a ref" lose the misleading framing while keeping the accurate "vendored
snapshot" semantics.

**Requirements:** R1 (prose drops), R2 (preamble + flow), R3 (no extra surface).

**Dependencies:** U1 (the script must exist for the preamble to invoke it).

**Files:**

- Modify: `bundle/SKILL.md` — add `## Update check` section + inline upgrade flow.
- Modify: `bundle/SKILL.md` line ~19 — drop "Vendored into [`bundle/spec/`](./spec/) at a pinned ref" → "Vendored into
  `bundle/spec/` (snapshot refreshed each release)".
- Modify: `bundle/getting-started.md` line ~64 — keep the "what spec version is this skill pinned to?" reference (it's
  accurate and useful — the bundle DOES carry a specific spec version) but reword to "What spec version does this bundle
  ship?" to drop the pinning framing.
- Modify: `bundle/spec/README.md` lines ~5, ~26 — reword "pinned upstream tag" → "vendored upstream snapshot"; reword
  "skill's pinned `SPEC_VERSION`" → "skill's vendored `SPEC_VERSION`".

**Approach:**

- The new `## Update check` section in `bundle/SKILL.md` is the load-bearing addition. Place it as the first section
  after the frontmatter and intro paragraph, so any agent reading SKILL.md to understand what the skill does picks up
  the preamble before the normal content.
- Section structure (paraphrasing — exact prose at implementation time):

1. **Run the check first thing.** "On first invocation per session, run `bash $(dirname $0)/bin/check-update`. If stdout
   is empty, the bundle is current; continue. If stdout is `UPGRADE_AVAILABLE <old> <new>`, follow the inline upgrade
   flow below before any other work."
2. **Inline upgrade flow.**

- Use `AskUserQuestion` with question "agent-native-cli **v{new}** is available (you're on v{old}). Upgrade now?"
- Options (3, not gstack's 4 — drop "Always keep me up to date" since v0.2.0 has no auto-upgrade config):
- "Yes, upgrade now"
- "Not now"
- "Never ask again"
- On "Yes, upgrade now": run `git -C <bundle-parent-dir> pull --ff-only` and report the new HEAD.
- On "Not now": write snooze file via the same format the script reads (`<remote_version> <new_level> <epoch>`). Tell
  user the snooze duration ("Next reminder in 24h" / "48h" / "7 days" depending on level).
- On "Never ask again": write a sentinel file `$HOME/.cache/agent-native-cli/disabled` that the script reads at Step 0
  and exits early on. (Alternative: document `rm bundle/bin/check-update` as the disable mechanism. Decide at
  implementation time.)
- Bundle docs prose drops: scope-limited reword passes per Files list above. Don't restructure surrounding sections.

**Patterns to follow:**

- `~/.claude/skills/gstack-upgrade/SKILL.md` Step 1 — the AskUserQuestion + snooze pattern. Strip the auto_upgrade
  branch and install-type detection; keep the rest verbatim where applicable.
- skill repo's existing SKILL.md voice (terse, agent-readable, RFC-flavored).

**Test scenarios:**

Test expectation: manual review per Verification below. SKILL.md is documentation; the agent's behavior is what matters
and is exercised end-to-end via U1's smoke tests + manual upgrade-flow walkthrough.

**Verification:**

- `markdownlint-cli2 'bundle/**/*.md'` clean.
- A manual walkthrough: run `bash bundle/bin/check-update` with a mocked-remote that returns a higher version, copy the
  `UPGRADE_AVAILABLE` line into a Claude Code session, confirm Claude reads SKILL.md's preamble correctly and routes to
  the AskUserQuestion + git pull flow without inventing extra steps.
- `grep -i 'pinned at\|pinned ref' bundle/` returns zero hits (or only matches in `bundle/spec/principles/` content
  vendored from agentnative-spec, which this plan doesn't touch).
- `bundle/SKILL.md` `## Update check` section is the first non-frontmatter section after the intro paragraph.

---

- [x] U3. **Drop SHA-pin fields from production manifest + validators**

**Target repo:** `agentnative-site`

**Outcome:** `src/data/skill.json` carries no SHA-pin fields; `source` is `{type, url}` only. `src/build/skill.mjs`
carries no `COMMIT_RE` / `SEMVER_RE` validators and no `REQUIRED_VERIFY` block. Rendered consumer surface (`/install`,
`/skill`, `.json`, `.md`, `.html`) has no "pinned at commit" prose and no `## Verify` section.

**Shipped via:** PR #44 (install→skill split, 2026-04-29); PR #67 + PR #72 via release PR #73 (SHA-pin enforcement drop,
2026-05-03).

---

- [x] U4. **Tests reflect the new manifest shape**

**Target repo:** `agentnative-site`

**Outcome:** `tests/build.test.ts`, `tests/regression.test.ts`, and the install/skill e2e suite carry no SHA-pin
assertions. Validator manifests use the surviving keys (`schema_version`, `type`, `name`, `description`,
`principles_url`, `license`, `source.{type, url}`, `install`, `update`, `uninstall`, `skill_page_html`).

**Shipped via:** PR #44 + PR #67 + PR #72 alongside the production-code changes.

---

- [x] U5. **Drop SHA-pin prose from site docs**

**Target repo:** `agentnative-site`

**Outcome:** `RELEASES.md`, `docs/DESIGN.md`, `AGENTS.md`, and `docs/VOICE.md` carry no live SHA-pin references.
Consumer-facing prose rendered from `skill.mjs` has neither "pinned at commit" language nor a `## Verify` section. The
launch-readiness plan (`docs/plans/2026-04-28-001-feat-show-hn-launch-readiness-plan.md`) was scrubbed of its four
`source.commit` jq checks; current-shape assertions reference `schema_version` and `source.url`.

**Shipped via:** PR #44 + PR #67 + PR #72 for the runbook / design / agents / voice docs; direct-to-`dev` plan edit
2026-05-27 for the launch-readiness scrub.

---

- [x] U6. **No live SHA-pin references in plan docs, pointers, or session trackers**

**Target repo:** mixed.

**Outcome:** `agentnative-skill` repo docs (`RELEASES.md`, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`,
`spec/README.md`) and `scripts/sync-spec.sh` carry no SHA-pin model claims. The bootstrap plan's task #15 describes the
actual cherry-pick scope without referencing the abandoned SHA-pin downstream model. The site launch-readiness plan's
four `source.commit` jq checks have been replaced with current-shape `schema_version` / `source.url` assertions. The
`~/.gstack/` central tracker and `agentnative-site` canonical pointer describe the `bin/check-update`-driven update
model.

**Shipped via:** PR #11 (skill repo-docs + `sync-spec.sh` rewrite, 2026-04-29); direct-to-`dev` edits to
`agentnative-skill/docs/plans/2026-04-27-001-bootstrap-agentnative-skill-plan.md`,
`agentnative-site/docs/plans/2026-04-28-001-feat-show-hn-launch-readiness-plan.md`, and the two `~/.gstack/` files
between 2026-04-29 and 2026-05-27.

---

## System-Wide Impact

- **Interaction graph:**
- Producer side: `agentnative-skill` ships the script + preamble; `agentnative-site` no longer needs to coordinate on
  each skill release.
- Consumer side: every Claude Code / Codex / Cursor / OpenCode session that reads `bundle/SKILL.md` runs the script
  early. The agent receives `UPGRADE_AVAILABLE` (or empty) and routes accordingly. No HTTP round-trip through anc.dev.
- **Error propagation:**
- Network failure during check: script outputs nothing, exits 0. Agent continues without prompt.
- `git pull --ff-only` failure (uncommitted changes, divergent history): consumer sees the failure directly. No silent
  partial-update.
- **State lifecycle risks:**
- Snooze file corruption: script defaults to "not snoozed" if format is invalid (defensive parse).
- Cache file corruption: script forces re-fetch. Mirrors gstack.
- Multi-host install (same user has skill in `~/.claude/skills/` AND `~/.codex/skills/`): both share the same state dir
  at `$HOME/.cache/agent-native-cli/`, so snooze + cache are global. Consequence: snoozing in one host snoozes in all.
  Acceptable for v0.2.0; revisit if it confuses users.
- **API surface parity:**
- `install.json` schema shrinks. Producers (the site) and consumers (any third party scripting `install.json` for
  discovery) need to handle the new shape. Forward-compatibility: extra fields are tolerated by `loadInstallData`
  (verify in U3); old consumers reading `source.commit` get `undefined` and need to handle.
- The `update` field in `install.json` keeps its current value (`cd <install-dir> && git pull --ff-only`). Consumers can
  still update manually without going through the bundle's `bin/check-update`.
- **Integration coverage:**
- U4's e2e test (`install.e2e.ts`) without the SHA assertion still proves: every host clones, SKILL.md lands at the
  expected path. That's the install-path invariant; the SHA assertion was redundant (it only proved that two values
  sourced from the same `git clone` at the same time matched).
- The full upgrade flow (`UPGRADE_AVAILABLE` → AskUserQuestion → `git pull --ff-only`) is exercised end-to-end only by
  manual smoke testing post-merge. Defer formal integration test to post-launch.
- **Unchanged invariants:**
- The `git clone --depth 1 …` install command. Same URL, same depth, same destination behavior.
- `skill-availability.yml` reachability probe. No SHA references; keeps doing what it does.
- The bundle's spec-vendoring posture (`bundle/spec/` is a snapshot of `agentnative-spec`, refreshed each release). This
  change drops the *language* of "pinning" but keeps the *behavior* of vendoring.
- The existing `update` field in `install.json` (consumers can still `cd <install-dir> && git pull --ff-only` if they
  prefer not to invoke `bin/check-update`).

---

## Risks & Dependencies

| Risk                                                                                                                                                                                                     | Mitigation                                                                                                                                                                                                                                                                          |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Launch eve timing — full plan + 6 units + tests takes 3-4h; cuts must happen tonight                                                                                                                     | U1 + U2 + U3 are the load-bearing path; U4 is mechanical; U5 + U6 are cleanup. If time-pressed, ship U1–U4 in v0.2.0 and defer U5–U6 to a fast-follow PR within 24h. The misleading prose in site docs is not consumer-facing on launch day; the install.json schema and tests are. |
| Script bug surfaces during launch-day install verification                                                                                                                                               | U1's smoke tests run before U2 lands. If the script behaves incorrectly post-merge, the worst case is `bundle/SKILL.md` instructs the agent to invoke a broken check; consumers see no upgrade prompt (graceful degrade — the script outputs nothing on any failure).               |
| `bin/check-update` mode bit not preserved through git operations                                                                                                                                         | Verify with `git ls-files --stage` after staging; use `chmod +x` and `git update-index --chmod=+x` if needed.                                                                                                                                                                       |
| `loadInstallData` accepts extra fields (so a stale `source.commit` lingering in someone's local manifest doesn't break the build) — but if it currently rejects extras, U3's edits could fail validation | Read `loadInstallData` carefully at U3 implementation time; the current code iterates `REQUIRED_*` lists rather than walking `Object.keys`, suggesting it accepts extras silently. Confirm before relying on this.                                                                  |
| Drift between `bundle/SKILL.md`'s preamble and what the agent actually does                                                                                                                              | Manual smoke test the full flow post-merge: install bundle on a clean machine, mock remote VERSION higher than local, run a Claude Code session, confirm the AskUserQuestion appears and `git pull --ff-only` runs.                                                                 |
| AskUserQuestion option labels surface to users — "Never ask again" semantics may be unclear (does it disable forever?)                                                                                   | Document the disable mechanism in SKILL.md's `## Update check` section. For v0.2.0, "Never ask again" writes a sentinel file the script reads at startup; document `rm $HOME/.cache/agent-native-cli/disabled` as the re-enable path.                                               |
| `git pull --ff-only` rejects when consumer has uncommitted edits in the bundle                                                                                                                           | This is the right behavior — the consumer needs to resolve the divergence themselves. The AskUserQuestion flow surfaces the git error and stops; it doesn't auto-stash.                                                                                                             |
| State directory `$HOME/.cache/agent-native-cli/` collides with another tool's cache (low-probability but possible)                                                                                       | Use a sufficiently specific directory name. If a future agentnative-cli puts its own cache here, namespace by tool: `$HOME/.cache/agent-native-cli/skill-update/`. Defer until proven needed.                                                                                       |
| U6's plan-doc scrub leaves dangling cross-references in long-form prose                                                                                                                                  | The verification grep catches obvious cases. For prose ambiguity (e.g., a paragraph that talks about "SHA pinning" historically), preserve historical context in addenda; only update active guidance.                                                                              |

---

## Documentation / Operational Notes

- **Post-merge documentation:** the bundle's new `## Update check` section is the authoritative consumer-facing
  reference. Site `RELEASES.md` updates point at it rather than restating the model.
- **Operator runbook (skill-side):** new release flow is `bump VERSION → cherry-pick to release/v<X.Y.Z> → tag → push`.
  No site-side coordination on each release. Daily `skill-availability.yml` probe still runs as a producer-reachability
  canary.
- **Consumer-side disable:** if a user wants to silence update checks, they remove the script (`rm
  bundle/bin/check-update`) or write the sentinel file (`touch $HOME/.cache/agent-native-cli/disabled`). Document both
  in SKILL.md.
- **Post-launch follow-ups (defer; not in scope):**
- Snooze duration tuning based on actual user feedback.
- Auto-upgrade configuration (mirror gstack's `auto_upgrade: true` setting if useful).
- Bats unit tests for `bin/check-update` (formal coverage).
- Telemetry on update-prompt acceptance rates (only with explicit opt-in).

---

## Sources & References

- **Parent (central tracker, source of truth):**
  `~/.gstack/projects/brettdavies-agentnative/brett-dev-design-show-hn-launch-inversion-20260427-144756.md`
- **Source pattern (read directly during planning):**
- `~/.claude/skills/gstack/bin/gstack-update-check`
- `~/.claude/skills/gstack-upgrade/SKILL.md`
- **Skill bootstrap plan (task #15 cherry-pick scope rides this plan):**
  `agentnative-skill/docs/plans/2026-04-27-001-bootstrap-agentnative-skill-plan.md`
- **Site repo current install pipeline:**
- `agentnative-site/src/data/install.json`
- `agentnative-site/src/build/install.mjs`
- `agentnative-site/tests/build.test.ts`, `agentnative-site/tests/regression.test.ts`,
  `agentnative-site/tests/e2e/install.e2e.ts`
- `agentnative-site/.github/workflows/skill-availability.yml`
- **Site prose docs touched by U5:**
- `agentnative-site/RELEASES.md`
- `agentnative-site/docs/DESIGN.md`
- `agentnative-site/docs/VOICE.md`
- `agentnative-site/AGENTS.md`
- **Cross-repo session memory:**
- `~/.claude/projects/-home-brett-dev-agentnative-spec/memory/` (audit decisions captured during this session)
- `~/.gstack/projects/brettdavies-agentnative*/cross-repo-canonical-pointer.md` (sibling-repo wiring)
- **Global rules:** `~/.claude/CLAUDE.md` — branch discipline, plan-doc carve-out, audience-bounded PR-flow rule.
