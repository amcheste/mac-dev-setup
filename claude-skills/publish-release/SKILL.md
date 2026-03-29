---
name: publish-release
description: Publish a new versioned release for a repository. Handles VERSION bump, CHANGELOG promotion, git commit, tag, and push to trigger the release pipeline.
---

Publish a new release based on the user's request: $ARGUMENTS

## Parse the request

Extract from the user's message:
- **version**: the version string (e.g. `1.0.0`, `0.1.0-beta.1`, `2.1.0-rc.1`). Strip any leading `v`.
- **repo**: optional repository name. If not specified, use the current working directory. If named, look under `~/Repos` for a matching directory.

If the version is ambiguous or missing, ask the user to confirm before proceeding.

## Pre-flight checks

1. Confirm you are in the correct repository directory (or `cd` to it)
2. Run `git status` — the working tree must be clean with no uncommitted changes
3. Run `git checkout main && git pull` — must be on `main` and up to date with `origin/main`
4. Confirm `VERSION` file exists in the repo root
5. Read the current version from `VERSION` and show it to the user before proceeding

## Execute the release

Run the bump script with the appropriate subcommand:

```bash
# For patch/minor/major increments
./scripts/bump-version.sh patch   # or minor / major

# For explicit versions including pre-release
./scripts/bump-version.sh set <version>
```

The script will:
- Update `VERSION`
- Promote `[Unreleased]` in `CHANGELOG.md` to the new version with today's date
- Commit with message `chore: release v<version>`
- Create an annotated tag `v<version>`

## Push

```bash
git push && git push --tags
```

## Confirm pipeline triggered

After pushing, run:
```bash
gh run list --limit 3
```

Show the user the release pipeline URL and confirm the tag was pushed. Let them know:
- If the version contains `-` (e.g. `-beta.1`, `-rc.1`) it will be published as a **pre-release** in GitHub and will not show as the latest version
- If it is a stable version (e.g. `1.0.0`) it will become the **latest** release after the pipeline passes

## Summary

Tell the user:
- What version was tagged
- That the pipeline is running: validate → VM acceptance → publish
- Where to watch it: `https://github.com/amcheste/mac-dev-setup/actions`
- That a GitHub Release will be created automatically if all gates pass
