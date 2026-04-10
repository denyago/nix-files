{ config, ... }:
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      signing.format = null;
      settings.user = {
        name = config.fullName;
        email = config.email;
      };
    };
  };
}
