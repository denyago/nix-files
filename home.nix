{ config, pkgs, lib, userProfile, workInternal, ... }:

let
  # LazyVim starter config straight from GitHub
  lazyvim-config = builtins.fetchGit {
    url = "https://github.com/LazyVim/starter.git";
    rev = "803bc181d7c0d6d5eeba9274d9be49b287294d99";
  };
  baseCliTools = with pkgs; [
    ripgrep
    fd
    jq
    yq # python yq → provides `yq` and `xq` binaries
    tree
    unixtools.watch
    htop
    tmux
    tree
    unar

    # Network Tools
    rclone
    rsync
    wget
    httpyac

    git
    gh # GitHub CLI tool
    lazygit # Simple terminal UI for git commands
    graphviz

    # Languages
    nodejs_24
    yarn

    bat # Cat(1) clone with syntax highlighting and Git integration
    exiftool # Tool to read, write and edit EXIF meta information
    gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
    pinentry-curses # Passphrase entry dialog utilizing the Assuan protocol
    pinentry_mac

    lazydocker # Simple terminal UI for both docker and docker-compose
    dive # Tool for exploring each layer in a docker image
    k9s

    awscli
    go-task

    # LazyVim utilities
    fzf
    ast-grep
    neovide
    lua
    imagemagick
    ghostscript
    shfmt
    stylua
    nodePackages.prettier
    tree-sitter
    lua-language-server
  ];
  homeOnlyCliTools = with pkgs; [
    # Core utilities
    mc
    mtr
    overmind
    smartmontools

    # Languages
    go
    jdk25_headless
    kotlin
    rustup

    # Language tools
    gradle
    jmeter
    pnpm
    shellcheck

    # Security / encryption / OSINT
    gocryptfs
    nmap
    gallery-dl
    yt-dlp
    zbar

    # Mechanical keyboards
    qmk
  ];
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
      export PATH="/usr/local/bin:$HOME/.rvm/bin:$PATH:$HOME/.local/bin:$HOME/.yarn/bin"
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Locale
      export LANG=en_US.UTF-8

      # iTerm2 integration (from YADR)
      if [ -f "$HOME/.yadr/zsh/iterm2_shell_integration.zsh" ]; then
        source "$HOME/.yadr/zsh/iterm2_shell_integration.zsh"
      fi

      ${lib.optionalString userProfile.isHomeProfile ''
        # GPG TTY fix
        export GPG_TTY=$(tty)

        # LM Studio CLI
        export PATH="$PATH:$HOME/.lmstudio/bin"
      ''}

      export PATH="${config.home.profileDirectory}/bin:$PATH"
    '';

    # Stuff that used to be in .zshenv (runs *very* early)
    envExtra = lib.optionalString userProfile.isHomeProfile ''
      # Cargo environment
      if [ -f "$HOME/.cargo/env" ]; then
      . "$HOME/.cargo/env"
      fi
    '';
  };

  home.packages =
    baseCliTools
    ++ lib.optionals userProfile.isHomeProfile homeOnlyCliTools
    ++ workInternal.packages;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Denys Yahofarov";
      email = userProfile.email;
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
     git
     ripgrep
     fd
    ];
  };

  
  # >>> LazyVim <<<
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-files/nvim";
}

