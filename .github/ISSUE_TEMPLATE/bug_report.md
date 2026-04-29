---
name: Bug report
about: A bundle file has a wrong example, a stale path, a broken cross-reference, or contradicts the spec.
title: "bug: <short description>"
labels: bug
---

<!--
Before filing:

- For bugs in `anc` (the checker itself, e.g. wrong scorecard, missing check), file at
  https://github.com/brettdavies/agentnative-cli/issues
- For substantive principle changes (new principles, MUST/SHOULD/MAY tier changes), file at
  https://github.com/brettdavies/agentnative/issues
- This tracker is for skill-bundle bugs: stale templates, broken links, wrong invocations in `getting-started.md`, drift
  between vendored spec and other bundle docs, etc.
-->

## What happened

<!-- One or two sentences. Include the file, the cited example, and the unexpected behavior. -->

## What you expected

<!-- One sentence — what should the bundle have said or done instead? -->

## How to reproduce

1. 1. 1.

```bash
# exact commands or quoted bundle content; redact paths/credentials
```

## Environment

- Bundle version (`cat VERSION` if cloned, or the tag you installed): vX.Y.Z
- Pinned spec version (`cat spec/VERSION`): vX.Y.Z
- Host (Claude Code / Cursor / Codex / other):
- `anc --version` (if a workflow involving anc is at issue):
- OS and shell:

## Why this is a bundle bug, not a spec or anc bug

<!-- Optional but very useful. If a getting-started flow doesn't work, explain whether the breakage is in this
     bundle's prose (fixable here) vs. in anc's behavior (file in agentnative-cli) vs. in the principle text
     itself (file in agentnative-spec). -->
