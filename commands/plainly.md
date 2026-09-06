---
description: Switch plainly on or off, show whether it is on, or view and change the injected prompt — "prompt" shows it, "prompt set <text>" replaces it, "prompt reset" restores the default. No argument shows the state.
argument-hint: "[on|off|status|prompt|prompt set <text>|prompt reset]"
allowed-tools: Bash("${CLAUDE_PLUGIN_ROOT}/plainly-ctl.sh":*)
---

Plainly, after applying "$ARGUMENTS": !`"${CLAUDE_PLUGIN_ROOT}/plainly-ctl.sh" --data "${CLAUDE_PLUGIN_DATA}" --stdin-args <<'PLAINLY_ARGV_EOF'
$ARGUMENTS
PLAINLY_ARGV_EOF`

Decide how to present the script output above, based on "$ARGUMENTS":

- **Starts with "prompt"** — the output is a header line naming which prompt is in force and its file, then the prompt text. Show all of it verbatim inside one fenced code block, unchanged, and add nothing else.
- **Anything else** (on/off/status/empty) — the output is a one-line state summary. Relay it to the user in one short line.

If the script printed an error instead, show that. Do nothing else.
