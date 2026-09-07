---
description: Switch plainly on or off, show whether it is on, or view and change the injected prompt — "prompt" shows it, "prompt set <text>" replaces it, "prompt reset" restores the default. No argument shows the state.
argument-hint: "[on|off|status|prompt|prompt set <text>|prompt reset]"
allowed-tools: Bash("${CLAUDE_PLUGIN_ROOT}/plainly-ctl.sh":*)
---

Plainly, for "$ARGUMENTS": !`"${CLAUDE_PLUGIN_ROOT}/plainly-ctl.sh" --data "${CLAUDE_PLUGIN_DATA}" --report-only --stdin-args <<'PLAINLY_ARGV_EOF'
$ARGUMENTS
PLAINLY_ARGV_EOF`

Decide how to present the result, based on "$ARGUMENTS":

- **"on", "off", "prompt set <text>", or "prompt reset"** — these change a file, and the shell output above is only an acknowledgement. Plainly's hook makes the change as this prompt is submitted and attaches its result to this prompt as additional context; that text begins with "plainly". Relay that result, not the acknowledgement: for "on" or "off" in one short line; for "prompt set" or "prompt reset" verbatim inside one fenced code block, unchanged, and add nothing else. If no such additional context was attached, say that plainly's hook did not run so nothing changed, and show the shell output above.
- **"prompt"** on its own — the output above is a header line naming which prompt is in force and its file, then the prompt text. Show all of it verbatim inside one fenced code block, unchanged, and add nothing else.
- **Anything else** (status or empty) — the output above is a one-line state summary. Relay it to the user in one short line.

If the script printed an error instead, show that. Do nothing else.
