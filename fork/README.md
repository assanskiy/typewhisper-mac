# Fork of TypeWhisper

Artur's fork of [TypeWhisper/typewhisper-mac](https://github.com/TypeWhisper/typewhisper-mac) (GPL-3.0; the developer agreed to it).
Goal: get fixes and features sooner than upstream ships them, keep upstream compatibility, and offer every change back upstream.
The iOS fork of the private `typewhisper-ios` joins once read access exists.

## Branches

| branch | what it holds | who writes it |
|---|---|---|
| `main` | an exact mirror of upstream `main`, never committed to | `fork-sync.yml` only, force-aligned to upstream |
| `fork` (default) | upstream `main` + our delta commits on top, linear | rebased by `fork-sync.yml`; a change lands by cherry-picking its `pr/*` commit |
| `pr/<issue>-<slug>` | one delta item, one commit, based on upstream `main` | the session fixing it; the upstream PR is opened from it |

The delta is `git log main..fork`. Each delta commit carries trailers:

- `Fork-Delta: upstream-pr` (offered upstream, `Upstream-Issue: #<n>`, later `Upstream-PR: #<n>`) or `Fork-Delta: fork-only` (this tooling, branding, signing).

`python3 fork/delta.py` prints the table (commit, kind, issue, upstream PR state); `--check` fails on a delta commit without the trailer.

## Sync

`fork-sync.yml` runs daily and on demand: it force-aligns `main` to upstream `main`, rebases `fork` onto it, and pushes `fork` only after `fork-check.yml` passes on the result.
A delta commit upstream already merged drops out by itself (the rebase skips a patch upstream already holds).
A maintainer-edited version conflicts instead: the job stops, leaves `fork` untouched and opens an issue `sync conflict`; resolve by dropping our commit if upstream's version covers the case.

## Adding a change

1. Labels `needs discussion` or `effort: large` → a design comment on the issue first (decisions the maintainer must make, a sketch, a smaller first PR); code after his answer.
2. An open upstream PR on the issue (comments, `refs/pull/*`) → cherry-pick it onto `fork` with `Upstream-PR: #<n>` and stop. Else branch `pr/<issue>-<slug>` from `main`, one commit, title by upstream `AGENTS.md` § Pull Requests, body with Context, Change, Test plan, `Closes #<n>`, trailers above.
3. Push the branch, then dispatch `fork-check.yml` on `fork` with input `ref: pr/<issue>-<slug>`: it compiles and tests it on macOS (a `pr/*` branch holds no fork workflow, so a push alone runs nothing).
4. Review: a fresh reviewer (not the author) judges the commit against the issue, the reporter's real setup and who else hits the problem; only SHIP goes on. A change that serves one setup only stays `fork-only`.
5. Run it on a Mac: build the branch, replay the issue's scenario, run `scripts/pr-preflight.sh`.
6. Cherry-pick the commit onto `fork`.
7. Open the upstream PR from the `pr/*` branch (Artur's GitHub account; upstream `pr-description.yml` rules apply). The orchestrator's `projects/typewhisper/fork/upstream_prs.py --open` refuses a branch until steps 3–5 are recorded for its current code.

## Build

`fork-check.yml`: unsigned Release build of scheme `TypeWhisper` plus `delta.py --check`, with upstream's own Xcode version and setup scripts (read from `.github/workflows/build.yml`, so a toolchain bump upstream needs no edit here).
Signed builds for Artur's Mac are the next stage: our own bundle id, our update feed instead of upstream's Sparkle feed (else upstream updates overwrite our build), and no TypeWhisper name or icon (`TRADEMARK.md`).
