{ config, ... }:
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      signing.format = null;
      settings = {
        user = {
          name = config.fullName;
          email = config.email;
        };
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
    };
  };
}
