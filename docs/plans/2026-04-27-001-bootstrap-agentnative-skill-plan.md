---
title: "feat: Bootstrap agentnative-skill producer repo (Unit 1 of skill-distribution master plan)"
type: feat
status: complete-pending-public-flip
date: 2026-04-27
completed_date: 2026-04-27
v0.1.0_commit: 47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e
v0.1.0_tag_object: 5e2b676369a952c80da4bf133ce5ac03d34406a5
master_plan: ../../../agentnative-site/docs/plans/2026-04-24-001-feat-skill-distribution-endpoint-plan.md
related_session: ../../../agentnative-site/docs/plans/2026-04-27-001-feat-skill-distribution-site-plan.md
origin: master plan Unit 1, executed in dedicated session
---

# feat: Bootstrap agentnative-skill producer repo

## Session Context

This plan is executed by a **dedicated session whose cwd is `~/dev/agentnative-skill/`**. A parallel session in
`~/dev/agentnative-site/` runs the matching site-side plan (Units 2–5). The two sessions exchange exactly **one
artifact**: the v0.1.0 commit SHA produced here, consumed there as `source.commit` in `src/data/install.json`.

**Master plan (canonical reference):**
`~/dev/agentnative-site/docs/plans/2026-04-24-001-feat-skill-distribution-endpoint-plan.md` — Unit 1. **Sibling site
plan:** `~/dev/agentnative-site/docs/plans/2026-04-27-001-feat-skill-distribution-site-plan.md` — Units 2–5 plus the
public-flip cutover.

This document defines execution shape; the master plan defines architectural rationale. Read the master plan's Unit 1
section first if any decision below feels under-justified.

## State at Session Start

- **Repo created (this current session):** `github.com/brettdavies/agentnative-skill` (private, empty, topics applied).
- **Local clone present:** `~/dev/agentnative-skill/` containing only `.git/`. Origin =
  `git@github.com:brettdavies/agentnative-skill.git`.
- **Bundle source (private, author's machine):** `~/dev/agent-skills/agent-native-cli/` — pre-audited; no private path
  references found via `grep -rln -E '(agent-skills|~/dev|/home/brett)'`.
- **Bundle inventory (verified at planning time):**
- `SKILL.md` (root)
- `checklists/new-tool.md`
-

`references/{framework-idioms,framework-idioms-other-languages,principles-deep-dive,project-structure,rust-clap-patterns}.md`

- `scripts/check-compliance.sh`
- `scripts/checks/_helpers.sh` + 21 `check-*.sh` scripts (broader than the master plan's illustrative list — copy the
  actual filesystem, do not enforce the master plan's incomplete enumeration)
- `templates/{agents-md-template.md,clap-main.rs,error-types.rs,output-format.rs}`

## Goals

1. Stand up the public producer repo with the bundle at the root, governance files, CI gates, and v0.1.0 tag.
2. Migrate via clean-room re-commit (no history import from the private source).
3. Apply `github-repo-setup` skill defaults (branch protection, tag protection, CODEOWNERS).
4. **Stop before public flip.** The visibility cutover is coordinated with the site PR in the sibling session.
5. Hand off the v0.1.0 commit SHA to the site session via a one-line note.

## Non-Goals

- **No `gh repo edit --visibility public`.** That is the final cutover step in the site plan, not here.
- **No site repo edits.** Cross-repo coordination is via SHA handoff only.
- **No content rewriting of SKILL.md or scripts.** Migration is byte-faithful copy. Content evolution is post-bootstrap.
- **No git history import** from the private source. The private repo's branches, authorship, and paths must not leak.
- **No signed tags in v1.** Documented in the master plan as deferred to v2.

## Branch Discipline (initial commit special case)

The master plan and global CLAUDE.md mandate `dev` off `main`, features off `dev`, PR'd back. An empty repo has no
`main` to PR against — the first commit is a bootstrap exception:

1. Bootstrap commit lands on `main` directly (no PR — there is nothing to review against).
2. Immediately after, create `dev` tracking `main`. Push it. **Leave `main` as the repo default branch** — this matches
   the rest of the agentnative ecosystem (`agentnative`, `agentnative-cli`, `agentnative-site` all default to `main`). A
   naive `git clone` should land visitors on the released bundle, not on `dev`'s WIP.
3. Tag `v0.1.0` on the bootstrap commit (pre-`dev` creation is fine; tag refers to commit SHA, not branch).
4. Any subsequent work in this repo (post-v0.1.0) follows full discipline: feat/*off `dev`, squash-PR to `dev`,
   release/* cherry-picked from `main` and PR'd to `main`.

The bootstrap exception is one commit only. Repeat-edits during this session must NOT pile onto `main`; if you discover
a fix mid-session, force yourself onto a `feat/*` branch.

## Implementation Steps

### Step 1: Verify session preconditions

```bash
pwd                                          # → /home/brett/dev/agentnative-skill
git remote -v                                # → origin git@github.com:brettdavies/agentnative-skill.git (fetch+push)
git status                                   # → clean, on no branch yet (empty repo)
ls ~/dev/agent-skills/agent-native-cli/      # → bundle source visible
gh auth status                               # → authenticated as brettdavies
```

If any check fails, stop and ask the orchestrator. The repo creation in the parent session is the only external
prerequisite; everything else from here is local work.

### Step 2: Author governance files

Create at repo root (do **not** copy from master plan verbatim — write fresh content suited to a single-skill repo):

- **`README.md`** — short. What this repo is (the `agent-native-cli` skill bundle, cloned-in-place install model),
  pointer to `https://anc.dev/install` for install instructions, pointer to `https://anc.dev/p1` for principles,
  license, contribution model. ~50 lines max.
- **`LICENSE`** — MIT, year 2026, copyright Brett Davies. Match the form used in `~/dev/agentnative-site/LICENSE` if
  present (read it for exact wording); otherwise standard SPDX MIT text.
- **`CHANGELOG.md`** — keepachangelog.com format. Initial section: `## [0.1.0] - 2026-04-27 — Initial release`. Bullets
  describe the bundle (7 principles, 24 compliance checks, templates).
- **`VERSION`** — single line `0.1.0\n`. No frontmatter, no metadata. This is the source of truth for the version string
  the site reads at release time.
- **`SECURITY.md`** — vulnerability disclosure policy. Channel: GitHub private security advisories
  (`https://github.com/brettdavies/agentnative-skill/security/advisories/new`). 90-day disclosure window. Reference
  `SECURITY.md` patterns from `~/dev/agentnative-cli/SECURITY.md` if it exists.
- **`.gitignore`** — minimal: editor scratch files (`.DS_Store`, `*.swp`, `.idea/`, `.vscode/`), local todos
  (`TODO*.md`, `.context/`), build artifacts if any (`target/`, `node_modules/`).
- **`.gitattributes`** — `* text=auto eol=lf` and `*.sh text eol=lf` to enforce line endings on shell scripts (Windows
  hosts will checkout LF). This is in the master plan's risk table; the file IS the mitigation.

### Step 3: Migrate the bundle (clean-room copy)

```bash
# Copy each top-level item from the source. Use cp -a to preserve mode bits (scripts must remain +x).
cp -a ~/dev/agent-skills/agent-native-cli/SKILL.md         ./
cp -a ~/dev/agent-skills/agent-native-cli/checklists       ./
cp -a ~/dev/agent-skills/agent-native-cli/references       ./
cp -a ~/dev/agent-skills/agent-native-cli/scripts          ./
cp -a ~/dev/agent-skills/agent-native-cli/templates        ./

# Verify scripts kept executable bits.
ls -l scripts/*.sh scripts/checks/*.sh | awk '{print $1, $NF}' | grep -v 'rwx' && \
  echo 'FAIL: non-executable scripts found' || echo 'OK: scripts executable'

# Final frontmatter audit — should output nothing (matched at planning time, re-verify after copy).
rg -n --no-heading '(agent-skills|~/dev|/home/brett)' . || echo 'OK: no private paths'
```

**Frontmatter audit beyond paths:** `SKILL.md`'s top-level `description` field and `name` should match the deployed
skill. The frontmatter at planning time was clean — re-grep after the copy and pause if anything new surfaces.

### Step 4: CI workflow

Create `.github/workflows/ci.yml`. Jobs:

1. `markdownlint` — runs `markdownlint-cli2` against `**/*.md`. Use the action pinned to a commit SHA per global
   CLAUDE.md SHA-pinning rule (resolve via `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`).
2. `shellcheck` — runs against `scripts/*.sh` and `scripts/checks/*.sh` with severity `style`. Use a pinned-by-SHA
   action.

Triggers: `push` on `main`/`dev`/`feat/**`, `pull_request` against `main`/`dev`. Required for branch protection in Step
7.

The site session has a `~/dev/agentnative-site/.github/workflows/ci.yml` reference; you may consult it for action SHA
patterns but do NOT introduce any other site-specific CI logic — this repo's CI is intentionally minimal.

### Step 5: CODEOWNERS

Create `.github/CODEOWNERS`:

```text
# Mandatory review on anything that runs on user machines at install time
scripts/**          @brettdavies
.github/workflows/  @brettdavies
```

Per master plan risk row "Shell scripts in producer repo execute on user machines" — this is the review gate.

### Step 6: Initial commit + push

```bash
git checkout -b main                                                  # create main locally
git add -A
git status --short                                                    # sanity scan; no surprises
git commit -m "feat: initial bundle for agent-native-cli v0.1.0

Migrate the agent-native-cli skill bundle into a public producer repo.
Bundle ships at the repo root so 'git clone' directly into a host's
skills directory IS install.

Includes:
- SKILL.md (north-star standard, 7 principles)
- checklists/, references/, scripts/, templates/
- 24 compliance checks across 9 groups (scripts/checks/*)
- governance: LICENSE (MIT), CHANGELOG, VERSION, SECURITY.md, CODEOWNERS
- CI: markdownlint + shellcheck

Source: clean-room re-commit from a private bundle that lived on the
author's machine since March 2026. No history imported.

Companion endpoints (anc.dev/install, anc.dev/install.json) ship via
the agentnative-site repo, pinning to this commit SHA."
git push -u origin main

# Now create dev tracking main and push it.
# Leave `main` as the repo default branch (matches the rest of the
# ecosystem: agentnative, agentnative-cli, agentnative-site all
# default to main). A naive `git clone` should land on the released
# bundle, not on dev's WIP.
git checkout -b dev
git push -u origin dev
```

### Step 7: Tag v0.1.0

Tag on `main` (the bootstrap commit), then push:

```bash
git checkout main
git tag -a v0.1.0 -m "v0.1.0 — initial release"
git push origin v0.1.0

# Capture SHA for the site session handoff.
git rev-parse v0.1.0    # → 40-char SHA — copy this verbatim
```

**Hand off the SHA to the orchestrator.** The site session needs this exact value as `source.commit` in
`src/data/install.json`.

### Step 8: Apply repo settings (branch + tag protection)

Use `gh api` against the rulesets endpoint (modern replacement for branch-protection). The `github-repo-setup` skill is
the authoritative source for the rules — invoke it via `Skill(skill="github-repo-setup", args="audit + apply")` if
present; otherwise apply the following manually.

**Branch ruleset (covers `main` AND `dev`):**

- Force-push: blocked.
- Branch deletion: blocked.
- Required status checks: `markdownlint`, `shellcheck` (the two CI jobs from Step 4).
- Require linear history: optional (nice-to-have for a small repo, not load-bearing).
- Bypass: repo admins permitted (so `gh repo edit --visibility public` and emergency hotfixes still work).

**Tag ruleset (covers `v*`):**

- Force-push (re-tag): blocked.
- Tag deletion: blocked.
- Bypass: repo admins permitted.

Verify both rulesets actually take effect:

```bash
gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[].name'    # should list both
git checkout main
git commit --allow-empty -m "test: should be rejected" && git push origin main
# expected: refused by ruleset; if accepted, the protection isn't applied
```

(Reset / discard the test commit after verifying refusal.)

### Step 9: Verification gates

Mark this Unit complete only when ALL of these are green:

- [ ] `gh repo view brettdavies/agentnative-skill --json visibility -q .visibility` → `PRIVATE` (cutover is later, not
  here).
- [ ] `gh repo view brettdavies/agentnative-skill --json defaultBranchRef -q .defaultBranchRef.name` → `main`.
- [ ] `gh run list --branch main --limit 1` → CI job for the initial commit completed `success`.
- [ ] `gh release list` → empty for now (no GitHub Release object created — the tag exists, the release doesn't; v1
  doesn't need a Release object).
- [ ] `gh api repos/brettdavies/agentnative-skill/git/ref/tags/v0.1.0 --jq '.object.sha'` → matches the SHA captured in
  Step 7.
- [ ] Force-push to `main` fails (verified in Step 8).
- [ ] `markdownlint-cli2 '**/*.md'` exits zero locally.
- [ ] `shellcheck scripts/*.sh scripts/checks/*.sh` exits zero locally (or shows only style-level warnings explicitly
  tolerated by the CI config).
- [ ] **Local install smoke test (Claude Code):**
      ```bash
      mkdir -p /tmp/anc-test-home/.claude/skills
      HOME=/tmp/anc-test-home git clone --depth 1 git@github.com:brettdavies/agentnative-skill.git \
        /tmp/anc-test-home/.claude/skills/agent-native-cli
      ls /tmp/anc-test-home/.claude/skills/agent-native-cli/SKILL.md   # exists
      rm -rf /tmp/anc-test-home
      ```
      (SSH clone works against private repo for this user; the public e2e in the site session will use HTTPS.)

### Step 10: Hand-off note

Append a short note to the orchestrator's chat (do NOT commit a separate handoff doc to the repo):

```text
agentnative-skill v0.1.0 ready for site pin.
Commit SHA: <40-char SHA from Step 7>
Repo: still PRIVATE — public flip pending site PR cutover.
```

That's the entire cross-session handoff payload.

## Risks & Mitigations (this session only)

| Risk                                                                  | Mitigation                                                                                                                                                                                                    |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Accidental include of bundle source's parent dir or hidden files      | `git status --short` between copy and commit; explicit per-item `cp -a` (Step 3) rather than wildcard from source root                                                                                        |
| Scripts lose +x bits on copy                                          | `cp -a` preserves modes; verification in Step 3 fails loud if any script is non-executable                                                                                                                    |
| `markdownlint` flags existing skill content not previously CI-checked | Resolve in-session: either fix the markdown to pass, or add a narrowly-scoped `.markdownlint.jsonc` exception with a comment explaining why. Do NOT lower the bar globally                                    |
| Branch protection blocks the very `git push` that creates `dev`       | Push `main` BEFORE creating the ruleset (Step 6 precedes Step 8); rulesets apply on next push                                                                                                                 |
| Frontmatter audit false-negative — private path slips through         | Re-run audit in Step 3 AFTER copy, not just at planning time; the planning-time grep is supporting evidence, not a substitute                                                                                 |
| GitHub Release object expected but not created                        | Master plan does not require a Release object for v1 — tag suffices. Don't create one speculatively                                                                                                           |
| Tag created on `dev` instead of `main`                                | Step 7 explicitly checks out `main` before tagging. The bootstrap commit is on `main`; `dev` was created from it so they point at the same SHA at this moment, but the canonical tag-bearing branch is `main` |
| Site session starts before this is done                               | The user is orchestrating both sessions and will not start the site session before this session reports the SHA                                                                                               |

## Files Touched (in this repo only)

```text
.gitattributes
.gitignore
.github/CODEOWNERS
.github/workflows/ci.yml
CHANGELOG.md
LICENSE
README.md
SECURITY.md
SKILL.md                       # migrated from ~/dev/agent-skills/agent-native-cli/
VERSION
checklists/new-tool.md         # migrated
docs/plans/2026-04-27-001-bootstrap-agentnative-skill-plan.md  # this plan, committed alongside bootstrap
references/                    # migrated (5 files)
scripts/                       # migrated (1 top-level + 1 helper + 21 check scripts)
templates/                     # migrated (4 files)
```

## Sources & References

- **Master plan:** `~/dev/agentnative-site/docs/plans/2026-04-24-001-feat-skill-distribution-endpoint-plan.md` (Unit 1)
- **Sibling site plan (parallel session):**
  `~/dev/agentnative-site/docs/plans/2026-04-27-001-feat-skill-distribution-site-plan.md`
- **Bundle source (private, author's machine):** `~/dev/agent-skills/agent-native-cli/`
- **Skill on Claude Code (live):** `~/.claude/skills/agent-native-cli/` — same content as the bundle source; do NOT use
  this path as the migration source (it may diverge from the master copy in `~/dev/agent-skills/`)
- **External:** [agentskills.io specification](https://agentskills.io/specification),
  [garrytan/gstack](https://github.com/garrytan/gstack)
- **Global rules consulted:** `~/.claude/CLAUDE.md` (SHA-pinning, branch discipline, no AI attribution, dev-flow
  squash-merge)

---

## Post-execution addendum (2026-04-27)

This section captures what actually happened during execution, including deviations from the plan, discoveries, and
follow-up work that was scoped in-session. The plan above is preserved as authored. Where the addendum contradicts the
plan, the addendum is canonical.

### Final state at end of session

| Ref                              | Value                                                                   |
| -------------------------------- | ----------------------------------------------------------------------- |
| Bootstrap commit on `main`       | `47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e`                              |
| Tag object SHA for `v0.1.0`      | `5e2b676369a952c80da4bf133ce5ac03d34406a5`                              |
| Repo visibility                  | `PRIVATE` (deliberate; flip happens in the agentnative-site session)    |
| Default branch                   | `dev`                                                                   |
| Latest `dev` head at session end | `80099fc` (chore: AGENTS.md, PR template, RELEASES.md, guard-main-docs) |

The site session pins `source.commit` in `src/data/install.json` to the **bootstrap commit SHA**
(`47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e`), not the tag object SHA.

### Deviations from the plan

#### Step 6 — branch creation

The plan said `git checkout -b main`. The empty repo defaulted to `main` with no commits, so the local `git checkout -b
main` step was a no-op (already on `main`). The push and downstream steps proceeded as written.

#### Step 6 / Step 7 — bootstrap commit rewrite

The original plan included `docs/plans/2026-04-27-001-bootstrap-agentnative-skill-plan.md` in the bootstrap commit on
`main` (per the original "Files Touched" list). The user flagged that plans must not appear on `main` (global branch
discipline; `docs/plans/**` is a `dev`-only path).

The fix required:

1. `trash docs/plans/...` and `git commit --amend` on `main` to remove the plan from the bootstrap commit.
2. `git push origin main --force-with-lease` (the only force-push to `main` in this session; pre-rulesets so allowed).
3. `git tag -d v0.1.0`, `git push origin :refs/tags/v0.1.0`, retag, push tag.
4. `git reset --hard main` on `dev` to align dev with the new `main`, then re-add the plan as a separate commit on `dev`
   (`docs: add v0.1.0 bootstrap plan (dev-only)`), `git push origin dev --force-with-lease`.

SHAs changed across the rewrite: bootstrap commit went from `01f64d7...` to `47a76cc...`; tag object went from
`a2523fd...` to `5e2b676...`. Both are recorded in the frontmatter.

This is the canonical reason the addendum table holds the correct SHAs and not whatever the original Step 7 transcript
shows.

#### Step 7 — SHA semantics

The plan instructed `git rev-parse v0.1.0` to capture the SHA for handoff. For an annotated tag, that returns the **tag
object SHA**, not the commit SHA. The handoff requires the commit SHA, accessed via `git rev-parse v0.1.0^{commit}` or
`gh api repos/.../commits/v0.1.0 --jq .sha`. Both SHAs are recorded explicitly above.

The Step 9 verification gate "tag SHA matches" compares the tag object SHA from `gh api .../git/ref/tags/v0.1.0 --jq
'.object.sha'` against `git rev-parse v0.1.0` — those agree (both are tag-object SHAs), so the gate is satisfied as
written.

#### Step 8 — rulesets unavailable on private free-tier

Both modern rulesets (`/repos/.../rulesets`) and legacy branch protection (`/repos/.../branches/.../protection`) return
`HTTP 403 — Upgrade to GitHub Pro or make this repository public to enable this feature` on private free-tier repos. The
plan assumed Step 8 would apply rulesets immediately while still private. It cannot.

What was actually done:

- `repo-settings.sh apply` ran successfully for the non-Pro-gated settings (squash-only merge, signoff, etc.).
- The three ruleset JSONs (`protect-main.json`, `protect-dev.json`, `protect-tags.json`) were authored under
  `.github/rulesets/` along with a `README.md` that documents the apply procedure and negative tests.
- Application of the rulesets was deferred to a follow-up task ("Step 11" in the in-session task list, executed
  post-public-flip). Without rulesets, the Step 9 gate "Force-push to `main` fails" cannot be verified yet.

#### Step 9 — verification gate adjustments

| Gate                         | Status at session end                               |
| ---------------------------- | --------------------------------------------------- |
| visibility = PRIVATE         | met                                                 |
| default branch = main        | met (corrected post-bootstrap; see deviation below) |
| CI on `main` succeeded       | met                                                 |
| `gh release list` empty      | met                                                 |
| tag object SHA matches       | met                                                 |
| force-push to `main` refused | **deferred** to post-public-flip ruleset apply      |
| markdownlint clean           | met                                                 |
| shellcheck clean             | met (with `.shellcheckrc` per "Additions" below)    |
| local clone smoke test       | met                                                 |

#### Step 10 — handoff payload

The handoff carries both SHAs (commit + tag object) so the consumer cannot accidentally pin to the wrong one. Per plan,
the handoff is via the orchestrator chat, no committed handoff doc.

#### Default branch — corrected post-bootstrap

The plan's Step 6 and Branch-Discipline section originally said to set `dev` as the repo default branch. This was a plan
error: the rest of the agentnative ecosystem (`agentnative`, `agentnative-cli`, `agentnative-site`) uses `default=main`,
and a naive `git clone` should land visitors on the released bundle, not on `dev`'s WIP. The plan now correctly leaves
`main` as default; both Step 6 and the Branch-Discipline section have been updated above. The live repo was originally
configured with `default=dev` (executing the now-corrected plan literally) and was switched to `default=main` via `gh
repo edit brettdavies/agentnative-skill --default-branch main` once the divergence was spotted. Step 9's gate is updated
accordingly.

### Additions not in the original plan

These were authored in-session because reality required them. Each is stable to keep.

| File                                    | Why                                                                                                                                                                                                                                                                                                                                                                  |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.markdownlint-cli2.yaml`               | Repo-local copy of the canonical 120-char config from `~/.markdownlint-cli2.yaml`. Without it, CI defaults to 80-char and fails on the migrated `SKILL.md` and `templates/agents-md-template.md`. The skill canonical config doesn't ship globally — every repo carries its own copy. Marked `Canonical version: 2026.04.15` so drift is detectable.                 |
| `.shellcheckrc`                         | Three narrow disables (`SC1091`, `SC2034`, `SC2125`) tolerating style-only findings in the migrated bundle scripts. The plan's "no content rewriting" rule meant those scripts couldn't be modified in v0.1.0; the gate verbiage explicitly allowed "style-level warnings explicitly tolerated by the CI config". The disables are commented in-file with rationale. |
| `.github/rulesets/protect-main.json`    | Branch ruleset for `main`: required signatures, linear history, squash-only PR with CODEOWNERS review, three required status checks (`markdownlint`, `shellcheck`, `guard-docs / check-forbidden-docs`), creation/deletion/non-fast-forward blocked. Bypass: admins.                                                                                                 |
| `.github/rulesets/protect-dev.json`     | Branch ruleset for `dev`: deletion + force-push blocked, required signatures. No PR-requirement at the ruleset level (`dev` is the integration branch).                                                                                                                                                                                                              |
| `.github/rulesets/protect-tags.json`    | Tag ruleset for `v*`: deletion, force-push (re-tag), and updates all blocked. Tags are immutable historical anchors that the site's `install.json` pins to.                                                                                                                                                                                                          |
| `.github/rulesets/README.md`            | Apply + verify procedure for all three rulesets, intended to be run post-public-flip.                                                                                                                                                                                                                                                                                |
| `AGENTS.md`                             | Project-level agent instructions for this repo specifically (NOT the Rust template). Repo's `.gitignore` was extended with `!AGENTS.md` to override the global `**/AGENTS.md` ignore for this repo only.                                                                                                                                                             |
| `RELEASES.md`                           | Release procedure adapted from the canonical `~/.claude/skills/github-repo-setup/references/RELEASES.md` for the lightweight `dev → main` model (no `release/*` cherry-pick). Documents version-bump procedure, branch model, ruleset apply, and the verified status-check context table.                                                                            |
| `.github/pull_request_template.md`      | Copy of the canonical `~/.config/github/pull_request_template.md`. Required because GitHub does not follow symlinks for PR-template discovery.                                                                                                                                                                                                                       |
| `.github/workflows/guard-main-docs.yml` | Caller for the `brettdavies/.github` reusable workflow that blocks `docs/plans/`, `docs/solutions/`, `docs/brainstorms/`, `docs/reviews/` from PRs targeting `main`. **Mechanically prevents** the failure mode that triggered the bootstrap-commit rewrite above.                                                                                                   |

### Adopted release pattern

Lightweight `feat/* → dev → main` (single squash-merge per release; no `release/*` cherry-pick branches). Documented
end-to-end in `RELEASES.md`. The full `release/*` pattern is not justified for a content+scripts repo — there's no
crates.io publish, no Homebrew dispatch, no cross-platform build, and `guard-main-docs.yml` already filters engineering
docs out of release-time PRs.

### Outstanding tasks (carried forward to the agentnative-site session or owner)

All resolved 2026-04-28 in the post-public-flip "Step 11" follow-up. See
[Step 11 — post-public-flip execution](#step-11--post-public-flip-execution-2026-04-28) below.

- ~~**Apply rulesets post-public-flip.**~~ Done.
- ~~**`allow_auto_merge`.**~~ Done — required explicit toggle (did not self-resolve on flip).
- ~~**Secret scanning + push protection.**~~ Done — required explicit toggle.

### Step 11 — post-public-flip execution (2026-04-28)

Visibility flipped via `gh repo edit brettdavies/agentnative-skill --visibility public
--accept-visibility-change-consequences`. All three rulesets posted from `.github/rulesets/*.json` and confirmed
`enforcement: active`:

| Ruleset ID | Name                 | Target          | Rules                                                                                                                    |
| ---------- | -------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------ |
| 15669559   | Protect main         | refs/heads/main | creation, deletion, non_fast_forward, pull_request, required_signatures, required_status_checks, required_linear_history |
| 15669560   | Protect dev          | refs/heads/dev  | deletion, non_fast_forward, required_signatures                                                                          |
| 15669561   | Protect release tags | refs/tags/v*    | deletion, non_fast_forward, update                                                                                       |

All three rulesets share `bypass_actors: [{actor_id: 5, actor_type: RepositoryRole, bypass_mode: always}]` — admin
always-bypass, per the `.github/rulesets/README.md` "Bypass" section.

#### Negative-test caveat

The negative tests in `.github/rulesets/README.md` ("force-push to main must be refused", "re-tagging v0.1.0 must be
refused") are written for a **non-admin actor**. The repo owner has `bypass_mode: always`, so a solo run of those tests
by the owner cannot demonstrate refusal — the push succeeds via bypass. The Step 9 gate "force-push to `main` refused"
was therefore **verified by configuration inspection** (rules array + bypass list, both fetched via
`/repos/.../rulesets/<id>`) rather than by destructive push. Enforcement is meaningful for any non-admin actor:
collaborators, fine-grained PATs, GitHub Apps. A future non-admin push attempt will populate
`/repos/.../rulesets/rule-suites` with a recorded refusal.

Plan addendum's negative tests should be re-read with this in mind: the tests in `.github/rulesets/README.md` remain
correct *as written*, but only a non-admin actor can run them. Updating that README to call this out explicitly is a
cleanup pass for a later session.

#### Repo settings — drift resolved

`repo-settings.sh report` post-flip showed three actionable drifts (none self-resolved on the visibility flip):

| Setting                           | Before   | After   |
| --------------------------------- | -------- | ------- |
| `allow_auto_merge`                | false    | true    |
| `secret_scanning`                 | disabled | enabled |
| `secret_scanning_push_protection` | disabled | enabled |

`secret_scanning_non_provider_patterns` and `secret_scanning_validity_checks` remain disabled — both require GitHub
Advanced Security (paid). The audit script reports these as warnings rather than failures.

Applied via `~/.claude/skills/github-repo-setup/scripts/repo-settings.sh apply brettdavies/agentnative-skill`. Final
state: "Repo settings: ✓ compliant", "Security: warnings only — no actionable drift".

#### Step 9 gate — final reconciliation

| Gate                         | Status (post-Step-11)                                       |
| ---------------------------- | ----------------------------------------------------------- |
| visibility = PRIVATE         | superseded — flipped to PUBLIC 2026-04-28 per Step 11       |
| default branch = main        | met                                                         |
| CI on `main` succeeded       | met                                                         |
| `gh release list` empty      | met                                                         |
| tag object SHA matches       | met                                                         |
| force-push to `main` refused | met by configuration inspection (admin bypass caveat above) |
| markdownlint clean           | met                                                         |
| shellcheck clean             | met                                                         |
| local clone smoke test       | met                                                         |

### Inputs from this session that survived past the plan

- Bootstrap commit SHA `47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e` is the load-bearing artifact for the site session.
- The lightweight release pattern + `guard-main-docs.yml` is the structural lesson — the plan-on-main bug is now
  mechanically impossible going forward.
