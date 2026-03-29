# Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

---

## Version Format

```
MAJOR.MINOR.PATCH[-PRE_RELEASE]
```

| Component | When to increment |
|-----------|-------------------|
| **MAJOR** | Breaking changes — tools removed, dotfiles restructured, setup flow changed in a non-backwards-compatible way |
| **MINOR** | New tools, new scripts, new MCP servers, new dotfile features — backwards compatible |
| **PATCH** | Bug fixes, documentation updates, CI improvements, dependency updates |
| **PRE_RELEASE** | Optional suffix signalling a version is not yet mainstream stable (e.g. `-beta.1`, `-rc.2`) |

---

## Stability Signals

| Version range | Meaning |
|---------------|---------|
| `0.x.x` | Pre-stable — actively being developed, breaking changes may occur between minor versions |
| `1.0.0`+ | Stable — the environment has been run on a real machine and proven reliable |
| `x.x.x-beta.N` | Beta — feature-complete for the version, but not yet fully tested |
| `x.x.x-rc.N` | Release candidate — final testing before a stable release |

Pre-release versions are published to GitHub Releases with the **Pre-release** flag set,
so they never show as the "latest" release. Only stable versions become the default install.

---

## Bumping a Version

Use the bump script — it updates `VERSION`, promotes `CHANGELOG.md`, commits, and tags:

```bash
# Increment automatically
./scripts/bump-version.sh patch      # 1.0.0 → 1.0.1
./scripts/bump-version.sh minor      # 1.0.0 → 1.1.0
./scripts/bump-version.sh major      # 1.0.0 → 2.0.0

# Set an explicit version (use for pre-releases or precise control)
./scripts/bump-version.sh set 0.1.0-beta.1
./scripts/bump-version.sh set 1.0.0-rc.1
./scripts/bump-version.sh set 1.0.0
```

Then push the commit and tag to trigger the release pipeline:

```bash
git push && git push --tags
```

---

## Release Pipeline

Pushing a `v*.*.*` tag automatically triggers:

```
tag push → validate → VM acceptance test → publish GitHub Release
```

The release is **blocked** if either gate fails. A pre-release tag (containing `-`)
publishes with the GitHub Pre-release flag and does not become the default install version.

---

## Changelog

All notable changes are recorded in [CHANGELOG.md](CHANGELOG.md) following the
[Keep a Changelog](https://keepachangelog.com/) format.

Work lands under `## [Unreleased]` and is promoted to a version entry by the bump script.
