# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-05-12

### Added
- Brand banner under `assets/` (svg + 1200/2400 png) per [`banner-spec.md`](https://github.com/amcheste/alanchester-brand/blob/main/docs/banner-spec.md). Hero shows a terminal trace of the setup script resolving to **→ productive** in Hunter Green (the δ output). README replaces the mascot logo with the banner; `assets/logo.png` preserved for potential reuse.
- `/publish-release` skill: Step 5 ensures `main` is the GitHub default branch after the release ceremony. Idempotent — only fires on the first release.
- `/setup-repo` skill: Step 2 now respects release state when setting the GitHub default branch (`develop` for repos with no releases yet, `main` kept for repos with releases). Reflects the integration-trunk vs GitHub-default-branch distinction documented in engineering-handbook v0.2.0.
- `zshrc`: export `CLAUDE_GH_APP_ID` and `CLAUDE_GH_APP_PRIVATE_KEY_PATH` so the Epsilon agent token-mint script picks them up from non-interactive shells (#74).

### Changed
- Release Drafter workflow bumped to v7.3.0. Dropped the `pull_request` trigger — v7 was failing CI on PR events because `GITHUB_REF` is `refs/pull/N/merge`, which the Releases API rejects as `target_commitish`.
- `/setup-repo` skill: disables squash merge by default to protect commit ancestry, refuses forks in pre-flight, and is in sync with engineering-handbook conventions.
- README badges aligned to brand colors (License in Hunter Green `#1F4D3A`, Version in Ink `#0B0B0C`).
- Workflow validation: added `actionlint` to catch YAML parse errors early (#66).

### Fixed
- CI false failures on develop pushes (#65).

### Dependencies
- Dependabot bumps: `github/codeql-action` (3.35.1 → 4.35.4), `actions/labeler` (6.0.1 → 6.1.0), `softprops/action-gh-release` (2.6.1 → 3.0.0), `actions/upload-artifact` (7.0.0 → 7.0.1).

## [1.0.0] - 2026-04-02

## [0.1.0-beta.1] - 2026-03-29

## [0.1.0-beta.1] - 2026-03-29

## [0.1.0-beta.1] - 2026-03-29

## [0.1.0-beta.1] - 2026-03-29

## [0.1.0-beta.1] - 2026-03-29

## [1.0.0] - 2026-03-29

### Added
- Bootstrap script (`setup.sh`). Zero-to-productive on a fresh Mac in one command
- Homebrew tap with `dev-tools` formula (`Formula/dev-tools.rb`)
- `Brewfile`. Full package list: CLI tools, languages, cloud/devops, GUI casks
- `Brewfile.ci`. CLI-only subset for fast CI runs
- Dotfiles: `zshrc`, `vimrc` (vim-plug + ALE + vim-go + gruvbox), `secrets.template`
- Scripts: `install-dotfiles.sh`, `setup-credentials.sh`, `setup-mcps.sh`, `upgrade.sh`
- `CLAUDE.md`. Claude Code preferences and learned preferences system
- CI/CD: lint (`shellcheck`), formula audit (`brew audit --strict`), integration test (macOS runner)
- Release pipeline with validation gate on `v*.*.*` tags
