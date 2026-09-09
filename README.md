# plainly

A Claude Code plugin that makes Claude write **every reply in plain language**.
One hook injects a short instruction into each prompt you send. The only settings are
an on/off switch and the instruction itself.

Why use a hook and not an output style or a `CLAUDE.md` rule? Claude reads
those once, at the start of the conversation. After a long session with lots of
tool output, it stops following them. This hook runs on every prompt. So the
instruction is always the last thing Claude has read.

The hook never gets in the way. If something goes wrong, it does nothing. Your
prompt reaches Claude just as you typed it.

## Requirements

- Claude Code.
- `bash` and `jq`. `jq` comes with macOS 15 and later. On older macOS, run
  `brew install jq`. On Linux, install it with your package manager.

## Install

Add this repository as a plugin marketplace. Then install the plugin from it:

```bash
claude plugin marketplace add https://github.com/razwanizmi/plainly
claude plugin install plainly@razwanizmi
```

The first command downloads the repository for you. Later, `claude plugin
update plainly` gets new versions, and `claude plugin uninstall plainly`
removes the plugin.

Want to try the plugin for one session without installing it? Clone or download
this repository and start Claude Code with the directory loaded. Replace
`PLUGIN_DIR` with the path to that directory. Nothing is left behind when the
session ends:

```bash
claude --plugin-dir PLUGIN_DIR
```

## Use

There is nothing to do. The instruction goes out with every prompt, in every
session.

To pause it, run `/plainly off` in Claude Code. To turn it back on, run
`/plainly on`. `/plainly` on its own shows whether it is on or off. The change
starts with your next prompt. You do not need to restart. The setting stays the
way you set it across sessions until you change it. Nothing on screen shows the
state, so run `/plainly` if you are not sure.

The switch is an empty file named `off` in the plugin's data directory. For
the install above, that is `~/.claude/plugins/data/plainly-razwanizmi/`.
Uninstalling the plugin deletes that directory, so nothing is left behind.

The hook makes the change, not the `/plainly` command itself. When Claude
Code's Bash sandbox is on, the shell behind a slash command cannot write
under `~/.claude`, but hooks run outside the sandbox. So `/plainly off`,
`/plainly on`, `/plainly prompt set`, and `/plainly prompt reset` are applied
by the hook as you send the command, and Claude relays the result. This works
with the sandbox on or off. It needs `jq`; without it the command tells you
so and shows a shell command you can run instead.

## The prompt

This is the instruction the hook injects by default:

```
This applies to the reply you write now, whatever earlier instructions said
about style. Write in plain language:

- Short sentences. About 20 words, one idea each. Split any sentence that has
  a semicolon, a dash aside, or a second clause with a new fact.
- Everyday words.
- No figurative language. No idioms, metaphors, or images. Say the literal
  thing.
- One qualifier per claim. Verdict, reason, caveat if there is one, then stop.
- Active voice with a clear actor. Past tense for history, present tense for
  the state today.
- Keep every fact, number, table, and verdict. Change how a finding is said,
  not what was found.
```

To use your own instruction instead, run `/plainly prompt set` followed by
the text. For example:

```
/plainly prompt set Reply in plain language and keep it under 100 words.
```

`/plainly prompt` shows the instruction in force and the file it comes from.
`/plainly prompt reset` goes back to the default. Your instruction is saved as
`prompt.md` in the plugin's data directory, next to the `off` file, so it
survives plugin updates. `/plainly prompt set` takes a single line. For a
longer instruction, open that file in an editor. It is read fresh on every
prompt, so edits apply at once.

## Layout

| File | Role |
|---|---|
| `prompt-inject.sh` | The hook. Runs on every prompt: applies `/plainly` changes, otherwise returns the instruction. |
| `prompt.md` | The default instruction. |
| `plainly-ctl.sh` | Manages the `off` file and your own `prompt.md`. The hook runs it to apply changes; `/plainly` runs it to show the state and the prompt. |
| `commands/plainly.md` | The `/plainly` command. |
| `hooks/hooks.json` | Registers the hook with Claude Code. |
| `.claude-plugin/plugin.json` | Plugin manifest. |
| `.claude-plugin/marketplace.json` | Lets `claude plugin marketplace add` install from this directory. |
