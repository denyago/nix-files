{ ... }:
{
  flake.modules.homeManager.base = {
    home.stateVersion = "24.11";
    programs.home-manager.enable = true;
  };
}
