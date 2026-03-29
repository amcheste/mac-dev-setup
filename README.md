# dev_env

[![Validate](https://github.com/amcheste/dev_env/actions/workflows/validate.yml/badge.svg)](https://github.com/amcheste/dev_env/actions/workflows/validate.yml)

Personal developer environment for macOS — managed as a Homebrew tap.

One command installs all CLI tools, GUI apps, dotfiles, and prompts for credentials.

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/amcheste/dev_env ~/Repos/amcheste/dev_env
cd ~/Repos/amcheste/dev_env

# 2. Run setup (installs Homebrew if needed, then everything else)
bash setup.sh
```

That's it. Setup will:
- Install [Homebrew](https://brew.sh) if not already present
- Tap this repo (`amcheste/dev-env`)
- Install all packages from `Brewfile` (CLI tools + GUI apps)
- Symlink `~/.zshrc` and `~/.vimrc` from `dotfiles/`
- Install [vim-plug](https://github.com/junegunn/vim-plug) and all Vim plugins
- Run the credential wizard to populate `~/.secrets`

---

## Homebrew Tap

Once the tap is added you can also install the formula directly:

```bash
brew tap amcheste/dev-env https://github.com/amcheste/dev_env
brew install --HEAD amcheste/dev-env/dev-tools
```

Or install individual packages from the `Brewfile`:

```bash
brew bundle --file=~/Repos/amcheste/dev_env/Brewfile
```

---

## What's Installed

### CLI Tools
| Tool | Purpose |
|------|---------|
| `git`, `gh` | Version control + GitHub CLI |
| `vim`, `fzf`, `ripgrep`, `fd`, `bat` | Editor + search utilities |
| `tmux` | Terminal multiplexer |
| `jq` | JSON processor |
| `wget`, `tree` | Misc utilities |

### Languages
| Tool | Purpose |
|------|---------|
| `go` | Go language |
| `pyenv` | Python version manager |
| `nvm` | Node version manager |
| `openjdk`, `maven` | Java + build tool |

### Cloud & DevOps
| Tool | Purpose |
|------|---------|
| `kubectl` | Kubernetes CLI |
| `kind` | Local k8s clusters |
| `helm` | Kubernetes package manager |
| `terraform` | Infrastructure as code |
| `oci-cli` | Oracle Cloud CLI |
| `doctl` | DigitalOcean CLI |

### Databases
| Tool | Purpose |
|------|---------|
| `mongosh` | MongoDB shell |

### GUI Apps (Casks)
- **iTerm2** — terminal
- **Cursor** — AI-powered editor
- **Docker Desktop** — containers
- **GoLand**, **IntelliJ IDEA**, **PyCharm** — JetBrains IDEs
- **MongoDB Compass** — database GUI
- **Meslo LG Nerd Font** — powerline-compatible font

---

## Dotfiles

Dotfiles live in `dotfiles/` and are symlinked into `$HOME` by `scripts/install-dotfiles.sh`.

| File | Destination | Notes |
|------|-------------|-------|
| `dotfiles/zshrc` | `~/.zshrc` | Shell config, aliases, PATH setup |
| `dotfiles/vimrc` | `~/.vimrc` | Full Vim config with plugins |
| `dotfiles/secrets.template` | `~/.secrets` | Credential template (on first install) |

To re-install dotfiles only:
```bash
bash scripts/install-dotfiles.sh
```

---

## Credentials

Secrets live in `~/.secrets` (chmod 600, never committed).

To re-run the credential wizard:
```bash
bash scripts/setup-credentials.sh
```

The wizard configures:
- `ANTHROPIC_API_KEY` — for Claude Code
- `OCIR_TOKEN`, `OCIR_REGION`, `OCIR_NAMESPACE` — Oracle Cloud Registry
- `DIGITAL_OCEAN_TOKEN` — DigitalOcean / doctl
- `DB_PASSWORD` — default database password

---

## Upgrading

Run the upgrade script to pull the latest changes, update all packages, and refresh dotfiles:

```bash
cd ~/Repos/amcheste/dev_env
bash scripts/upgrade.sh
```

This does: `git pull` → `brew bundle` (new packages) → `brew upgrade` (existing packages) → re-link dotfiles → `vim +PlugUpdate`.

---

## CI/CD

Every pull request and push to `main` runs the validation pipeline:

| Check | What it does |
|-------|-------------|
| **Shell lint** | `shellcheck` on all `.sh` scripts |
| **Formula audit** | `brew audit --strict` + `brew style` on the formula |
| **Secret safety** | Scans `secrets.template` for real credential patterns |
| **Integration test** | Real macOS runner — installs from `Brewfile.ci`, runs `install-dotfiles.sh`, asserts symlinks + permissions |
| **Tool smoke test** | Verifies `go`, `kubectl`, `helm`, `terraform`, `doctl`, `jq`, `gh` are on PATH |

Releases are cut by pushing a `v*.*.*` tag — the release pipeline runs full validation as a gate before creating the GitHub Release.

---

## Manual Steps

A few things can't be automated:
- **OCI CLI config** — run `oci setup config` after install
- **Vim plugins** — run `vim +PlugInstall +qall` on first open (setup.sh does this automatically)
- **gh auth** — `gh auth login` (setup-credentials.sh handles this)

---

## Repo Structure

```
dev_env/
├── Formula/
│   └── dev-tools.rb          # Homebrew formula
├── dotfiles/
│   ├── zshrc                 # Shell config
│   ├── vimrc                 # Vim config
│   └── secrets.template      # Credential template
├── scripts/
│   ├── install-dotfiles.sh   # Symlinks dotfiles into $HOME
│   └── setup-credentials.sh  # Interactive credential wizard
├── etc/
│   └── Default.json          # iTerm2 color profile
├── Brewfile                  # All packages (brew bundle)
├── setup.sh                  # Bootstrap entry point
└── README.md
```

---

## iTerm2 Color Profile

Import `etc/Default.json` in iTerm2:
> Preferences → Profiles → Other Actions → Import JSON Profiles

Uses **Meslo LG Nerd Font** (installed by the Brewfile).
