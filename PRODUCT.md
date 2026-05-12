# PRODUCT.md

Channel-specific design context for the **skill bundle channel** of agentnative. Inherits the shared identity, voice
anchor, audiences, and universal anti-patterns from `BRAND.md` — synced from
[`agentnative-spec`](https://github.com/brettdavies/agentnative) alongside `spec/principles/`. Until that sync runs,
read the source at [`brettdavies/agentnative/BRAND.md`](https://github.com/brettdavies/agentnative/blob/main/BRAND.md).
See [`spec/README.md`](./spec/README.md) for resync instructions.

## Channel — skill bundle

The skill bundle teaches agents how to use `anc` and the spec. The spec describes the contract; the linter verifies it;
the skill bundle teaches the workflow that connects the two.

## Audience (narrowed)

- **AI agents** loading the skill via Claude Code's skill discovery (frontmatter triggers), Cursor's skill registry,
  Codex's `~/.codex/skills/`, OpenCode's `.opencode/skills/`, and equivalent runtimes. The agent reads `SKILL.md` first,
  drills into [`getting-started.md`](./getting-started.md) for one of three loops (existing CLI / new Rust CLI / other
  language), and consults `references/` only when remediating a specific `anc` finding.
- **Humans** running `anc skill install <host>` for the first time, or maintaining the bundle. They expect commands to
  be runnable as written, paths to resolve, and the bundle to track what `anc` produces.

## Register

- **Instructional voice.** Second-person imperative is the default. "Run `anc check . --output json` to score the repo."
  Not "the skill recommends running `anc check`."
- **Every action is a runnable command.** Code blocks contain commands the reader can paste. Pseudo-commands and
  prose-only "how to think about it" are out.
- **Reference-shaped tables.** Where the artifact is a list of options, files, or trade-offs, render it as a table with
  stable column headers. The three-artifact table at the top of `SKILL.md` and the useful-flags paragraph in
  `getting-started.md` are the patterns.
- **Triggers and keywords are first-class.** The skill's `description` frontmatter determines which agents discover the
  skill. Keep it dense in the canonical vocabulary (`agentic CLI`, `agent-native`, `anc check`, `audit-profile`, …). The
  opposite of marketing prose; closer to a search-index line.
- **Cross-link to the spec, the linter, and the templates.** A skill that paraphrases what the spec says drifts. Link
  instead, and quote the requirement ID, not the prose.

## Skill-specific anti-patterns

These extend the universal bans in `BRAND.md`:

- **No "in this guide we will…" preamble.** The agent skips it. Open with the action.
- **No narrative scaffolding.** "First, we'll cover X. Then, Y. Finally, Z." Out. The TOC and section headings carry the
  structure; prose that recapitulates them is noise.
- **No "consider doing X" hedges.** State the action. "Run `anc check`." Not "you might want to consider running `anc
  check`."
- **No paraphrased spec content.** When the contract matters, link to `spec/principles/p<N>-*.md` and quote the
  requirement ID (`p1-must-no-interactive`), not the prose. Spec drift is silent and expensive when paraphrased.
- **No screenshots, no images.** The skill is consumed by agents; images are tokens-for-no-signal.
- **No version numbers in prose.** "Currently `v0.3.0`" goes stale. Reference [`VERSION`](./VERSION) and
  [`spec/VERSION`](./spec/VERSION) directly, or link to the canonical source. Frontmatter aside.

## Voice anchor application

The pattern in `BRAND.md`, specialized for the skill channel:

- **`SKILL.md`** opens with the three-artifact table (spec / linter / skill), the first action (update check), then the
  launch link to `getting-started.md`. No preamble.
- **`getting-started.md`** opens with the three loops, each as a runnable command sequence with inline annotation.
- **`references/*.md`** are exhaustive references for one technical area each (Rust/clap patterns, framework idioms,
  project structure, update check). Each section stands alone; readers arrive via deep links from `anc` findings.
- **`templates/*`** are the smallest functional starting points, not "examples." A copied template runs.

## Status

This file is the skill-channel `PRODUCT.md`. The spec channel's equivalent lives at
[`agentnative-spec/PRODUCT.md`](https://github.com/brettdavies/agentnative/blob/main/PRODUCT.md); the site channel's at
`~/dev/agentnative-site/PRODUCT.md`. Cross-channel content is in `BRAND.md`, synced from the spec repo.
