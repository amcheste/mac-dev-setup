<div align="center">

# mac-dev-setup

**A fully automated macOS developer environment — from zero to productive in one command.**

[![Validate](https://github.com/amcheste/mac-dev-setup/actions/workflows/validate.yml/badge.svg)](https://github.com/amcheste/mac-dev-setup/actions/workflows/validate.yml)
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

---

Setting up a new Mac — or recovering from a disaster — should take minutes, not days.
This repo automates everything: Homebrew packages, GUI apps, dotfiles, Vim plugins, and credentials.
It's versioned, tested against a real macOS runner on every pull request, and designed to be run again and again without side effects.

```bash
git clone https://github.com/amcheste/mac-dev-setup ~/Repos/amcheste/mac-dev-setup
bash ~/Repos/amcheste/mac-dev-setup/setup.sh
```

> Installs Homebrew if missing, then handles everything else unattended.

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
| **GoLand / IntelliJ / PyCharm** | JetBrains IDEs |
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

## CI/CD

Every pull request runs a three-job pipeline on a **real macOS GitHub Actions runner**:

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

Releases are cut with a `v*.*.*` tag — the release pipeline runs validation as a gate, then publishes a GitHub Release automatically.

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

## iTerm2 Color Profile

Import `etc/Default.json` for the matching terminal color scheme:

> **iTerm2** → Preferences → Profiles → Other Actions → Import JSON Profiles

Pairs with **Meslo LG Nerd Font** (installed automatically by the Brewfile).

---

## License

MIT — do whatever you want with it.
