class DevTools < Formula
  desc "Personal developer environment — dotfiles and setup scripts"
  homepage "https://github.com/amcheste/dev_env"
  head "https://github.com/amcheste/dev_env.git", branch: "main"
  license "MIT"

  # ── CLI Utilities ────────────────────────────────────────────────────────
  depends_on "git"
  depends_on "gh"
  depends_on "vim"
  depends_on "fzf"
  depends_on "ripgrep"
  depends_on "fd"
  depends_on "bat"
  depends_on "tmux"
  depends_on "jq"
  depends_on "tree"
  depends_on "wget"

  # ── Languages ───────────────────────────────────────────────────────────
  depends_on "go"
  depends_on "pyenv"
  depends_on "nvm"
  depends_on "openjdk"
  depends_on "maven"

  # ── Cloud & DevOps ──────────────────────────────────────────────────────
  depends_on "kubernetes-cli"
  depends_on "kind"
  depends_on "helm"
  depends_on "terraform"
  depends_on "oci-cli"
  depends_on "doctl"

  # ── Databases ───────────────────────────────────────────────────────────
  depends_on "mongosh"

  def install
    # Install dotfiles to share dir so install-dotfiles.sh can find them
    pkgshare.install "dotfiles"

    # Expose setup scripts as runnable commands
    bin.install "scripts/install-dotfiles.sh"
    bin.install "scripts/setup-credentials.sh"
  end

  def caveats
    <<~EOS
      Developer environment installed! Complete setup with:

        1. Install dotfiles (symlinks ~/.vimrc and ~/.zshrc):
             install-dotfiles.sh

        2. Install Vim plugins:
             vim +PlugInstall +qall

        3. Set up API keys and credentials:
             setup-credentials.sh

      Dotfiles are stored at:
        #{opt_pkgshare}/dotfiles/
    EOS
  end

  test do
    assert_predicate pkgshare/"dotfiles/vimrc", :exist?
    assert_predicate pkgshare/"dotfiles/zshrc", :exist?
    assert_predicate pkgshare/"dotfiles/secrets.template", :exist?
  end
end
