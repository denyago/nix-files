{ config, ... }:
{
  flake.modules.darwin.iterm2 = {
    system.defaults.CustomUserPreferences."com.googlecode.iterm2" = {
      DynamicProfilesPath = "/Users/${config.username}/.config/iterm2/DynamicProfiles";
    };
  };

  flake.modules.homeManager.iterm2 =
    { lib, ... }:
    {
      home.file.".config/iterm2/DynamicProfiles/denyago.json" = {
        source = ./iterm2/DynamicProfiles/denyago.json;
      };

      programs.zsh.initContent = lib.mkOrder 950 ''
        if [ -f "$HOME/.yadr/zsh/iterm2_shell_integration.zsh" ]; then
          source "$HOME/.yadr/zsh/iterm2_shell_integration.zsh"
        fi
      '';
    };
}
