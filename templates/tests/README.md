# Adaptable test skeletons

Small, self-contained black-box test skeletons, principle-organized, for the two ecosystems this bundle ships worked
anchors in. They are the offline `cp` targets for the checklist in
[`references/testing.md`](../../references/testing.md); the language-to-harness table there maps the same structure onto
Python, Go, and Ruby.

| File                 | Harness                           | Distilled from                                                                         |
| -------------------- | --------------------------------- | -------------------------------------------------------------------------------------- |
| `cli-integration.rs` | Rust: `assert_cmd` + `predicates` | `agentnative-cli` `tests/integration.rs` @ `013a527b241ad2ed318963cec1ebf838f16f60fa`  |
| `worker.test.ts`     | TS: `bun:test`                    | `agentnative-site` `tests/worker.test.ts` @ `78fea0df3ee00579f84abfde6e249eeea8ad3ffe` |

## How to adapt

1. Copy the file into your repo's test directory (`cp <skill-root>/templates/tests/cli-integration.rs tests/`).
2. Replace every `YOUR_*` placeholder with your binary, verbs, routes, tokens, and documented exit codes. In the TS
   skeleton, swap the `declare` block for imports from your own handler.
3. Run the suite and watch it fail for the right reasons (red first), then make it pass; the assertions describe the
   contract, not the implementation.
4. Drop tests for surfaces your tool does not ship, and add one test per remaining arm of your exit-code table.

## Snapshots, not sources of truth

Each skeleton is a point-in-time snapshot of a CI-green file in its source repo; the header comment records the repo,
path, and commit SHA it was distilled from. The live file at the source repo's HEAD is the authoritative robust version.
When the source file changes materially, this bundle re-derives the skeleton and re-pins the SHA (policy in
`CONTRIBUTING.md`).
