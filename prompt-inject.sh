#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# prompt-inject.sh — UserPromptSubmit hook. The whole of plainly.
#
# Claude Code fires UserPromptSubmit on every prompt, before the model sees
# it. This hook returns a plain-language instruction as additionalContext,
# which Claude Code injects as a system reminder next to the prompt. Because
# it is re-injected on EVERY turn it always sits at the end of the context,
# where an output style or a CLAUDE.md rule does not: those are read once at
# the top and fade behind fifty turns of tool output. Nothing is rewritten:
# Claude writes the reply itself in plain language.
#
# The instruction is read from a file, never hard-coded here:
#   ${CLAUDE_PLUGIN_DATA}/prompt.md   the user's own prompt, written by
#                                     /plainly prompt set; wins when it exists
#                                     and is not blank
#   <plugin dir>/prompt.md            the bundled default
# The user's copy lives in the data directory, not next to this script,
# because the plugin directory is replaced on every update and an edit there
# would be lost. The default's leading clause asserts precedence over style
# rules higher in the context (an output style, a CLAUDE.md), which is the
# case this plugin exists for; the price is that it also outranks a format
# the user or a skill asked for on an earlier turn. If neither file has any
# text, nothing is injected.
#
# The only switch is /plainly on|off (plainly-ctl.sh), which
# creates or removes a flag file this hook checks on every prompt. A flag
# file rather than an env var because env is frozen at session launch and
# cannot be flipped mid-session. It persists across sessions until
# /plainly on removes it.
#
# The file is ${CLAUDE_PLUGIN_DATA}/off: Claude Code exports that variable to
# every hook process, and the directory is the documented home for plugin
# state — it survives plugin updates and is removed on uninstall, so a
# switched-off plugin leaves nothing behind. The slash command's shell does
# not get the variable, so the command file passes the substituted
# placeholder to plainly-ctl.sh explicitly; see there. Without the
# variable (an older Claude Code) the fallback is
# ~/.claude/plugins/data/plainly/off, and both scripts share it.
#   PLAINLY_OFF_FILE <path>   overrides the path (tests point it at
#                                  /nonexistent so a real switch cannot leak in)
#
# FAIL-OPEN CONTRACT: on ANY problem emit nothing and exit 0 — the prompt then
# reaches Claude exactly as typed. This hook never blocks a prompt. It must
# also be fast: UserPromptSubmit stalls the session until it returns.
# ---------------------------------------------------------------------------
set -uo pipefail

[ -f "${PLAINLY_OFF_FILE:-${CLAUDE_PLUGIN_DATA:-${HOME:-/tmp}/.claude/plugins/data/plainly}/off}" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
[ -n "$payload" ] || exit 0
printf '%s' "$payload" | jq -e . >/dev/null 2>&1 || exit 0

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME:-/tmp}/.claude/plugins/data/plainly}"
PROMPT_FILE="$DATA_DIR/prompt.md"
# A blank user prompt counts as absent, so a stray empty file cannot silence
# the plugin; /plainly prompt reset removes it outright.
if ! [ -r "$PROMPT_FILE" ] || ! grep -q '[^[:space:]]' "$PROMPT_FILE" 2>/dev/null; then
  PROMPT_FILE="$(cd "$(dirname "$0")" && pwd)/prompt.md"
fi
[ -r "$PROMPT_FILE" ] || exit 0

# --rawfile hands jq the file as one string, so no shell quoting can mangle it.
# Trailing whitespace is trimmed; an empty file yields nothing.
jq -n --rawfile c "$PROMPT_FILE" '
  ($c | sub("\\s+$"; "")) as $p
  | select($p != "")
  | {hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$p}}
' 2>/dev/null
exit 0
