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
2. Show the user what you're about to do and confirm before making any changes

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

## Step 3 — Protect develop

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

## Step 4 — Protect main

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

## Step 5 — Tag protection ruleset

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

## Step 6 — Verify CODEOWNERS routing

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
