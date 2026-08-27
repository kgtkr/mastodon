#!/usr/bin/env bash
set -eux

if [ -z "${1:-}" ] || [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be in X.Y.Z format (e.g. 4.6.5)" >&2
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"

if ! git diff-index --quiet HEAD --; then
  echo "Error: Working directory has uncommitted changes." >&2
  exit 1
fi

git fetch --all
git push --tags || true

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != kgtkr/update/* ]]; then
  git checkout kgtkr-master
  git merge --ff-only origin/kgtkr-master || true
fi

git merge "v$VERSION" --no-edit || true
