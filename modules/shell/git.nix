{ config, ... }:
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings.user = {
        name = config.fullName;
        email = config.email;
      };
    };
  };
}
