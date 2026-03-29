# CLAUDE.md — mac-dev-setup

This file is read by Claude Code at the start of every session in this repo.
It captures developer preferences, project conventions, and accumulated knowledge.

---

## About This Repo

This is a personal macOS developer environment managed as a Homebrew tap.
The goal is a single command that gets a machine from zero to fully productive —
tools, dotfiles, credentials, MCPs, and Claude Code configuration all included.

**Key files:**
- `setup.sh` — bootstrap entry point (run on a fresh machine)
- `Brewfile` — full package list including GUI casks
- `Brewfile.ci` — CLI-only subset used in CI (no heavy casks)
- `Formula/dev-tools.rb` — Homebrew formula for the tap
- `dotfiles/` — zshrc, vimrc, secrets.template (symlinked into $HOME)
- `scripts/` — install-dotfiles, setup-credentials, setup-mcps, upgrade

---

## Developer Preferences

### Editor
- Primary editor: **Vim** with vim-plug, ALE, vim-go, gruvbox
- AI editor: **Cursor** for larger refactors and exploration
- Never assume VS Code

### Shell
- Shell: **zsh**
- Prompt is minimal (`%n:%1~ $ `) — no heavy frameworks like oh-my-zsh
- Aliases and functions live in `dotfiles/zshrc`, not scattered elsewhere

### Languages
- **Go** — preferred for backend services and CLI tools
- **Python** — scripting, data work, AI integrations
- **Java** — enterprise/existing projects (Maven)
- **Node/TypeScript** — frontend and MCP server work

### Cloud & Infrastructure
- **OCI (Oracle Cloud)** and **DigitalOcean** — both actively used
- **Kubernetes** locally via `kind`, remotely via OCI/DO clusters
- **ArgoCD** for GitOps deployments
- **Terraform** for infrastructure as code

### Git & GitHub Workflow
- Always branch from `main`, never commit directly
- Always open a PR for review before merging
- Commit messages should be descriptive — explain *why*, not just *what*
- Conventional commits style: `feat:`, `fix:`, `docs:`, `chore:`

### Scripting Standards
- All shell scripts must pass `shellcheck` with no warnings
- Scripts should be idempotent — safe to run multiple times
- Always use `set -euo pipefail` at the top of bash scripts
- Prefer explicit error messages over silent failures

### Testing & CI
- Use `act` to test GitHub Actions workflows locally before pushing:
  ```bash
  act pull_request                   # full pipeline
  act pull_request -j lint           # lint job only
  act pull_request -j formula-audit  # formula audit only
  ```
- `Brewfile.ci` exists for fast CI runs — add new CLI tools there too
- See `TESTING.md` for full acceptance testing options

### Secrets & Credentials
- Secrets live in `~/.secrets` (chmod 600, never committed)
- `dotfiles/secrets.template` documents every slot
- `scripts/setup-credentials.sh` is the interactive wizard
- Never hardcode credentials in any file

### Repository Layout
- All repos cloned to `~/Repos/<ORG>/<REPO>` (e.g. `~/Repos/amcheste/mac-dev-setup`)
- `~/Repos` is created by `setup.sh` on first run

---

## Working in This Repo

When making changes:
1. Run `shellcheck` on any modified scripts before committing
2. Test workflow changes with `act` before pushing
3. Update `Brewfile.ci` alongside `Brewfile` when adding CLI tools
4. If changing dotfiles, test with `bash scripts/install-dotfiles.sh` locally

When adding a new tool to the environment:
1. Add to `Brewfile` (and `Brewfile.ci` if it's a CLI tool)
2. Add any config/aliases to `dotfiles/zshrc` or `dotfiles/vimrc`
3. Add to the smoke-test in `.github/workflows/validate.yml`
4. Update `README.md` tool table

---

## Learned Preferences

> **How this section works:** As Claude works with you across sessions and notices
> a consistent pattern or preference, it should suggest adding it here as a one-liner.
> You review, refine, and commit it. This keeps durable knowledge in the repo —
> not session-specific questions, but things that should be true on a clean install.

<!-- Preferences are added here over time as they are discovered -->
- Prefer interactive scripts with clear progress output (use `▶` prefix for steps, `✓` for success)
- Prefer ASCII art / box-drawing separators (`━━━`) over plain `---` in terminal output
- Keep CI fast — integration test should complete under 5 minutes
- GUI cask installs are always deferred to manual or `setup.sh`, never required in CI
