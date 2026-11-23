# Fork of TypeWhisper

Artur's fork of [TypeWhisper/typewhisper-mac](https://github.com/TypeWhisper/typewhisper-mac) (GPL-3.0; the developer agreed to it).
Goal: a workbench for changes offered upstream. Artur runs the developer's own releases; this fork ships no build of its own.
Each change is written, checked in CI, reviewed and run on a Mac here, then opened as a PR to upstream.

## Branches

| branch | what it holds | who writes it |
|---|---|---|
| `main` | an exact mirror of upstream `main`, never committed to | `fork-sync.yml` only, force-aligned to upstream |
| `tooling` (default) | upstream `main` + this fork's tooling (`fork/`, `fork-*.yml`), commits marked `Fork-Delta: fork-only` | rebased by `fork-sync.yml` |
| `pr/<issue>-<slug>` | one change, one commit, based on upstream `main` | the session fixing it; the upstream PR is opened from it |
| `issue-media` | screenshots linked from issues and PR bodies | the session posting them |

Each commit over upstream carries `Fork-Delta: upstream-pr` (`Upstream-Issue: #<n>`, later `Upstream-PR: #<n>`) or `Fork-Delta: fork-only`.
`python3 fork/delta.py --base main --head <ref>` prints the table; `--check` fails on a commit without the trailer.

## Sync

`fork-sync.yml` runs daily and on demand: it force-aligns `main` to upstream `main`, rebases `tooling` onto it, and pushes `tooling` only after `fork-check.yml` passes on the result.
A conflict stops the job, leaves `tooling` untouched and opens an issue `sync conflict`.
`pr/*` branches are rebased by hand when upstream moves under them.

## Adding a change

1. Labels `needs discussion` or `effort: large` → a design comment on the issue first (decisions the maintainer must make, a sketch, a smaller first PR); code after his answer.
2. An open upstream PR on the issue (comments, `refs/pull/*`) → no change of ours: wait for it or review it. Else branch `pr/<issue>-<slug>` from `main`, one commit, title by upstream `AGENTS.md` § Pull Requests, body with Context, Change, Test plan, `Closes #<n>`, trailers above. Commit with `--cleanup=verbatim`: git's default cleanup drops a body line starting with `#`.
3. Push the branch, then dispatch `fork-check.yml` on `tooling` with input `ref: pr/<issue>-<slug>`: it compiles and tests it on macOS (a `pr/*` branch holds no fork workflow, so a push alone runs nothing).
4. Review: a fresh reviewer (not the author) judges the commit against the issue, the reporter's real setup and who else hits the problem; only SHIP goes on. A change that serves one setup only is not offered.
5. Run it on a Mac: build the branch in Debug (bundle id `com.typewhisper.mac.dev`, «TypeWhisper Dev», side by side with the installed release), replay the issue's scenario, run `scripts/pr-preflight.sh`.
6. Open the upstream PR from the `pr/*` branch (Artur's GitHub account; upstream `pr-description.yml` rules apply). The orchestrator's `projects/typewhisper/fork/upstream_prs.py --open` refuses a branch until steps 3–5 are recorded for its current code.

## Build

`fork-check.yml`: unsigned Release build of scheme `TypeWhisper` plus `delta.py --check`, with upstream's own Xcode version and setup scripts (read from `.github/workflows/build.yml`, so a toolchain bump upstream needs no edit here).
