{ ... }:
{
  flake.modules.homeManager.zsh =
    { config, lib, ... }:
    {
      programs.zsh = {
        enable = true;

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [
            "cp"
            "git"
            "gh"
            "nvm"
            "rvm"
            "ruby"
            "python"
            "docker"
            "docker-compose"
            "aws"
          ];
        };

        initContent = lib.mkMerge [
          (lib.mkOrder 550 ''
            # Custom completions (my-nix) — must be before compinit
            fpath=("$HOME/.zsh/completions" $fpath)
          '')

          (lib.mkOrder 900 ''
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

            export PATH="${config.home.profileDirectory}/bin:$PATH"
          '')
        ];
      };
    };
}
