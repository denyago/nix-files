{ config, ... }:
{
  flake.modules.darwin.iterm2 = {
    system.defaults.CustomUserPreferences."com.googlecode.iterm2" = {
      DynamicProfilesPath = "/Users/${config.username}/.config/iterm2/DynamicProfiles";
    };
  };

  flake.modules.homeManager.iterm2 = {
    home.file.".config/iterm2/DynamicProfiles/denyago.json" = {
      source = ./iterm2/DynamicProfiles/denyago.json;
    };
  };
}
