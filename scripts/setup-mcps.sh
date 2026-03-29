#!/usr/bin/env bash
# setup-mcps.sh — Configure Claude Code MCP servers for development.
# Idempotent — skips servers that are already configured.
# Run after setup-credentials.sh so ~/.secrets is populated.
set -euo pipefail

SECRETS_FILE="$HOME/.secrets"

# Load secrets so we can use API keys and tokens
if [[ -f "$SECRETS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$SECRETS_FILE"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code MCP Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Configures MCP servers at user scope (~/.claude/)."
echo "  These are available in every Claude Code session."
echo ""

# Check claude is installed
if ! command -v claude &>/dev/null; then
    echo "ERROR: Claude Code is not installed."
    echo "  Run: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Helper: check if an MCP is already registered
mcp_exists() {
    claude mcp list 2>/dev/null | grep -q "^$1"
}

# ── GitHub MCP ────────────────────────────────────────────────────────────────
# Gives Claude direct access to PRs, issues, repos, Actions, code search
echo "── GitHub MCP ───────────────────────────────────────────────────────────"
if mcp_exists "github"; then
    echo "  Already configured ✓"
else
    # Use the token from gh CLI if available, fall back to env var
    GITHUB_TOKEN=""
    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
        GITHUB_TOKEN="$(gh auth token)"
        echo "  Using token from gh CLI"
    elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "  Using GITHUB_TOKEN from environment"
    else
        echo "  WARNING: No GitHub token found. Run 'gh auth login' first."
        echo "  Skipping GitHub MCP."
    fi

    if [[ -n "$GITHUB_TOKEN" ]]; then
        claude mcp add github -s user \
            -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN" \
            -- docker run -i --rm \
            -e GITHUB_PERSONAL_ACCESS_TOKEN \
            ghcr.io/github/github-mcp-server
        echo "  GitHub MCP configured ✓"
        echo "  Capabilities: repos, PRs, issues, Actions, code search, releases"
    fi
fi

echo ""

# ── Filesystem MCP ───────────────────────────────────────────────────────────
# Scoped read/write access so Claude can navigate beyond the current project
echo "── Filesystem MCP ───────────────────────────────────────────────────────"
if mcp_exists "filesystem"; then
    echo "  Already configured ✓"
else
    claude mcp add filesystem -s user \
        -- npx -y @modelcontextprotocol/server-filesystem \
        "$HOME/Repos" \
        "$HOME/Documents" \
        "$HOME/.claude"
    echo "  Filesystem MCP configured ✓"
    echo "  Scoped to: ~/Repos, ~/Documents, ~/.claude"
fi

echo ""

# ── Memory MCP ───────────────────────────────────────────────────────────────
# Persistent facts across sessions — supplements CLAUDE.md with dynamic context
echo "── Memory MCP ───────────────────────────────────────────────────────────"
if mcp_exists "memory"; then
    echo "  Already configured ✓"
else
    claude mcp add memory -s user \
        -- npx -y @modelcontextprotocol/server-memory
    echo "  Memory MCP configured ✓"
    echo "  Stores facts that persist across Claude Code sessions"
fi

echo ""

# ── PostgreSQL MCP ───────────────────────────────────────────────────────────
# Direct database access — Claude can query dev/local databases
echo "── PostgreSQL MCP ───────────────────────────────────────────────────────"
if mcp_exists "postgres"; then
    echo "  Already configured ✓"
else
    # Default to local postgres; can be overridden via DB_URL env var
    DB_URL="${DB_URL:-postgresql://localhost/postgres}"
    claude mcp add postgres -s user \
        -- npx -y @modelcontextprotocol/server-postgres \
        "$DB_URL"
    echo "  PostgreSQL MCP configured ✓"
    echo "  Connected to: $DB_URL"
    echo "  NOTE: Update DB_URL in ~/.secrets for a different database"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MCP setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Configured servers:"
claude mcp list 2>/dev/null | sed 's/^/    /' || true
echo ""
echo "  To verify: claude mcp list"
echo "  To remove: claude mcp remove <name>"
echo ""
