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

1. An open upstream PR on the issue (comments, `refs/pull/*`) → cherry-pick it onto `fork` with `Upstream-PR: #<n>` and stop. Else branch `pr/<issue>-<slug>` from `main`, one commit, title by upstream `AGENTS.md` § Pull Requests, body with Context, Change, Test plan, `Closes #<n>`, trailers above.
2. Push the branch: `fork-check.yml` compiles it on macOS.
3. Cherry-pick the commit onto `fork`.
4. Open the upstream PR from the `pr/*` branch (Artur's GitHub account; upstream `pr-description.yml` rules apply).

## Build

`fork-check.yml`: unsigned Release build of scheme `TypeWhisper` plus `delta.py --check`, with upstream's own Xcode version and setup scripts (read from `.github/workflows/build.yml`, so a toolchain bump upstream needs no edit here).
Signed builds for Artur's Mac are the next stage: our own bundle id, our update feed instead of upstream's Sparkle feed (else upstream updates overwrite our build), and no TypeWhisper name or icon (`TRADEMARK.md`).
