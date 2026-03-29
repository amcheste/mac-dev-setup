#!/usr/bin/env bash
# Bump semver in VERSION, update CHANGELOG.md, commit, and tag.
# Usage: ./scripts/bump-version.sh [major|minor|patch]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"
CHANGELOG_FILE="$REPO_ROOT/CHANGELOG.md"

usage() {
  echo "Usage: $0 [major|minor|patch]" >&2
  exit 1
}

[[ $# -ne 1 ]] && usage

COMPONENT="$1"
[[ "$COMPONENT" =~ ^(major|minor|patch)$ ]] || usage

# Read and parse current version
CURRENT="$(tr -d '[:space:]' < "$VERSION_FILE")"
if [[ ! "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "ERROR: VERSION file contains invalid semver: '$CURRENT'" >&2
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

case "$COMPONENT" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TODAY="$(date +%Y-%m-%d)"

echo "▶ Bumping $CURRENT → $NEW_VERSION"

# Update VERSION
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update CHANGELOG: replace '## [Unreleased]' with new release entry,
# insert fresh '[Unreleased]' block above it.
if ! grep -q '## \[Unreleased\]' "$CHANGELOG_FILE"; then
  echo "ERROR: CHANGELOG.md is missing '## [Unreleased]' section." >&2
  exit 1
fi

# Use awk for reliable multi-line manipulation
awk -v ver="$NEW_VERSION" -v date="$TODAY" '
  /^## \[Unreleased\]$/ {
    print "## [Unreleased]"
    print ""
    print "## [" ver "] - " date
    next
  }
  { print }
' "$CHANGELOG_FILE" > "${CHANGELOG_FILE}.tmp"

mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"

echo "▶ Updated CHANGELOG.md"

# Stage and commit
git -C "$REPO_ROOT" add "$VERSION_FILE" "$CHANGELOG_FILE"
git -C "$REPO_ROOT" commit -m "chore: bump version to v${NEW_VERSION}"

# Annotated tag
git -C "$REPO_ROOT" tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"

echo "✓ Committed and tagged v${NEW_VERSION}"
echo ""
echo "Next steps:"
echo "  git push && git push --tags"
