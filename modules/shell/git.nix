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
        core.pager = "delta";
        delta = {
          navigate = true;
          dark = true;
          line-numbers = true;
        };
        interactive.diffFilter = "delta --color-only";
        "filter \"lfs\"" = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
    };
  };
}
