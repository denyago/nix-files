{ config, pkgs, ... }:

let
  # LazyVim starter config straight from GitHub
  lazyvim-config = builtins.fetchGit {
    url = "https://github.com/LazyVim/starter.git";
    rev = "803bc181d7c0d6d5eeba9274d9be49b287294d99";
  };
in
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

      export PATH="${config.home.profileDirectory}/bin:$PATH"
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

  programs.neovim = {
    enable = true;

    # Have `vi`, `vim`, `vimdiff` all point to neovim
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Make nvim the default editor ($EDITOR)
    defaultEditor = true;

    # Enable language bindings
    withPython3 = true;
    withNodeJs  = true;
    withRuby    = true;

    # Extra tools available *inside* Neovim (for grep, etc.)
    extraPackages = with pkgs; [
      ripgrep
      fd
      git
    ];
  };

  
  # >>> LazyVim here <<<
  # This will put the LazyVim starter config into ~/.config/nvim
  xdg.configFile."nvim" = {
    source = lazyvim-config;
    # If you ever get clashes, you can uncomment:
    # force = true;
  };
}

