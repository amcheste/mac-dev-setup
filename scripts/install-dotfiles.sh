#!/usr/bin/env bash
# install-dotfiles.sh
# Symlinks dotfiles from this repo (or brew pkgshare) into $HOME.
# Idempotent — safe to run multiple times. Existing real files are backed up
# once; subsequent runs detect correct symlinks and skip them.
set -euo pipefail

# ── Locate dotfiles ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# If running after `brew install dev-tools`, dotfiles live in pkgshare
if command -v brew &>/dev/null; then
    BREW_DOTFILES="$(brew --prefix)/share/dev-tools/dotfiles"
    if [[ -d "$BREW_DOTFILES" ]]; then
        DOTFILES_DIR="$BREW_DOTFILES"
    fi
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "ERROR: dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

echo "Installing dotfiles from: $DOTFILES_DIR"
echo ""

# ── Helpers ───────────────────────────────────────────────────────────────────

# safe_backup <path>
# Moves <path> to <path>.bak. If <path>.bak already exists, uses a timestamp
# suffix instead to avoid silently overwriting a previous backup.
safe_backup() {
    local target="$1"
    local bak="${target}.bak"
    if [[ -e "$bak" ]]; then
        bak="${target}.$(date +%Y%m%d%H%M%S).bak"
    fi
    mv "$target" "$bak"
    echo "  Backed up    $target  →  $bak"
}

# backup_and_link <source> <target>
# Links target → source. Skips if already correctly linked. Backs up real
# files before replacing. Replaces stale or wrong symlinks silently.
backup_and_link() {
    local source="$1"
    local target="$2"

    # Already pointing to the right place — nothing to do
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        echo "  Up to date   $target  ✓"
        return
    fi

    # Real file exists — back it up before replacing
    if [[ -e "$target" && ! -L "$target" ]]; then
        safe_backup "$target"
    elif [[ -L "$target" ]]; then
        # Stale or wrong symlink — remove silently
        rm "$target"
    fi

    ln -sf "$source" "$target"
    echo "  Linked       $target  →  $source"
}

# ── Symlink dotfiles ─────────────────────────────────────────────────────────
backup_and_link "$DOTFILES_DIR/zshrc"  "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/vimrc"  "$HOME/.vimrc"

# ── Secrets template (only if ~/.secrets doesn't exist) ─────────────────────
if [[ ! -f "$HOME/.secrets" ]]; then
    echo ""
    echo "  Creating     ~/.secrets  (from template — fill in your values)"
    cp "$DOTFILES_DIR/secrets.template" "$HOME/.secrets"
    chmod 600 "$HOME/.secrets"
else
    echo "  Up to date   ~/.secrets  ✓"
fi

# ── vim-plug bootstrap ───────────────────────────────────────────────────────
VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [[ ! -f "$VIM_PLUG" ]]; then
    echo ""
    echo "  Installing vim-plug..."
    curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "  vim-plug installed ✓"
else
    echo "  Up to date   vim-plug  ✓"
fi

# ── Claude Code skills ────────────────────────────────────────────────────────
# Symlinks each skill directory from claude-skills/ into ~/.claude/skills/.
# New skills added to the repo are picked up automatically on re-runs.
# Existing user-created skill directories are backed up, not destroyed.
SKILLS_SRC_DIR="$REPO_DIR/claude-skills"
SKILLS_DEST_DIR="$HOME/.claude/skills"

if [[ -d "$SKILLS_SRC_DIR" ]]; then
    echo ""
    mkdir -p "$SKILLS_DEST_DIR"
    for skill_dir in "$SKILLS_SRC_DIR"/*/; do
        skill_name="$(basename "$skill_dir")"
        skill_src="${skill_dir%/}"   # strip trailing slash for clean symlink
        dest="$SKILLS_DEST_DIR/$skill_name"

        # Already pointing to the right place — nothing to do
        if [[ -L "$dest" && "$(readlink "$dest")" == "$skill_src" ]]; then
            echo "  Up to date   $dest  ✓"
            continue
        fi

        # Stale or wrong symlink — replace silently
        if [[ -L "$dest" ]]; then
            rm "$dest"
        # Real directory the user may have created — back it up, don't destroy it
        elif [[ -d "$dest" ]]; then
            safe_backup "$dest"
        fi

        ln -sf "$skill_src" "$dest"
        echo "  Linked       $dest  →  $skill_src"
    done
    echo "  Claude Code skills installed ✓  (invoke with /publish-release)"
fi

echo ""
echo "Done!"
echo "  • New terminal or 'source ~/.zshrc' to reload shell"
echo "  • 'vim +PlugInstall +qall' to install Vim plugins (first run only)"
echo "  • 'bash scripts/setup-credentials.sh' to configure ~/.secrets"
