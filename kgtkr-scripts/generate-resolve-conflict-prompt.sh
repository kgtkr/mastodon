#!/usr/bin/env bash
set -eu

FILE="${1:-}"
AGENTS_RULES=""
[ -f ".agents/AGENTS.md" ] && AGENTS_RULES=$(cat .agents/AGENTS.md)

cat <<EOF
You are an AI coding assistant resolving git merge conflicts in a Mastodon fork repository.
Below are the project rules and custom features specifications:
---
$AGENTS_RULES
---

The input from stdin is the content of the file '$FILE' containing git merge conflict markers (<<<<<<<, =======, >>>>>>>).
Please resolve all merge conflict markers in this file.
Maintain all custom features according to the specifications above.
Output ONLY the fully resolved file content code without any markdown formatting wrappers or explanation text.
EOF
