---
title: "feat: Bootstrap agentnative-skill producer repo (Unit 1 of skill-distribution master plan)"
type: feat
status: complete
date: 2026-04-27
completed_date: 2026-04-27
public_flip_completed_date: 2026-04-28
v0_2_0_completed_date: 2026-04-29
v0.1.0_commit: 47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e
v0.1.0_tag_object: 5e2b676369a952c80da4bf133ce5ac03d34406a5
v0.2.0_commit: 2b10c845760becf3de8d66aafbb7b57820385d45
v0.2.0_tag_object: 054c249c36e92d5fc08603f701c999ac9ad187b6
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

All Step 9 gates pass:

- [x] `gh repo view brettdavies/agentnative-skill --json visibility -q .visibility` → `PUBLIC` (flipped 2026-04-28).
- [x] `gh repo view brettdavies/agentnative-skill --json defaultBranchRef -q .defaultBranchRef.name` → `main`.
- [x] `gh run list --branch main --limit 1` → CI job for the initial commit completed `success`.
- [x] `gh release list` → both `v0.1.0` and `v0.2.0` published.
- [x] `gh api repos/brettdavies/agentnative-skill/git/ref/tags/v0.1.0 --jq '.object.sha'` →
  `5e2b676369a952c80da4bf133ce5ac03d34406a5` (tag object SHA, recorded in frontmatter alongside the commit SHA
  `47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e`).
- [x] Force-push to `main` fails for non-admin: `protect-main` rules array blocks force-push; the `actor_type:
  RepositoryRole, actor_id: 5, bypass_mode: always` bypass allows admin overrides.
- [x] `markdownlint-cli2 '**/*.md'` exits zero locally.
- [x] `shellcheck scripts/*.sh scripts/checks/*.sh` exits zero with three narrow `.shellcheckrc` disables (`SC1091`,
  `SC2034`, `SC2125`) tolerating style-only findings in the migrated bundle scripts.
- [x] **Local install smoke test (Claude Code):**
      ```bash
      mkdir -p /tmp/anc-test-home/.claude/skills
      HOME=/tmp/anc-test-home git clone --depth 1 git@github.com:brettdavies/agentnative-skill.git \
        /tmp/anc-test-home/.claude/skills/agent-native-cli
      ls /tmp/anc-test-home/.claude/skills/agent-native-cli/SKILL.md   # exists
      rm -rf /tmp/anc-test-home
      ```
      (SSH clone was verified during the bootstrap session against the then-private repo. After the 2026-04-28 public
      flip, both `git clone https://github.com/brettdavies/agentnative-skill.git` and the SSH form should work; the
      site session's e2e relies on the HTTPS path.)

### Step 10: Hand-off note

Handoff was delivered to the orchestrator chat with the bootstrap SHAs (commit
`47a76cceb8b7b1bc013c19ee18a5e38179b1dd0e`, tag object `5e2b676369a952c80da4bf133ce5ac03d34406a5`) and repo visibility
(`PRIVATE` during bootstrap, flipped `PUBLIC` 2026-04-28). No separate handoff doc was committed.

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
