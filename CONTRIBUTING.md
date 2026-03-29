# Contributing

## Getting Started

**Prerequisites:**
- [`shellcheck`](https://github.com/koalaman/shellcheck) — `brew install shellcheck`
- [`act`](https://github.com/nektos/act) — `brew install act` — local GitHub Actions runner
- [`tart`](https://github.com/cirruslabs/tart) — `brew install cirruslabs/cli/tart` — VM acceptance tests

Clone to the expected path:
```bash
git clone git@github.com:amcheste/mac-dev-setup ~/Repos/amcheste/mac-dev-setup
```

---

## Development Workflow

Run shellcheck on any modified scripts before committing:
```bash
shellcheck setup.sh scripts/*.sh
```

Test workflow changes locally with `act` before pushing:
```bash
act pull_request -j lint
```

`Brewfile.ci` must stay in sync with `Brewfile` for CLI tools. Any formula added to `Brewfile` that is not a GUI cask must also appear in `Brewfile.ci`.

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

This clones a fresh Sequoia base image, runs `setup.sh` inside the VM, and executes `scripts/acceptance-test.sh` to verify the result.

**In CI:** trigger manually via `workflow_dispatch` on the [VM Acceptance Test](../../actions/workflows/acceptance.yml) workflow. The acceptance workflow also runs automatically on every `v*.*.*` release tag as part of the release gate.

---

## Release Process

1. Update `CHANGELOG.md` — move items from `[Unreleased]` into the new version section if needed.
2. Run the bump script:
   ```bash
   ./scripts/bump-version.sh patch   # or minor / major
   ```
3. Push the commit and tag:
   ```bash
   git push && git push --tags
   ```
4. The release pipeline runs automatically: validate → VM acceptance → draft release notes → publish.
