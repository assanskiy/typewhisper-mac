#!/usr/bin/env bash
# Rebase the fork's delta onto upstream main. Exit 0 rebased (HEAD = candidate), 2 conflict (nothing changed).
set -euo pipefail
UPSTREAM_URL=https://github.com/TypeWhisper/typewhisper-mac.git
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch --no-tags upstream main
git fetch --no-tags origin fork
git checkout -q -B fork origin/fork
before=$(git rev-list --count upstream/main..fork --)
if ! git rebase upstream/main; then
  git diff --name-only --diff-filter=U | sed 's/^/conflict: /'
  git rebase --abort
  exit 2
fi
after=$(git rev-list --count upstream/main..HEAD --)
echo "delta commits: $before before, $after after (dropped $((before - after)) already upstream)"
