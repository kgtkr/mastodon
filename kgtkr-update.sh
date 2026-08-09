#!/usr/bin/env bash
set -eux

COMMAND="all"
VERSION_ARG=""

if [ "$#" -ge 2 ]; then
  COMMAND="$1"
  VERSION_ARG="$2"
elif [ "$#" -eq 1 ]; then
  if [[ "$1" =~ ^(master|release|all)$ ]]; then
    echo "Error: Version argument is required." >&2
    exit 1
  else
    COMMAND="all"
    VERSION_ARG="$1"
  fi
else
  echo "Usage: $0 [master|release|all] <version>" >&2
  exit 1
fi

if [[ ! "$VERSION_ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be in X.Y.Z format (e.g. 4.6.3)" >&2
  exit 1
fi

VERSION_ARR=(${VERSION_ARG//./ })
MINOR_VERSION=${VERSION_ARR[0]}.${VERSION_ARR[1]}
VERSION=$MINOR_VERSION.${VERSION_ARR[2]}

update_master() {
  if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory has uncommitted changes." >&2
    exit 1
  fi

  git fetch --all
  git push --tags || true

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$CURRENT_BRANCH" != update/* ]]; then
    git checkout kgtkr-master
    git merge --ff-only origin/kgtkr-master || true
  fi

  UPSTREAM_BASE="main"
  if git rev-parse --verify origin/main &>/dev/null; then
    UPSTREAM_BASE="origin/main"
  elif git rev-parse --verify upstream/main &>/dev/null; then
    UPSTREAM_BASE="upstream/main"
  fi

  MERGE_BASE=$(git merge-base "$UPSTREAM_BASE" "v$VERSION")
  git merge "$MERGE_BASE" --no-edit || true
}

update_release() {
  if git checkout "kgtkr-$MINOR_VERSION" 2>/dev/null; then
    git merge --ff-only "origin/kgtkr-$MINOR_VERSION" || true
  else
    git checkout -b "kgtkr-$MINOR_VERSION"
  fi

  git merge kgtkr-master --no-edit
  git merge "v$VERSION" --no-edit

  git checkout mstdn.kgtkr.net 2>/dev/null || git checkout -b mstdn.kgtkr.net
  git reset --hard "kgtkr-$MINOR_VERSION"
}

case "$COMMAND" in
  master)
    update_master
    ;;
  release)
    update_release
    ;;
  all)
    update_master
    update_release
    ;;
esac
