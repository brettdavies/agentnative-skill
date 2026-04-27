---
name: Bug report
about: A check produces wrong results, a script fails, or a doc says one thing while the code does another.
title: "bug: <short description>"
labels: bug
---

## What happened

<!-- One or two sentences. Include the command you ran and the unexpected behavior. -->

## What you expected

<!-- One sentence — what should the bundle have done instead? -->

## How to reproduce

1. 1. 1.

```bash
# exact commands; redact paths/credentials
```

## Environment

- Bundle version (`cat bundle/VERSION` if cloned, or the tag you installed): vX.Y.Z
- Host (Claude Code / Cursor / Codex / other):
- Target tool the checker was run against (if applicable): owner/repo @ commit
- OS and shell:
- `bundle/scripts/check-compliance.sh --principle N` output (if relevant):

```text
<paste relevant scorecard rows or error output>
```

## Why this is a bundle bug, not a target-tool bug

<!-- Optional but very useful. If a check fails on a tool that you believe is correctly implementing the principle,
     explain why. Cite the relevant section of bundle/SKILL.md or bundle/references/principles-deep-dive.md. -->
