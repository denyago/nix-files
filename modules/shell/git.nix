{ config, ... }:
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings.user = {
        name = "Denys Yahofarov";
        email = config.email;
      };
    };
  };
}
