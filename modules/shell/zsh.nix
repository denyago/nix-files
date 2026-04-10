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
          (lib.mkOrder 900 ''
            export PATH="/usr/local/bin:$PATH:$HOME/.local/bin"
            export LANG=en_US.UTF-8
          '')

          (lib.mkOrder 1100 ''
            export PATH="${config.home.profileDirectory}/bin:$PATH"
          '')
        ];
      };
    };
}
