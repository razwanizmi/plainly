# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/) at `0.x`.

## [Unreleased]

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
