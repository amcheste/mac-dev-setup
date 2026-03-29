<div align="center">

# mac-dev-setup

**An agentic-forward macOS developer environment — from zero to productive in one command.**

[![Validate](https://github.com/amcheste/mac-dev-setup/actions/workflows/validate.yml/badge.svg)](https://github.com/amcheste/mac-dev-setup/actions/workflows/validate.yml)
[![Version](https://img.shields.io/github/v/tag/amcheste/mac-dev-setup?label=version&sort=semver)](https://github.com/amcheste/mac-dev-setup/releases)
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/amcheste/mac-dev-setup/badge)](https://scorecard.dev/viewer/?uri=github.com/amcheste/mac-dev-setup)

</div>

---

Setting up a new Mac — or recovering from a disaster — should take minutes, not days.
This repo automates everything: Homebrew packages, GUI apps, dotfiles, Vim plugins, credentials, and a fully configured [Claude Code](https://claude.ai/claude-code) environment with MCP servers wired in from day one.

```bash
git clone https://github.com/amcheste/mac-dev-setup ~/Repos/amcheste/mac-dev-setup
bash ~/Repos/amcheste/mac-dev-setup/setup.sh
```

> Installs Homebrew if missing, then handles everything else unattended.

---

## Agentic Development — Built In

This isn't just a tool installer. It sets up **Claude Code** as a first-class part of the development workflow — configured to know how you work, what you build, and how you prefer to do it.

### Claude Code Configuration

A `CLAUDE.md` file in this repo captures your development preferences so Claude Code understands your environment from the first session on any machine:

- **Tooling** — Vim, Zsh, Go/Python/Java/Node, OCI + DigitalOcean, Kubernetes via `kind`
- **Git workflow** — always branch, always PR, conventional commits, descriptive messages
- **Shell standards** — `shellcheck`-clean scripts, `set -euo pipefail`, idempotent installs
- **Project conventions** — how to test with `act`, when to update `Brewfile.ci`, how to add tools

### Learned Preferences — A Model That Grows With You

The `CLAUDE.md` has a **Learned Preferences** section that acts as a living record of how you work.
As Claude Code works with you across sessions and notices consistent patterns — how you structure commits, which shortcuts you reach for, what output format you prefer — those observations get added back here and committed. Not session-specific questions, but durable preferences that should be true on every clean install.

Over time, this file becomes a precise picture of your development style. New machine, new team member, new context — Claude Code picks it all up instantly.

### MCP Servers — Claude Wired Into Your Stack

`setup.sh` automatically configures [MCP servers](https://modelcontextprotocol.io) so Claude Code has direct access to your development infrastructure:

| MCP | What Claude Can Do |
|-----|--------------------|
| **GitHub** | Read/write PRs, issues, Actions runs, code search, releases |
| **Filesystem** | Navigate `~/Repos`, `~/Documents`, `~/.claude` beyond the active project |
| **Memory** | Persist facts across sessions — supplements `CLAUDE.md` with dynamic context |
| **PostgreSQL** | Query local and dev databases directly in conversation |

To reconfigure MCPs: `bash scripts/setup-mcps.sh`

---

## What Gets Installed

### Languages & Runtimes

| Tool | Version Management |
|------|--------------------|
| Go | Direct via Homebrew |
| Python | `pyenv` — switch versions per project |
| Node.js | `nvm` — switch versions per project |
| Java | OpenJDK + Maven |

### Cloud & Infrastructure

| Tool | Purpose |
|------|---------|
| `kubectl` + `kind` | Kubernetes — local clusters and remote |
| `helm` | Kubernetes package manager |
| `terraform` | Infrastructure as code |
| `oci-cli` | Oracle Cloud Platform |
| `doctl` | DigitalOcean CLI |
| `gh` | GitHub CLI — PRs, releases, Actions |

### Developer Utilities

| Tool | Why It's Here |
|------|--------------|
| `fzf` | Fuzzy finder — wired into shell history and Vim |
| `ripgrep` | 10x faster than grep, respects `.gitignore` |
| `fd` | Faster `find` with sane defaults |
| `bat` | `cat` with syntax highlighting and line numbers |
| `tmux` | Terminal multiplexer |
| `jq` | JSON slicing and dicing in the shell |
| `mongosh` | MongoDB shell |

### GUI Apps (via Homebrew Cask)

| App | Purpose |
|-----|---------|
| **iTerm2** | Terminal (with custom color profile) |
| **Cursor** | AI-powered editor |
| **Docker Desktop** | Container runtime |
| **MongoDB Compass** | Database GUI |
| **Meslo LG Nerd Font** | Powerline-compatible font for terminal |

---

## Dotfiles

Shell and editor configs live in `dotfiles/` and are **symlinked** into `$HOME` — edits in this repo take effect immediately, and `git diff` always shows what's changed.

```
dotfiles/
├── zshrc            → ~/.zshrc    (PATH, pyenv, nvm, aliases, secrets loader)
├── vimrc            → ~/.vimrc    (vim-plug, gruvbox, ALE, vim-go, fzf)
└── secrets.template              (copied to ~/.secrets on first run)
```

### Vim Setup

The `vimrc` turns Vim into a proper IDE without an IDE's weight:

- **[vim-plug](https://github.com/junegunn/vim-plug)** — plugin manager, auto-bootstrapped
- **[ALE](https://github.com/dense-analysis/ale)** — async lint and fix on save (`goimports`, `black`, `tflint`)
- **[vim-go](https://github.com/fatih/vim-go)** — Go development (goimports, highlighting, `:GoBuild`)
- **[fzf.vim](https://github.com/junegunn/fzf.vim)** — fuzzy file/buffer/grep search (`<leader>f`, `<leader>r`)
- **[gruvbox](https://github.com/morhetz/gruvbox)** — colorscheme
- **[NERDTree](https://github.com/preservim/nerdtree)**, **[lightline](https://github.com/itchyny/lightline.vim)**, **[vim-fugitive](https://github.com/tpope/vim-fugitive)**
- Filetype-aware indent: real tabs for Go, 2-space for YAML/Terraform/JSON, PEP8 for Python

---

## Secrets Management

Credentials live in `~/.secrets` — `chmod 600`, sourced by `.zshrc`, and **never committed**.

On first run, `setup.sh` launches an interactive wizard that populates it:

```
── Anthropic ──────────────────────────────────
  API Key (sk-ant-...): ████████████████████

── Oracle Cloud (OCI) ─────────────────────────
  Registry Token: ████████
  Region (e.g. iad): iad
  Tenancy Namespace: ████████

── DigitalOcean ───────────────────────────────
  Personal Access Token (dop_...): ████████████

── Databases ──────────────────────────────────
  Default DB Password: ████████
```

To re-run at any time: `bash scripts/setup-credentials.sh`

A `dotfiles/secrets.template` (safe to commit) documents every slot.

---

## Homebrew Tap

This repo is structured as a [Homebrew tap](https://docs.brew.sh/Taps), meaning the formula can be installed directly:

```bash
brew tap amcheste/mac-dev-setup https://github.com/amcheste/mac-dev-setup
brew install --HEAD amcheste/mac-dev-setup/dev-tools
```

Or use `brew bundle` to install just the packages without the formula:

```bash
brew bundle --file=~/Repos/amcheste/mac-dev-setup/Brewfile
```

---

## Upgrading an Existing Install

One command pulls changes, updates packages, refreshes dotfile symlinks, and updates Vim plugins:

```bash
bash ~/Repos/amcheste/mac-dev-setup/scripts/upgrade.sh
```

---

## CI/CD Pipeline

Five automated workflows keep the environment reliable across every change and release.

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Validate** | Every PR + push to `main` | Lint, shellcheck, formula audit, macOS integration test, commit lint + semver suggestion |
| **VM Acceptance** | Release tags + manual | Full install in a clean Tart VM — the release gate |
| **Release** | `v*.*.*` tags | Validate → acceptance → publish release |
| **Release Drafter** | PR open/update + push to `main` | Auto-labels PRs by type, drafts release notes |
| **Label PR** | PR open/update | Adds content labels (`brew`, `scripts`, `dotfiles`, `ci`) |
| **Dependency Update** | Weekly (Monday) | Checks Brewfile packages for updates, opens issue if stale |
| **Stale** | Daily | Closes inactive issues and PRs after 30 + 7 days |
| **OpenSSF Scorecard** | Weekly + push to `main` | Security posture scoring and SARIF upload |

### Validate pipeline (every PR)

```
┌─────────────────┐     ┌──────────────────┐
│   Lint (Linux)  │     │  Formula Audit   │
│                 │     │    (macOS)       │
│ • shellcheck    │     │                  │
│ • secret scan   │     │ • brew audit     │
│ • .gitignore    │     │ • brew style     │
└────────┬────────┘     └────────┬─────────┘
         │                       │
         └──────────┬────────────┘
                    ▼
         ┌──────────────────────┐
         │  Integration Test    │
         │      (macOS)         │
         │                      │
         │ • brew bundle        │
         │ • install-dotfiles   │
         │ • assert symlinks    │
         │ • assert chmod 600   │
         │ • smoke-test tools   │
         └──────────────────────┘
```

### Release gate

Before any release is published, a clean macOS VM is spun up via [Tart](https://github.com/cirruslabs/tart), `setup.sh` runs from scratch, and the full acceptance test suite must pass. The release is blocked if anything fails.

```
tag push → validate → VM acceptance → draft release notes → publish release
```

---

## Repo Structure

```
mac-dev-setup/
├── .github/
│   └── workflows/
│       ├── validate.yml       # CI on every PR
│       └── release.yml        # Release on v*.*.* tags
├── Formula/
│   └── dev-tools.rb           # Homebrew formula
├── dotfiles/
│   ├── zshrc                  # Shell configuration
│   ├── vimrc                  # Vim configuration
│   └── secrets.template       # Credential slots (safe to commit)
├── scripts/
│   ├── install-dotfiles.sh    # Symlinks dotfiles, bootstraps vim-plug
│   ├── setup-credentials.sh   # Interactive credential wizard
│   └── upgrade.sh             # Update packages + dotfiles
├── etc/
│   └── Default.json           # iTerm2 color profile
├── Brewfile                   # Full package list (brew bundle)
├── Brewfile.ci                # CLI-only subset for fast CI runs
└── setup.sh                   # Bootstrap entry point
```

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/). Versions under `0.x.x` are pre-stable; `1.0.0`+ signals a proven, mainstream-ready release. Pre-release tags (e.g. `-beta.1`, `-rc.1`) are published to GitHub with the Pre-release flag and do not show as the latest version.

```bash
# Stable increments
./scripts/bump-version.sh patch              # 1.0.0 → 1.0.1
./scripts/bump-version.sh minor              # 1.0.0 → 1.1.0
./scripts/bump-version.sh major              # 1.0.0 → 2.0.0

# Explicit version (including pre-release)
./scripts/bump-version.sh set 0.1.0-beta.1
./scripts/bump-version.sh set 1.0.0-rc.1
```

Push with `git push && git push --tags` to trigger the release pipeline. See **[VERSIONING.md](VERSIONING.md)** for the full scheme.

---

## Testing

CI runs on every pull request against a real macOS runner. For full acceptance testing — including GUI casks and the interactive setup flow — see **[TESTING.md](TESTING.md)** for five options ranging from a local macOS user account to a UTM virtual machine.

| Method | Covers Casks | Clean State | Effort |
|--------|-------------|-------------|--------|
| CI/CD (automatic) | ✗ | ✓ | None |
| `act` (local) | ✗ | ✗ | Low |
| New macOS user | ✓ | ✓ | Low |
| Manual Actions run | ✓ | ✓ | Medium |
| UTM VM | ✓ | ✓ (snapshots) | High |

---

## iTerm2 Color Profile

Import `etc/Default.json` for the matching terminal color scheme:

> **iTerm2** → Preferences → Profiles → Other Actions → Import JSON Profiles

Pairs with **Meslo LG Nerd Font** (installed automatically by the Brewfile).

---

## Contributing

This is Alan Chester's personal development environment. It is open for others to **fork and adapt** for their own use — that is the primary use case for anyone other than the owner.

Bug fixes and improvements that are genuinely broadly useful are welcome as pull requests. Preference-based changes will generally be declined — if the defaults don't fit your workflow, fork it and make it yours.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full contribution guide, development workflow, and release process.

---

## License

Released under the [MIT License](LICENSE).

You are free to use, fork, modify, and distribute this project for any purpose. No warranty is provided — this is a personal environment, not a supported product.
