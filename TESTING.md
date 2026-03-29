# Testing Guide

This document describes every layer of testing available for `mac-dev-setup` —
from automated CI to full acceptance tests on a clean machine.

---

## What CI/CD Covers

Every pull request and push to `main` runs three jobs on GitHub Actions:

### Job 1 — Lint (Ubuntu, ~7 seconds)

| Check | How | What it catches |
|-------|-----|----------------|
| Shell script linting | `shellcheck` on all `.sh` files | Broken syntax, unsafe patterns, unused variables |
| Secret safety scan | Regex against `secrets.template` | Real credentials accidentally committed |
| `.gitignore` verification | Grep for `.secrets` entry | Secrets file exposed in git |

### Job 2 — Formula Audit (macOS, ~30 seconds)

| Check | How | What it catches |
|-------|-----|----------------|
| Formula correctness | `brew audit --strict` | Invalid formula structure, bad depends_on |
| Formula style | `brew style` | Ordering violations, deprecated API usage |

### Job 3 — Integration Test (macOS, ~2 minutes, runs after Jobs 1 & 2)

| Check | How | What it catches |
|-------|-----|----------------|
| Package install | `brew bundle --file=Brewfile.ci` | Broken package names, dependency conflicts |
| Dotfile install | `bash scripts/install-dotfiles.sh` | Script errors, missing source files |
| Symlinks created | `test -L ~/.zshrc && test -L ~/.vimrc` | install-dotfiles.sh not linking correctly |
| Secrets template | `test -f ~/.secrets` | Template not copied on first run |
| File permissions | `stat -f "%Mp%Lp" ~/.secrets` == `0600` | Secrets file world-readable |
| Tool availability | `command -v` for go, kubectl, helm, terraform, doctl, jq, gh | Package installs failing silently |

**What CI does NOT cover:**
- GUI cask installs (Cursor, Docker Desktop, GoLand, etc.) — too slow for CI
- The full `Brewfile` — `Brewfile.ci` is a CLI-only subset
- Interactive scripts (`setup-credentials.sh`, `setup-mcps.sh`)
- Vim plugin installation
- Homebrew bootstrap (runner already has Homebrew)
- Apple Silicon vs Intel differences (runner is fixed architecture)

These gaps are covered by the acceptance testing options below.

---

## Option 1 — Local Testing with `act` (Fastest)

[`act`](https://github.com/nektos/act) runs GitHub Actions workflows locally using Docker.
Use this to iterate on workflow changes without pushing.

**Install:**
```bash
brew install act
```

**Usage:**
```bash
# Run the full validate pipeline
act pull_request

# Run a single job
act pull_request -j lint
act pull_request -j formula-audit
act pull_request -j integration

# List available workflows and jobs
act --list

# Dry run — show what would execute without running
act pull_request --dryrun
```

**Notes:**
- `act` runs on Linux containers by default — the `lint` job works perfectly
- The `formula-audit` and `integration` jobs require macOS and will be skipped or emulated
- Use `act` primarily for rapid iteration on the `lint` job before pushing
- First run downloads a Docker image (~1GB) — subsequent runs are fast

---

## Option 2 — New macOS User Account (Best Value)

Create a second user on your Mac with a clean home directory.
This is the closest thing to a real zero-state install without any additional hardware.

**What it tests:**
- Full `Brewfile` including all GUI casks
- Complete `setup.sh` from start to finish
- Dotfile symlinking
- Vim plugin bootstrap
- `setup-credentials.sh` interactive flow
- `setup-mcps.sh` MCP configuration
- The actual user experience of a fresh install

**Steps:**

1. Create a new user account:
   ```
   System Settings → Users & Groups → Add Account
   Name: testenv (or any name)
   Account type: Administrator (needed for Homebrew)
   ```

2. Log in as the new user (or use fast user switching):
   ```
   Apple menu → Lock Screen, then log in as testenv
   ```

3. Open Terminal and run setup:
   ```bash
   git clone https://github.com/amcheste/mac-dev-setup \
       ~/Repos/amcheste/mac-dev-setup
   cd ~/Repos/amcheste/mac-dev-setup
   bash setup.sh
   ```

4. Walk through the credential wizard — use dummy values or real ones.

5. Verify the environment works as expected.

**Cleanup:**
```
System Settings → Users & Groups → select testenv → Delete Account
```
Choose "Delete the home folder" to fully clean up.

**Tips:**
- You can leave the test user around and re-run `bash scripts/upgrade.sh` to test upgrades
- Use fast user switching to go back and forth without logging out
- Take a screenshot of any failures for debugging

---

## Option 3 — Manual GitHub Actions Run (Recorded & Reproducible)

Add a `workflow_dispatch` trigger to run the full pipeline manually — including casks — from the GitHub UI.
This gives you a cloud-hosted, recorded acceptance test you can run before any release.

**To enable:** The `release.yml` workflow already has validation gates.
For a manual full test, trigger it from the Actions tab:

```
GitHub → Actions → Validate → Run workflow → select branch → Run
```

To add a full-Brewfile manual job (including casks), add this to `validate.yml`:

```yaml
  full-install:
    name: Full Install (Manual Only)
    runs-on: macos-latest
    if: github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4
      - name: Full brew bundle including casks
        run: brew bundle --file=Brewfile --no-upgrade
        timeout-minutes: 60
```

**What this adds over CI:**
- Installs all casks (Cursor, Docker, GoLand, etc.)
- Validates full `Brewfile` package names are current
- Gives you a timestamped, logged record of a clean install

**Cost:** macOS runner minutes count against your GitHub Actions quota (~10x Linux rate).
A full run with casks takes ~30-45 minutes. Run manually before releases, not on every PR.

---

## Option 4 — UTM macOS Virtual Machine (Best Isolation)

[UTM](https://mac.getutm.app) is a free, open-source VM manager for macOS.
A macOS guest VM gives true clean-room testing — snapshotable and restorable.

**Install UTM:**
```bash
brew install --cask utm
```

**Setup:**

1. Download a macOS IPSW restore image from [mrmacintosh.com](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/) or via `softwareupdate --fetch-full-installer`

2. In UTM: New VM → Virtualize → macOS → select IPSW → configure RAM/disk (16GB RAM, 60GB disk recommended)

3. Complete macOS setup inside the VM — create a user account, skip Apple ID

4. Take a **snapshot** before running setup (UTM → VM menu → Snapshot → Save):
   ```
   Snapshot name: "clean-install"
   ```

5. Run setup inside the VM:
   ```bash
   git clone https://github.com/amcheste/mac-dev-setup \
       ~/Repos/amcheste/mac-dev-setup
   bash ~/Repos/amcheste/mac-dev-setup/setup.sh
   ```

6. After testing, restore to snapshot to reset to clean state:
   ```
   UTM → VM menu → Snapshot → Restore → "clean-install"
   ```

**What this adds:**
- True clean-room — no pre-installed tools, fresh Homebrew
- Restorable — test as many times as you want from the same baseline
- Architecture testing — create ARM and Intel VMs to test both
- Offline testing — no cloud dependency

**Notes:**
- Apple Silicon Macs can only run Apple Silicon macOS guests (not Intel macOS)
- Performance is good for CLI work; GUI app installs are slow in the VM
- First-time setup of the VM takes ~30 minutes but snapshots make subsequent tests instant

---

## Option 5 — Cloud Mac / GitHub Larger Runners (Team / Automated)

For a fully automated, hosted clean-room test — relevant if this becomes a team setup.

**GitHub Larger Runners (macOS):**
- `macos-latest-xlarge` — Apple Silicon, 6 vCPU, 14GB RAM
- Add to a workflow with `runs-on: macos-latest-xlarge`
- Fully clean environment, billed per minute
- Good for release gates on a team

**MacStadium / Orka:**
- Dedicated Mac hardware in the cloud
- Persistent VMs you control — snapshot, restore, automate
- Relevant when this setup is used across a team

**Cost estimate for a full manual install run:**
- GitHub macOS-latest: ~$0.08/min × 45 min ≈ $3.60 per run
- Run this manually before releases, not on every PR

---

## Acceptance Test Checklist

Use this checklist when running a full acceptance test (Options 2, 4, or 5):

### Installation
- [ ] `setup.sh` completes without errors
- [ ] Homebrew is installed (or detected if already present)
- [ ] All packages in `Brewfile` install successfully
- [ ] `~/.zshrc` is symlinked to `dotfiles/zshrc`
- [ ] `~/.vimrc` is symlinked to `dotfiles/vimrc`
- [ ] `~/.secrets` is created from template with `chmod 600`
- [ ] vim-plug is installed at `~/.vim/autoload/plug.vim`
- [ ] Vim plugins install without errors (`vim +PlugInstall +qall`)

### Tools
- [ ] `go version` works
- [ ] `python3 --version` works (via pyenv)
- [ ] `node --version` works (via nvm)
- [ ] `kubectl version --client` works
- [ ] `helm version` works
- [ ] `terraform version` works
- [ ] `doctl version` works
- [ ] `gh --version` works
- [ ] `docker --version` works (if Docker Desktop installed)

### Credentials & MCPs
- [ ] `setup-credentials.sh` runs and writes `~/.secrets`
- [ ] `source ~/.secrets` exports expected variables
- [ ] `setup-mcps.sh` configures all MCP servers
- [ ] `claude mcp list` shows GitHub, filesystem, memory, postgres
- [ ] `gh auth status` shows authenticated

### Shell Environment
- [ ] Open a new terminal — prompt appears correctly
- [ ] `repos` alias navigates to `~/Repos`
- [ ] `k` alias works (`kubectl`)
- [ ] `tf` alias works (`terraform`)
- [ ] pyenv and nvm load without errors on shell start

### Upgrade
- [ ] `bash scripts/upgrade.sh` runs without errors on an already-configured machine
- [ ] Re-running `setup.sh` is idempotent — no duplicate installs or errors
