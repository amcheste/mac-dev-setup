# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0-beta.1] - 2026-03-29

## [1.0.0] - 2026-03-29

### Added
- Bootstrap script (`setup.sh`) — zero-to-productive on a fresh Mac in one command
- Homebrew tap with `dev-tools` formula (`Formula/dev-tools.rb`)
- `Brewfile` — full package list: CLI tools, languages, cloud/devops, GUI casks
- `Brewfile.ci` — CLI-only subset for fast CI runs
- Dotfiles: `zshrc`, `vimrc` (vim-plug + ALE + vim-go + gruvbox), `secrets.template`
- Scripts: `install-dotfiles.sh`, `setup-credentials.sh`, `setup-mcps.sh`, `upgrade.sh`
- `CLAUDE.md` — Claude Code preferences and learned preferences system
- CI/CD: lint (`shellcheck`), formula audit (`brew audit --strict`), integration test (macOS runner)
- Release pipeline with validation gate on `v*.*.*` tags
