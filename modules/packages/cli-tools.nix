{ ... }:
{
  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ripgrep
        fd
        jq
        yq
        tree
        unixtools.watch
        htop
        tmux
        unar

        # Network Tools
        rclone
        rsync
        wget
        httpyac

        git
        gh
        lazygit
        graphviz
        poppler-utils
        yt-dlp

        # Languages
        nodejs_24
        yarn
        ruby_3_4
        go
        rustup

        bat
        exiftool
        gnupg
        pinentry-curses
        pinentry_mac
        marp-cli

        lazydocker
        dive
        k9s
        kubernetes-helm
        duckdb

        awscli
        go-task

        # LazyVim utilities
        fzf
        ast-grep
        tree-sitter
        imagemagick
        ghostscript
        ## JS/TS/JSON/...
        prettier
        ## Shell
        shfmt
        ## Lua
        lua
        stylua
        lua-language-server
        ## Nix LSP + formatter
        nil
        nixfmt
        ## NeoVIM GUI App
        neovide
      ];
    };
}
