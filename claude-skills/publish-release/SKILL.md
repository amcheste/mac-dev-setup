---
name: publish-release
description: Publish a new versioned release. Bumps version on develop, opens a develop→main PR, merges it, tags main, and triggers the release pipeline.
---

Publish a new release based on the user's request: $ARGUMENTS

## Parse the request

Extract from the user's message:
- **version**: explicit version string (e.g. `1.0.0`, `0.2.0-beta.1`) OR a bump level (`patch`, `minor`, `major`). Strip any leading `v`.
- **repo**: optional repository name. If not specified, use the current working directory. If named, look under `~/Repos` for a matching directory.

If the version is ambiguous or missing, ask the user to confirm before proceeding.

## Pre-flight checks

1. Confirm you are in the correct repository directory (or `cd` to it)
2. Run `git status` — the working tree must be clean
3. Run `git checkout develop && git pull` — must be on `develop` and up to date
4. Confirm `VERSION` file exists in the repo root
5. Read the current version from `VERSION` and show it to the user before proceeding

## Step 1 — Bump version on develop

Run the bump script:

```bash
# Explicit version (including pre-release)
./scripts/bump-version.sh set <version>

# Or a relative increment
./scripts/bump-version.sh patch   # or minor / major
```

The script updates `VERSION`, commits with `chore: release v<version>`, and creates an annotated tag locally. **Do not push the tag yet** — push only the commit:

```bash
git push origin develop
```

## Step 2 — Open develop → main PR

```bash
gh pr create \
  --base main \
  --head develop \
  --title "chore: release v<version>" \
  --body "Promotes develop to main for release v<version>.

After merging, the tag will be pushed to trigger the release pipeline."
```

Show the user the PR URL and ask them to approve and merge it.

## Step 3 — Tag main after merge

After the user confirms the PR is merged:

```bash
git checkout main && git pull
git tag -a "v<version>" -m "Release v<version>"
git push origin "v<version>"
```

## Step 4 — Confirm pipeline triggered

```bash
gh run list --limit 3
```

Show the user the release pipeline URL and confirm the tag was pushed. Let them know:
- If the version contains `-` (e.g. `-beta.1`, `-rc.1`) it is published as a **pre-release** and will not show as the latest version
- If it is a stable version (e.g. `1.0.0`) it becomes the **latest** release after all pipeline gates pass

## Summary

Tell the user:
- What version was tagged on `main`
- That the pipeline is running: validate → VM acceptance → publish
- Where to watch it: `https://github.com/amcheste/mac-dev-setup/actions`
- That `main` now equals the new release and `develop` is ready for the next cycle
