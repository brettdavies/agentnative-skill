# Vendored agentnative-spec

This directory is a **vendored copy** of [`brettdavies/agentnative`](https://github.com/brettdavies/agentnative) — the
canonical specification of agent-native CLI principles. Files here are not edited by hand; they are mirrored from the
latest upstream `v*` tag and ship inside the skill bundle so consumers carry the canonical principle text alongside the
skill metadata. Each release of this bundle re-vendors against the latest spec tag. The currently vendored version is
recorded in [`VERSION`](./VERSION).

## Resync

Run from the repo root:

```bash
git -C $HOME/dev/agentnative-spec fetch --tags    # pick up new upstream tags first
scripts/sync-spec.sh                              # auto-resolves the latest v* tag
```

The script extracts files at the resolved tag via `git show`, so the spec checkout's working tree is not perturbed.
Override `SPEC_ROOT` if your spec checkout is not at `$HOME/dev/agentnative-spec`.

## Layout

| Path               | Source in `agentnative-spec` | Purpose                                                       |
| ------------------ | ---------------------------- | ------------------------------------------------------------- |
| `VERSION`          | `VERSION`                    | Spec version string; the skill's vendored `SPEC_VERSION`      |
| `CHANGELOG.md`     | `CHANGELOG.md`               | Spec change history; informational                            |
| `principles/p*.md` | `principles/p*.md`           | Frontmatter `requirements[]` is the machine-readable contract |

Each principle file has a YAML frontmatter block with `id`, `title`, `last-revised`, `status`, and `requirements[]`.
Each `requirements[]` entry carries a stable `id` (e.g. `p1-must-no-interactive`), a `level` (`must`/`should`/`may`), an
`applicability` (`universal` or `{if: <reason>}`), and a one-sentence `summary`. The `anc` checker
([brettdavies/agentnative-cli](https://github.com/brettdavies/agentnative-cli)) emits these IDs in its scorecard so
agents can navigate from a finding directly to the requirement.

## Licensing

Upstream content is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). This skill bundle is
dual-licensed under MIT or Apache-2.0; vendoring a CC BY 4.0 source requires attribution only, satisfied by this README
plus the upstream project link in each principle's frontmatter `id` field.
