{ ... }:
{
  flake.modules.homeManager.lazygit = {
    programs.lazygit = {
      enable = true;
      settings = {
        git.paging = {
          colorArg = "always";
          pager = "bat --style=plain --color=always --pager=never -l diff";
        };
      };
    };
  };
}
