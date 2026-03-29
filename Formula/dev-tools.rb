class DevTools < Formula
  desc "Personal developer environment — dotfiles and setup scripts"
  homepage "https://github.com/amcheste/dev_env"
  license "MIT"
  head "https://github.com/amcheste/dev_env.git", branch: "main"

  # Dependencies — must be alphabetical (enforced by brew style)
  depends_on "bat"
  depends_on "doctl"
  depends_on "fd"
  depends_on "fzf"
  depends_on "gh"
  depends_on "git"
  depends_on "go"
  depends_on "helm"
  depends_on "jq"
  depends_on "kind"
  depends_on "kubernetes-cli"
  depends_on "maven"
  depends_on "mongosh"
  depends_on "nvm"
  depends_on "oci-cli"
  depends_on "openjdk"
  depends_on "pyenv"
  depends_on "ripgrep"
  depends_on "terraform"
  depends_on "tmux"
  depends_on "tree"
  depends_on "vim"
  depends_on "wget"

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
    assert_path_exists pkgshare/"dotfiles/vimrc"
    assert_path_exists pkgshare/"dotfiles/zshrc"
    assert_path_exists pkgshare/"dotfiles/secrets.template"
  end
end
