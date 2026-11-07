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

BASE_TAG=$(git tag --merged HEAD -l "v*" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)

CUSTOM_PATCH=$(mktemp)
git diff --binary "$BASE_TAG" HEAD > "$CUSTOM_PATCH"

git merge --no-commit --no-ff -s ours "v$VERSION"
git read-tree --reset -u "v$VERSION"

if [ -s "$CUSTOM_PATCH" ]; then
  git apply --3way "$CUSTOM_PATCH" || true
fi
rm -f "$CUSTOM_PATCH"

if [ -z "$(git diff --name-only --diff-filter=U)" ]; then
  GIT_MERGE_AUTOEDIT=no git commit --no-edit
fi
