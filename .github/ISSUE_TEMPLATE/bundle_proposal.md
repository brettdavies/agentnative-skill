---
name: Bundle proposal
about: Propose a new template, reference doc, getting-started flow, or other change to the skill bundle.
title: "proposal: <short description>"
labels: proposal
---

<!--
Route check before filing:

- New principle, MUST/SHOULD/MAY tier change, or any substantive change to the standard itself → file at
  https://github.com/brettdavies/agentnative/issues (the spec repo). This skill bundle vendors the spec; principle
  changes happen there first, then arrive here via `scripts/sync-spec.sh`.

- New compliance check, change to scorecard semantics, or anything `anc check` does → file at
  https://github.com/brettdavies/agentnative-cli/issues (the checker).

- New starter template, reference doc, getting-started flow, idiom for a new language/framework, or any change to how
  this bundle teaches the existing principles → keep filing here.
-->

## Problem statement

<!-- What is the problem this proposal addresses? Be specific about which agent's workflow it would improve.
     Cite real tools, real PRs, or real `anc` findings where relevant. -->

## Proposal

<!-- One paragraph: what should the bundle do that it does not do today? Frame as a concrete change to one or more
     of: bundle/SKILL.md, bundle/getting-started.md, bundle/references/<file>, bundle/templates/<file>. -->

## Type of change

- [ ] New starter template under `bundle/templates/`
- [ ] New reference doc under `bundle/references/`
- [ ] Update to `bundle/SKILL.md` (entry-point structure or routing)
- [ ] Update to `bundle/getting-started.md` (new flow, new invocation)
- [ ] Idioms for a new language/framework in `bundle/references/framework-idioms-other-languages.md`
- [ ] Other (describe)

## Prior art

<!-- Existing tools, docs, or articles that demonstrate the problem or the proposed solution. Two or three is fine. -->

- -

## Draft of the change

<!-- Sketch what the relevant bundle file(s) would look like after the change. A diff against the current state is
     ideal; an outline is acceptable for early-stage proposals. -->

```diff
<!-- bundle/<file> -->
```

## Compatibility

- [ ] Additive — no existing bundle content needs to change
- [ ] Replaces existing content — list what gets removed/superseded
- [ ] Coordinated with a spec or anc change — link the upstream issue/PR

## Open questions

<!-- Anything you're unsure about. Decisions to make in the issue thread before any PR. -->

-
