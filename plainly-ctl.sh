#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# plainly-ctl.sh — the on/off switch and prompt editor behind /plainly.
#
# Everything here is a file in the plugin's data directory, which the hook
# re-reads on every prompt, so changes take effect on the next prompt without
# a restart:
#   ${CLAUDE_PLUGIN_DATA}/off         exists -> nothing injected
#   ${CLAUDE_PLUGIN_DATA}/prompt.md   the user's prompt, replacing the bundled
#                                     default while it exists and is not blank
# CLAUDE_PLUGIN_DATA is the plugin's documented state directory. Claude Code
# exports it to hook processes, but NOT to the shell that runs a slash
# command's !` block (verified on 2.1.263). It does substitute the
# ${CLAUDE_PLUGIN_DATA} placeholder in the command file, so the command
# passes the directory in as `--data <dir>`, and this script prefers that
# over its own environment. Without either, the fallback is the same one
# prompt-inject.sh uses, so the two still agree. PLAINLY_OFF_FILE overrides
# the off-file path (tests). Both files PERSIST across sessions until removed.
#
# Two callers, because of the Bash sandbox. With sandboxing on, Claude Code
# runs a slash command's !` block INSIDE the sandbox, which denies every
# write under ~/.claude and cannot be told otherwise (verified on 2.1.263).
# So the writes are made by the hook, prompt-inject.sh, which runs outside
# the sandbox: it recognises "/plainly on|off|prompt set|prompt reset" in the
# prompt and runs this script. The command's !` block runs this script with
# --report-only, which answers the read-only commands (reads are allowed)
# and, for the others, prints an acknowledgement instead of writing. It
# cannot report the result because it runs BEFORE the hook.
#
# Usage: plainly-ctl.sh [--data <dir>] [--report-only] [--stdin-args | <command>]
#   status              (default) print "plainly: on" or "plainly: off"
#   on                  remove the off-file
#   off                 create the off-file
#   prompt              print the prompt in force, and which file it came from
#   prompt set <text>   write <text> as the user's prompt (one line; for a
#                       longer prompt, edit the file `prompt` names)
#   prompt reset        remove the user's prompt -> bundled default
# Exits 1 if a file cannot be created or removed, 2 on a bad command.
# ---------------------------------------------------------------------------
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

# --data <dir>: the plugin data directory, substituted into the command file by
# Claude Code. Must come first. An empty value (placeholder not substituted)
# falls through to the environment and then the default.
if [ "${1:-}" = "--data" ]; then
  [ -n "${2:-}" ] && CLAUDE_PLUGIN_DATA="$2"
  shift 2 2>/dev/null || shift $#
fi
# --report-only: answer read-only commands, acknowledge the rest, write nothing.
REPORT_ONLY=0
if [ "${1:-}" = "--report-only" ]; then REPORT_ONLY=1; shift; fi

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME:-/tmp}/.claude/plugins/data/plainly}"
OFF_FILE="${PLAINLY_OFF_FILE:-$DATA_DIR/off}"
USER_PROMPT="$DATA_DIR/prompt.md"
DEFAULT_PROMPT="$SELF_DIR/prompt.md"

# Argument handling for the /plainly command. The command file runs this
# script as `plainly-ctl.sh --stdin-args` and feeds it $ARGUMENTS through a
# here-doc whose delimiter is quoted. With a quoted delimiter the shell treats
# the here-doc body as literal text, so whatever the user typed after /plainly
# arrives here unevaluated: no command substitution, no variable expansion, no
# operators. Putting "$ARGUMENTS" on the command line instead would not be
# safe, because Claude Code pastes the arguments into the command text before
# the shell parses it. This script reads that one line and splits it into
# words itself, with globbing off. The raw line is kept too: `prompt set`
# takes the rest of it verbatim, spacing included. The hook uses the same
# path, feeding it the line it took from the prompt. Calls from a terminal
# pass ordinary positional arguments and skip this block.
_argline=""
if [ "${1:-}" = "--stdin-args" ]; then
  IFS= read -r _argline || true
  set -f
  # shellcheck disable=SC2086
  set -- $_argline
  set +f
fi

# fail <message> [<captured stderr>]. The shell's message repeats the path and
# bash adds "<script>: line N: ", so only the reason after the last ": " is
# kept: "Permission denied", "Operation not permitted", "Is a directory".
fail() {
  _why="${2:-}"; _why="${_why##*: }"
  printf 'plainly-ctl: %s%s\n' "$1" "${_why:+: $_why}" >&2; exit 1
}

# --report-only acknowledgement for a command that writes. The hook makes the
# change on this same prompt, unless jq is missing, in which case the hook
# does nothing at all and the user needs to know.
ack() {
  if command -v jq >/dev/null 2>&1; then
    printf 'plainly: "%s" requested. The hook applies it as this prompt is submitted and reports the result in the additional context.\n' "$1"
  else
    printf 'plainly: "%s" requested, but jq is not installed, so the hook cannot apply it. Install jq, or run from a terminal:\n  %s --data %s %s\n' \
      "$1" "$SELF_DIR/plainly-ctl.sh" "$DATA_DIR" "$1"
  fi
  exit 0
}

# The text after "prompt set": from the raw line when it came through
# --stdin-args, otherwise the remaining positional arguments joined by spaces.
prompt_text() {
  if [ -n "$_argline" ]; then
    _t="${_argline#*prompt}"; _t="${_t#"${_t%%[![:space:]]*}"}"
    _t="${_t#set}";           _t="${_t#"${_t%%[![:space:]]*}"}"
    printf '%s' "$_t"
  else
    shift 2; printf '%s' "$*"
  fi
}

show_prompt() {
  if [ -r "$USER_PROMPT" ] && grep -q '[^[:space:]]' "$USER_PROMPT" 2>/dev/null; then
    printf 'plainly prompt: your own, from %s\n\n' "$USER_PROMPT"; cat "$USER_PROMPT"
  elif [ -r "$DEFAULT_PROMPT" ]; then
    printf 'plainly prompt: the default, from %s\n' "$DEFAULT_PROMPT"
    printf '(to change it: /plainly prompt set <text>, or write %s)\n\n' "$USER_PROMPT"; cat "$DEFAULT_PROMPT"
  else
    printf 'plainly prompt: none — %s is missing, nothing is injected\n' "$DEFAULT_PROMPT"
  fi
}

# Failures keep the operating system's own message ("Permission denied",
# "Operation not permitted", ...) so the cause is visible, not just the path.
case "${1:-status}" in
  status|"") ;;
  on)
    [ "$REPORT_ONLY" = 1 ] && ack on
    err="$(rm -f "$OFF_FILE" 2>&1)" || fail "cannot remove $OFF_FILE" "$err" ;;
  off)
    [ "$REPORT_ONLY" = 1 ] && ack off
    err="$({ mkdir -p "$(dirname "$OFF_FILE")" && : > "$OFF_FILE"; } 2>&1)" || fail "cannot create $OFF_FILE" "$err" ;;
  prompt)
    case "${2:-}" in
      "")    show_prompt; exit 0 ;;
      set)
        text="$(prompt_text "$@")"
        [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || fail 'usage: prompt set <text> (or "prompt reset" for the default)'
        [ "$REPORT_ONLY" = 1 ] && ack "prompt set"
        err="$({ mkdir -p "$DATA_DIR" && printf '%s\n' "$text" > "$USER_PROMPT"; } 2>&1)" || fail "cannot write $USER_PROMPT" "$err"
        show_prompt; exit 0 ;;
      reset)
        [ "$REPORT_ONLY" = 1 ] && ack "prompt reset"
        err="$(rm -f "$USER_PROMPT" 2>&1)" || fail "cannot remove $USER_PROMPT" "$err"
        show_prompt; exit 0 ;;
      *)     printf 'plainly-ctl: unknown prompt command "%s" (use prompt|prompt set <text>|prompt reset)\n' "$2" >&2; exit 2 ;;
    esac ;;
  *)   printf 'plainly-ctl: unknown command "%s" (use on|off|status|prompt|prompt set <text>|prompt reset)\n' "$1" >&2; exit 2 ;;
esac

if [ -f "$OFF_FILE" ]; then
  printf 'plainly: off (persists across sessions until /plainly on)\n'
else
  printf 'plainly: on\n'
fi
