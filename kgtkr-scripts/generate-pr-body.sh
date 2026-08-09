#!/usr/bin/env bash
set -eu

VERSION="$1"
BRANCH_NAME="kgtkr/update/v$VERSION"
OUTPUT_FILE="${2:-pr_body.txt}"

CHANGED_FILES=$(git diff --name-only "v$VERSION"..HEAD)

FILES_LIST=""
for f in $CHANGED_FILES; do
  FILES_LIST="${FILES_LIST}- \`$f\`"$'\n'
done

DIFF_DETAILS=""
for f in $CHANGED_FILES; do
  if [[ "$f" != *kgtkr* ]]; then
    FILE_DIFF=$(git diff "v$VERSION"..HEAD -- "$f")
    if [ -n "$FILE_DIFF" ]; then
      DIFF_DETAILS="${DIFF_DETAILS}"$'\n'"### \`$f\`"$'\n'"\`\`\`diff"$'\n'"$FILE_DIFF"$'\n'"\`\`\`"$'\n'
    fi
  fi
done

PR_BODY="Automated update to Mastodon **v$VERSION**.

## Changed Files (v$VERSION vs $BRANCH_NAME)
$FILES_LIST

## Diffs (excluding files containing 'kgtkr')
$DIFF_DETAILS"

if [ ${#PR_BODY} -gt 60000 ]; then
  PR_BODY="${PR_BODY:0:60000}"$'\n\n...(diff truncated due to length limits)'
fi

printf '%s' "$PR_BODY" > "$OUTPUT_FILE"
