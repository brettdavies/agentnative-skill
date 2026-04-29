# Getting started

This skill teaches agents how to design, build, or audit a CLI for use by other agents. The work is one of three loops;
pick the one that matches your starting point. The canonical checker is
[`anc`](https://github.com/brettdavies/agentnative-cli); the canonical principle text is in
[`spec/principles/`](./spec/principles/).

## You have an existing CLI

```bash
# 1. Run the checker.
anc check --output json . > scorecard.json

# 2. For each FAIL, look up the cited requirement_id (e.g. `p1-must-no-interactive`)
#    in spec/principles/p<N>-*.md — frontmatter `requirements[]`.

# 3. Apply the fix. Patterns live in:
#      references/rust-clap-patterns.md                (Rust/clap)
#      references/framework-idioms.md                  (Rust idioms)
#      references/framework-idioms-other-languages.md  (Click, argparse, Cobra, Commander, yargs, oclif, Thor)
#    Re-run `anc check` until the scorecard is clean.
```

Useful flags: `--principle N` to focus on one principle, `--audit-profile <category>` to suppress checks that don't
apply (e.g. `human-tui` for tools that legitimately intercept the TTY), `--binary` / `--source` to scope.

## You're building from scratch (Rust)

```bash
cargo init my-tool && cd my-tool

# Starter files. Encode P1–P7 by construction.
cp <skill-root>/templates/clap-main.rs          src/main.rs
cp <skill-root>/templates/error-types.rs        src/error.rs
cp <skill-root>/templates/output-format.rs      src/output.rs
cp <skill-root>/templates/agents-md-template.md AGENTS.md   # fill placeholders

# Add to Cargo.toml: clap (derive, env), serde, serde_json, thiserror,
# libc (SIGPIPE), clap_complete. See references/project-structure.md.

anc check --output json    # run continuously as you build
```

## You're building in another language

`anc`'s source-analysis layer is Rust-only; its behavioral layer (`anc check --command <name>`) runs against any
compiled binary on `PATH`. Read `spec/principles/p1-*.md` through `p7-*.md` for the language-agnostic requirements, and
`references/framework-idioms-other-languages.md` for per-framework idioms.

## Installing anc

```bash
brew install brettdavies/tap/agentnative   # macOS / Linux
cargo install agentnative
```

Binary name: `anc`. Prebuilt releases at <https://github.com/brettdavies/agentnative-cli/releases>.

## Where things live

| Question                                        | Where                                              |
| ----------------------------------------------- | -------------------------------------------------- |
| What does P3 mean?                              | `spec/principles/p3-progressive-help-discovery.md` |
| What spec version does this bundle ship?        | `spec/VERSION`                                     |
| How do I implement `<pattern>` in Rust/clap?    | `references/rust-clap-patterns.md`                 |
| How do I implement `<pattern>` in Python/Go/JS? | `references/framework-idioms-other-languages.md`   |
| File a spec question or proposal                | <https://github.com/brettdavies/agentnative>       |
| File an `anc` bug                               | <https://github.com/brettdavies/agentnative-cli>   |
| File a skill-bundle issue                       | <https://github.com/brettdavies/agentnative-skill> |
