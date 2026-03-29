# Contributing

## This Is a Personal Development Environment

`mac-dev-setup` is **Alan Chester's personal macOS developer environment**. Every tool,
dotfile, alias, and preference in this repo reflects how Alan works day-to-day.
It is published openly so others can learn from it, fork it, and adapt it for their own use.

### What this means for contributions

- **You are welcome to fork this repo** and tailor it to your own workflow. That is the primary
  intended use case for anyone other than Alan.
- **PRs are welcome** for genuine bugs, broken tooling, or improvements that are broadly useful
  and not preference-specific.
- **Preference PRs will generally be declined.** If you prefer a different shell, editor, color
  scheme, or aliasing style — fork it. This repo is not a general-purpose tool; it is a specific
  person's environment.
- **Alan has final say** on what goes into this repo. A PR may be well-written, well-tested, and
  genuinely useful, and still be declined because it doesn't fit how Alan works. That is not a
  reflection of your contribution quality — it just isn't the right repo for it.

If you are building your own environment, fork this repo and make it yours.
If you've found something that is broken or outdated in a way that affects everyone, open a PR.

---

## Getting Started (for contributors)

**Prerequisites:**
- [`shellcheck`](https://github.com/koalaman/shellcheck) — `brew install shellcheck`
- [`act`](https://github.com/nektos/act) — `brew install act` — local GitHub Actions runner
- [`tart`](https://github.com/cirruslabs/tart) — `brew install cirruslabs/cli/tart` — VM acceptance tests

Fork and clone to the standard path:
```bash
git clone git@github.com:<YOUR_FORK>/mac-dev-setup ~/Repos/<YOUR_GITHUB_USERNAME>/mac-dev-setup
cd ~/Repos/<YOUR_GITHUB_USERNAME>/mac-dev-setup
git checkout develop
```

---

## Branch Model

| Branch | Purpose |
|--------|---------|
| `main` | Always equals the latest published release — stable, never directly committed to |
| `develop` | Integration branch — all PRs target here |
| `feature/*`, `fix/*`, etc. | Short-lived branches off `develop` |

PRs go to `develop`. When enough changes accumulate for a release, `develop` is promoted to `main` via the `/publish-release` skill, which opens the develop→main PR automatically.

## Development Workflow

Run `shellcheck` on any modified scripts before committing:
```bash
shellcheck setup.sh scripts/*.sh
```

Test workflow changes locally with `act` before pushing:
```bash
act pull_request -j lint
```

`Brewfile.ci` must stay in sync with `Brewfile` for CLI tools. Any formula added to `Brewfile`
that is not a GUI cask must also appear in `Brewfile.ci`.

---

## Adding a Tool

1. **Brewfile** — add the formula. If it is a CLI tool, add it to `Brewfile.ci` as well.
2. **Dotfiles** — add relevant aliases or configuration to `dotfiles/zshrc`.
3. **Validate smoke test** — add `command -v <tool>` to the smoke-test step in `.github/workflows/validate.yml`.
4. **README table** — add a row to the appropriate table in `README.md`.

---

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use |
|--------|-----|
| `feat:` | New tool, script, or workflow capability |
| `fix:` | Bug fix in a script or workflow |
| `docs:` | README, CHANGELOG, or inline comment changes |
| `chore:` | Version bumps, dependency updates, housekeeping |

One logical change per PR. Keep commits atomic and the history readable.

---

## Running Acceptance Tests

**Locally (requires Tart):**
```bash
bash scripts/vm-acceptance-test.sh
```

This boots a fresh Sequoia base image, runs `setup.sh` inside the VM, and executes
`scripts/acceptance-test.sh` to verify the result.

**In CI:** trigger manually via `workflow_dispatch` on the
[VM Acceptance Test](../../actions/workflows/acceptance.yml) workflow.
The acceptance workflow also runs automatically on every `v*.*.*` release tag as part of the
release gate.

---

## Release Process

> Only the repo owner publishes releases.

Releases are handled by the `/publish-release` Claude Code skill, which automates the full flow:

1. Bumps version on `develop`, commits `chore: release v<version>`
2. Opens a PR: `develop → main`
3. Owner approves and merges the PR
4. Tags `main` with `v<version>` and pushes the tag
5. Release pipeline fires automatically: validate → VM acceptance → publish

To trigger manually:
```bash
# In Claude Code
/publish-release 1.0.0

# Or via bump script directly (then follow the steps above)
./scripts/bump-version.sh patch   # or minor / major / set <version>
```
