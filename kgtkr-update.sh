#!/usr/bin/env bash
set -eux

if [ -z "${1:-}" ] || [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be in X.Y.Z format (e.g. 4.6.3)" >&2
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION_ARR=(${1//./ })
MINOR_VERSION=${VERSION_ARR[0]}.${VERSION_ARR[1]}
VERSION=$MINOR_VERSION.${VERSION_ARR[2]}

if ! git diff-index --quiet HEAD --; then
  echo "Error: Working directory has uncommitted changes. Please commit or stash them first." >&2
  exit 1
fi

git fetch --all
git push --tags

git checkout kgtkr-master
git merge --ff-only origin/kgtkr-master

# kgtkr-masterのアップデート
git merge $(git merge-base main v$VERSION) # コンフリクト発生の可能性
git push origin kgtkr-master


if git checkout kgtkr-$MINOR_VERSION; then
  git merge --ff-only origin/kgtkr-$MINOR_VERSION
else
  git checkout -b kgtkr-$MINOR_VERSION
fi

# kgtkr-$MINOR_VERSION のアップデート
git merge kgtkr-master
git merge v$VERSION
git push origin kgtkr-$MINOR_VERSION

# mstdn.kgtkr.net のアップデート
git checkout mstdn.kgtkr.net
git reset --hard kgtkr-$MINOR_VERSION
git push -f origin mstdn.kgtkr.net

git checkout kgtkr-master
