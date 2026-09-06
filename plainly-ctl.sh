#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# plainly-ctl.sh — the on/off switch behind /plainly.
#
# The hook checks one flag file on every prompt, so the switch takes effect on
# the next prompt without a restart:
#   ${CLAUDE_PLUGIN_DATA}/off   exists -> nothing injected
# CLAUDE_PLUGIN_DATA is the plugin's documented state directory. Claude Code
# exports it to hook processes, but NOT to the shell that runs a slash
# command's !` block (verified on 2.1.263: the command's shell had it unset
# while the hook had ~/.claude/plugins/data/plainly-inline). It does
# substitute the ${CLAUDE_PLUGIN_DATA} placeholder in the command file, so the
# command passes the directory in as `--data <dir>`, and this script prefers
# that over its own environment. Without either, the fallback is the same one
# prompt-inject.sh uses, so the two still agree. PLAINLY_OFF_FILE
# overrides everything (tests). The file PERSISTS across sessions until
# removed, so `status` says so.
#
# Usage: plainly-ctl.sh [--data <dir>] [--stdin-args | status|on|off]
#   status   (default) print "plainly: on" or "plainly: off"
#   on       remove the off-file
#   off      create the off-file
# Exits 1 if the file cannot be created or removed.
# ---------------------------------------------------------------------------
set -uo pipefail

# --data <dir>: the plugin data directory, substituted into the command file by
# Claude Code. Must come first. An empty value (placeholder not substituted)
# falls through to the environment and then the default.
if [ "${1:-}" = "--data" ]; then
  [ -n "${2:-}" ] && CLAUDE_PLUGIN_DATA="$2"
  shift 2 2>/dev/null || shift $#
fi
OFF_FILE="${PLAINLY_OFF_FILE:-${CLAUDE_PLUGIN_DATA:-${HOME:-/tmp}/.claude/plugins/data/plainly}/off}"

# Argument handling for the /plainly command. The command file runs this
# script as `plainly-ctl.sh --stdin-args` and feeds it $ARGUMENTS through a
# here-doc whose delimiter is quoted. With a quoted delimiter the shell treats
# the here-doc body as literal text, so whatever the user typed after /plainly
# arrives here unevaluated: no command substitution, no variable expansion, no
# operators. Putting "$ARGUMENTS" on the command line instead would not be
# safe, because Claude Code pastes the arguments into the command text before
# the shell parses it. This script reads that one line and splits it into
# words itself, with globbing off. Calls from a terminal pass ordinary
# positional arguments and skip this block.
if [ "${1:-}" = "--stdin-args" ]; then
  _argline=""
  IFS= read -r _argline || true
  set -f
  # shellcheck disable=SC2086
  set -- $_argline
  set +f
fi

fail() { printf 'plainly-ctl: %s\n' "$1" >&2; exit 1; }

case "${1:-status}" in
  status|"") ;;
  on)  rm -f "$OFF_FILE" 2>/dev/null || fail "cannot remove $OFF_FILE" ;;
  off) { mkdir -p "$(dirname "$OFF_FILE")" && : > "$OFF_FILE"; } 2>/dev/null || fail "cannot create $OFF_FILE" ;;
  *)   printf 'plainly-ctl: unknown command "%s" (use on|off|status)\n' "$1" >&2; exit 2 ;;
esac

if [ -f "$OFF_FILE" ]; then
  printf 'plainly: off (persists across sessions until /plainly on)\n'
else
  printf 'plainly: on\n'
fi
