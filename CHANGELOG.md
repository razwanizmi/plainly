# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/) at `0.x`.

## [Unreleased]

### Changed

- The default instruction is a new rule list: extreme brevity, everyday
  words, active voice, short sentences, no figurative language, and no
  chained hedges. It no longer states that every fact, number, table, and
  verdict is kept, and it no longer sets tense rules. It is 515 characters,
  down from 626.

## [0.3.1] - 2026-09-08

### Changed

- The default instruction is shorter, 626 characters instead of 858. It
  drops three phrases that repeated other rules and folds the "no fact,
  number, table, or verdict is dropped" sentence into the rule list. The
  rules themselves are unchanged.

## [0.3.0] - 2026-09-07

### Changed

- The default instruction is now a short rule list: short sentences,
  everyday words, no figurative language, one qualifier per claim, active
  voice. It states that plain language changes how a finding is said, not
  what was found, so no fact, number, table, or verdict is dropped.

## [0.2.1] - 2026-09-07

### Fixed

- `/plainly on`, `/plainly off`, `/plainly prompt set`, and `/plainly prompt
  reset` failed with `cannot create .../off` when Claude Code's Bash sandbox
  was on. The sandbox runs a slash command's shell block inside the sandbox
  and denies writes under `~/.claude`, which no `allowWrite` entry can lift.
  The hook, which runs outside the sandbox, now applies these commands as
  the prompt is submitted and reports the result; the command's shell block
  only answers read-only requests. `plainly-ctl.sh` also reports the
  operating system's reason when a file cannot be written.

## [0.2.0] - 2026-09-06

### Added

- `/plainly prompt`, `/plainly prompt set <text>`, and `/plainly prompt reset`.
  The hook now prefers a `prompt.md` in the plugin's data directory over the
  bundled one, because the plugin directory is replaced on every update and
  an edit there would be lost.

## [0.1.0] - 2026-09-06

### Added

- A `UserPromptSubmit` hook that injects the plain-language instruction next
  to every prompt. It exists because an output style or a `CLAUDE.md` rule is
  read once at the top of the context and stops being followed after enough
  turns; a per-prompt injection always sits at the end.
- `/plainly on|off|status`, backed by a flag file the hook checks on
  every prompt, because env vars are frozen at session launch and cannot be
  flipped mid-session.
