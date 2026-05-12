---
name: publish-release
description: Publish a new versioned release. Opens a version bump PR to develop, merges it, promotes develop to main via CLI --no-ff merge (never a GitHub PR), tags main, and triggers the release pipeline.
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

## Step 1 — Version bump PR to develop

Create a short-lived release branch, bump the version, and open a PR to develop:

```bash
git checkout -b chore/release-v<version>

# Bump version using the script
./scripts/bump-version.sh set <version>    # explicit
./scripts/bump-version.sh patch            # or minor / major

# The script commits with: chore: release v<version>
# Do NOT push the annotated tag yet — just the commit

git push -u origin chore/release-v<version>

gh pr create \
  --base develop \
  --head chore/release-v<version> \
  --title "chore: release v<version>" \
  --body "Version bump to v<version>. Merge to proceed with the develop→main CLI release merge."
```

Show the user the PR URL. Wait for CI to pass, then ask them to approve and merge it.

## Step 2 — Promote develop → main via CLI merge

After the version bump PR is merged, promote develop to main with a non-fast-forward merge from the command line.

> **Do NOT use a GitHub PR for this step.** GitHub's merge button squash-merges by default, which flattens every commit on develop into a single new commit on main with no ancestry relationship. On the next release, main and develop have diverged at every commit and every subsequent release hits merge conflicts. A `--no-ff` CLI merge preserves the commit graph so main remains a strict ancestor of develop.

```bash
git fetch origin
git checkout main && git pull
git merge --no-ff origin/develop -m "chore: release v<version>"
git push origin main
```

Confirm the push succeeded before moving to Step 3.

> **Branch protection note:** if `main` has `enforce_admins: true` and required-PR review, the CLI push will be rejected. Toggle protection around the push:
>
> ```bash
> # Disable bypass-prevention temporarily
> gh api -X DELETE repos/<owner/repo>/branches/main/protection/enforce_admins
>
> # ...do the merge and push above...
>
> # Re-enable
> gh api -X POST repos/<owner/repo>/branches/main/protection/enforce_admins
> ```
>
> The `amcheste-ai-agent` GitHub App needs `Administration: Read & Write` permission on the install for these toggles. The same dance applies to the `v*` tag ruleset in Step 3 if tag creation is restricted — toggle the ruleset's enforcement to `disabled` around the tag push, then back to `active`.

## Step 3 — Tag main

```bash
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

## Step 5 — Ensure `main` is the GitHub default branch

`develop` is the integration trunk and stays the same. GitHub's "default branch" repo setting is separate — it controls landing page, `git clone` target, and PR-base UI default. The convention (see [Branching & Releases](https://github.com/amcheste/engineering-handbook/blob/develop/docs/workflows/branching-and-releases.md#github-default-branch-setting)) is:

- Pre-release: GitHub default = `develop` (the only meaningful state)
- Post-release: GitHub default = `main` (external visitors see the shipped product)

Run this unconditionally at the end of the release flow. It's idempotent: on the first release it flips develop → main, on every subsequent release it's a no-op.

```bash
current=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
if [ "$current" != "main" ]; then
  gh repo edit --default-branch main
  echo "GitHub default branch flipped to main (first release)."
else
  echo "GitHub default branch already main."
fi
```

Contributors keep branching from and PR'ing to `develop` — only what GitHub renders on the repo landing page changes.

## Summary

Tell the user:
- What version was tagged on `main`
- That the pipeline is running: validate → VM acceptance → publish
- Where to watch it: `https://github.com/amcheste/<repo>/actions`
- That `main` now equals the new release and `develop` is ready for the next cycle
- If Step 5 flipped the default branch, mention it explicitly (it's the first release)
