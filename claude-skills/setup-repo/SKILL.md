---
name: setup-repo
description: Apply standard branch model, protection rules, and settings to a GitHub repository. Creates develop branch, sets it as default, protects develop and main, adds tag protection, and verifies CODEOWNERS routing.
---

Configure a GitHub repository with the standard branch model and protection rules: $ARGUMENTS

## Parse the request

Extract from the user's message:
- **repo**: the repository to configure, in `owner/repo` format. If only a name is given, assume `amcheste/<name>`. If not specified, use the current git remote: `gh repo view --json nameWithOwner -q .nameWithOwner`

## Pre-flight

1. Verify the repo exists: `gh repo view <owner/repo>`
2. **Refuse forks.** `setup-repo` configures the conventions of the *owner* of the repo. A fork is owned by upstream's conventions, not yours — applying your branching model, protections, and CODEOWNERS to it is wrong:

   ```bash
   if [ "$(gh repo view <owner/repo> --json isFork --jq .isFork)" = "true" ]; then
     echo "ERROR: <owner/repo> is a fork. setup-repo follows your conventions; forks follow upstream's. Aborting."
     exit 1
   fi
   ```

   This also applies to audit scripts that survey "all my repos" — use `gh repo list --source` (filters out forks) instead of plain `gh repo list` so forks don't surface in the report.
3. Show the user what you're about to do and confirm before making any changes

## Step 1 — Ensure develop branch exists

```bash
# Check if develop already exists
gh api repos/<owner/repo>/branches/develop 2>/dev/null && echo "exists" || echo "missing"
```

If missing:
```bash
# Get main branch HEAD SHA
MAIN_SHA=$(gh api repos/<owner/repo>/branches/main --jq '.commit.sha')

# Create develop at the same commit as main
gh api repos/<owner/repo>/git/refs \
  --method POST \
  --field ref="refs/heads/develop" \
  --field sha="$MAIN_SHA"
```

## Step 2 — Set develop as default branch

```bash
gh api repos/<owner/repo> \
  --method PATCH \
  --field default_branch=develop \
  --jq '.default_branch'
```

## Step 3 — Set merge policy: disable squash, default to rebase

Squash-merging is destructive when bot-authored PRs are merged by a human:
the squash commit replaces the bot's primary authorship with the merger, and
GitHub silently drops the `Co-Authored-By` trailers (so the human steering
the bot loses contribution-graph credit, and `git blame` no longer reflects
who actually wrote the code). Rebase merge preserves per-commit authorship
and trailers; merge commits stay enabled as a fallback for ceremonial merges
like the CLI `--no-ff` `develop → main` release promotion.

```bash
gh api repos/<owner/repo> \
  --method PATCH \
  --field allow_squash_merge=false \
  --field allow_rebase_merge=true \
  --field allow_merge_commit=true \
  --jq '{allow_squash_merge, allow_rebase_merge, allow_merge_commit}'
```

The convention alone isn't enough — without disabling squash at the repo
level, the wrong button eventually gets clicked. See
[engineering handbook → merge strategy](https://github.com/amcheste/engineering-handbook/blob/main/docs/philosophies/merge-strategy.md)
for the full reasoning.

## Step 4 — Protect develop

Require a PR and status checks before merging. Check if `.github/workflows/validate.yml` exists in the repo to know which checks to require:

```bash
gh api repos/<owner/repo>/contents/.github/workflows/validate.yml 2>/dev/null && echo "exists"
```

If validate.yml **exists**, ask the user which status check names to require (default: `Lint`, `Commit Lint`). If it **doesn't exist**, apply protection without required checks — just require a PR.

```bash
gh api repos/<owner/repo>/branches/develop/protection \
  --method PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [/* populated from above */]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## Step 5 — Protect main

Require a PR before merging. No direct pushes. No Commit Lint check required here (the develop→main release PR is a `chore:` commit which is valid, but having it as a required check on main is redundant).

```bash
gh api repos/<owner/repo>/branches/main/protection \
  --method PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [/* same as develop minus Commit Lint */]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## Step 6 — Tag protection ruleset

Prevent accidental creation, deletion, or force-moving of `v*` tags:

```bash
gh api repos/<owner/repo>/rulesets \
  --method POST \
  --input - <<'EOF'
{
  "name": "Protect release tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/v*"],
      "exclude": []
    }
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "creation"}
  ]
}
EOF
```

## Step 7 — Verify CODEOWNERS routing

Bot-authored PRs (via the `amcheste-ai-agent` GitHub App) need
`.github/CODEOWNERS` to auto-route review requests to a human reviewer.
Without this file, App-authored PRs don't appear in any reviewer's
queue (Graphite, GitHub's review-requested filter, etc.) and get lost.

```bash
gh api repos/<owner/repo>/contents/.github/CODEOWNERS >/dev/null 2>&1 \
  && echo "✓ CODEOWNERS exists" \
  || echo "⚠ CODEOWNERS missing"
```

If the file is missing, **do not write it directly** — `setup-repo` only
configures settings/rulesets, never commits to the repo. Instead, surface
the gap in the summary so the user can add it via a PR. The canonical
default content is:

```
# See https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
* @amcheste
```

This pairs with the bot-account model documented in the
[engineering handbook](https://github.com/amcheste/engineering-handbook/blob/main/docs/design/claude-bot-account.md).

## Summary

Report what was configured (and any gaps that need a follow-up PR):

```
✓ develop branch created (or already existed)
✓ develop set as default branch
✓ Merge policy: squash disabled, rebase + merge enabled
✓ develop protected — require PR + [checks]
✓ main protected — require PR + [checks]
✓ Tag ruleset active — v* tags protected
✓/⚠ CODEOWNERS verified (or: CODEOWNERS missing — see follow-ups)

Next steps:
- If using repo-template: copy .github/ files into this repo
- Add project-specific lint/test steps to .github/workflows/validate.yml
- Update required status check names to match your workflow job names
- If CODEOWNERS was missing, open a PR adding `.github/CODEOWNERS` with `* @amcheste`
```
