{ ... }:
{
  # oh-my-zsh runs its own compinit; the one nix-darwin puts in /etc/zshrc is a
  # redundant second compaudit + compinit on every shell start (~0.2s).
  flake.modules.darwin.zsh = {
    programs.zsh.enableCompletion = false;
  };

  flake.modules.homeManager.zsh =
    { config, lib, ... }:
    {
      programs.zsh = {
        enable = true;

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          # Skip compaudit (~0.2s per start): it re-audits every fpath dir, and
          # the nix/homebrew dirs are managed by us anyway.
          extraConfig = ''
            ZSH_DISABLE_COMPFIX=true
          '';
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
          (lib.mkOrder 900 ''
            export PATH="$PATH:$HOME/.local/bin"
            export LANG=en_US.UTF-8
          '')

          (lib.mkOrder 1100 ''
            export PATH="${config.home.profileDirectory}/bin:$PATH"
          '')
        ];
      };
    };
}
