---
description: Switch plainly on or off, or show whether it is on. No argument shows the state.
argument-hint: "[on|off|status]"
allowed-tools: Bash("${CLAUDE_PLUGIN_ROOT}/plainly-ctl.sh":*)
---

Plainly, after applying "$ARGUMENTS": !`"${CLAUDE_PLUGIN_ROOT}/plainly-ctl.sh" --data "${CLAUDE_PLUGIN_DATA}" --stdin-args <<'PLAINLY_ARGV_EOF'
$ARGUMENTS
PLAINLY_ARGV_EOF`

The output above is a one-line state summary. Relay it to the user in one short line. If the script printed an error instead, show that. Do nothing else.
