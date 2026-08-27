#!/usr/bin/env bash
set -eu

VERSION="$1"
BRANCH_NAME="kgtkr/update/v$VERSION"
OUTPUT_FILE="${2:-pr_body.txt}"

# 1. 変更ファイル一覧
CHANGED_FILES=$(git diff --name-only "v$VERSION"..HEAD)

FILES_LIST=""
for f in $CHANGED_FILES; do
  FILES_LIST="${FILES_LIST}- \`$f\`"$'\n'
done

# 2. kgtkr-meta 属性を除外した diff 詳細
DIFF_DETAILS=$(git diff "v$VERSION"..HEAD -- ':(exclude,attr:kgtkr-meta)')

PR_BODY="Automated update to Mastodon **v$VERSION**.

## Changed Files (v$VERSION vs $BRANCH_NAME)
$FILES_LIST

## Diffs (excluding kgtkr-meta files)
\`\`\`diff
$DIFF_DETAILS
\`\`\`"

if [ ${#PR_BODY} -gt 60000 ]; then
  PR_BODY="${PR_BODY:0:60000}"$'\n\n...(diff truncated due to length limits)'
fi

printf '%s' "$PR_BODY" > "$OUTPUT_FILE"
