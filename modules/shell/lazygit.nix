{ ... }:
{
  flake.modules.homeManager.lazygit = {
    programs.lazygit = {
      enable = true;
      settings = {
        git.pagers = [
          { pager = "delta --dark --paging=never"; }
        ];
      };
    };
  };
}
