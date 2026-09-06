# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/) at `0.x`.

## [Unreleased]

## [0.1.0] - 2026-09-06

### Added

- A `UserPromptSubmit` hook that injects the plain-language instruction next
  to every prompt. It exists because an output style or a `CLAUDE.md` rule is
  read once at the top of the context and stops being followed after enough
  turns; a per-prompt injection always sits at the end.
- `/plainly on|off|status`, backed by a flag file the hook checks on
  every prompt, because env vars are frozen at session launch and cannot be
  flipped mid-session.
