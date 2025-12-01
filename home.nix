{ config, pkgs, ... }:

{
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "cp" "git" "gh" "nvm" "rvm" "ruby" "python" "docker" "docker-compose" "aws" ];
    };

    # Stuff that used to live in .zshrc (interactive shells)
    initContent = ''
      # https://docs.brew.sh/Shell-Completion
      export FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"

      # PATH setup
      export PATH="/usr/local/bin:$HOME/.rvm/bin:$PATH:$HOME/.local/bin"
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Locale
      export LANG=en_US.UTF-8

      export EDITOR='nvim'

      # iTerm2 integration (from YADR)
      if [ -f "$HOME/.yadr/zsh/iterm2_shell_integration.zsh" ]; then
        source "$HOME/.yadr/zsh/iterm2_shell_integration.zsh"
      fi

      # SDKMAN
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

      # GPG TTY fix
      export GPG_TTY=$(tty)

      # LM Studio CLI
      export PATH="$PATH:/Users/di/.lmstudio/bin"
    '';

    # Stuff that used to be in .zshenv (runs *very* early)
    envExtra = ''
      # Cargo environment
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi
    '';
  };

  home.packages = with pkgs; [
    git
    neovim
    ripgrep
    fd
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "Denys Yahofarov";
      email = "denyago@gmail.com";
    };
  };
}

