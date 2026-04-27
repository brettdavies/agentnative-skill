---
name: Principle proposal
about: Propose a new principle, a substantive change to an existing principle, a new check, or a new template.
title: "proposal: <short description>"
labels: proposal
---

## Problem statement

<!-- What is the problem this proposal addresses? Be specific about which agent-native CLI failure modes it would
     prevent or which user need it would serve. Cite real tools or real PRs where relevant. -->

## Proposal

<!-- One paragraph: what should the bundle do that it does not do today? Frame as a change to bundle/SKILL.md
     or bundle/references/principles-deep-dive.md or both. -->

## Type of change

- [ ] New principle (P8 or later)
- [ ] Tightening an existing principle's MUST/SHOULD/MAY semantics
- [ ] Removing or relaxing an existing principle (major version bump)
- [ ] New automated check under `bundle/scripts/checks/`
- [ ] New template under `bundle/templates/`
- [ ] Other (describe)

## Prior art

<!-- Existing tools, specs, or articles that demonstrate the problem or the proposed solution. Two or three is fine. -->

- -

## Draft of the change

### `bundle/SKILL.md` diff sketch

```diff
<!-- Show approximately what would change in SKILL.md -->
```

### `bundle/references/principles-deep-dive.md` diff sketch

```diff
<!-- For new or substantively-changed principles, sketch the MUST/SHOULD/MAY language. -->
```

### Check / template additions

<!-- For new checks: which group does it belong to? What is its pass criterion? Does it produce PASS / WARN / FAIL?
     For new templates: which existing reference docs would point at it? -->

## Backward compatibility

- [ ] Backward-compatible (existing tools that pass today still pass after this change)
- [ ] Tightens — some currently-passing tools would start failing or warning. List representative examples:
- [ ] Breaking — explicit major version bump justified because:

## Open questions

<!-- Anything you're unsure about. Decisions to make in the issue thread before any PR. -->

-
