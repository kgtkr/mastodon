#!/usr/bin/env bash
set -eu

VERSION_ARR=(${1//./ })
MINOR_VERSION=${VERSION_ARR[0]}.${VERSION_ARR[1]}
VERSION=$MINOR_VERSION.${VERSION_ARR[2]}

git fetch --all
git push --tags

git checkout kgtkr-master
git pull

# kgtkr-masterのアップデート
git merge $(git merge-base main v$VERSION) # コンフリクト発生の可能性
git push origin kgtkr-master


git checkout kgtkr-$MINOR_VERSION || git checkout -b kgtkr-$MINOR_VERSION
git pull

# kgtkr-$MINOR_VERSION のアップデート
git merge kgtkr-master
git merge v$VERSION
git push origin kgtkr-$MINOR_VERSION

# mstdn.kgtkr.net のアップデート
git checkout mstdn.kgtkr.net
git reset --hard kgtkr-$MINOR_VERSION
git push -f origin mstdn.kgtkr.net

git checkout kgtkr-master
