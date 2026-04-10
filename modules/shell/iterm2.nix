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
        # Bundled with iTerm.app — always matches the installed version
        if [ -f /Applications/iTerm.app/Contents/Resources/iterm2_shell_integration.zsh ]; then
          source /Applications/iTerm.app/Contents/Resources/iterm2_shell_integration.zsh
        fi
      '';
    };
}
