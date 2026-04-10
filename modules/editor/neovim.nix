{ config, ... }:
let
  baseDir = "${config.nixDir}/base";
in
{
  flake.modules.homeManager.neovim =
    { config, pkgs, ... }:
    {
      programs.neovim = {
        enable = true;

        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        defaultEditor = true;

        withPython3 = true;
        withNodeJs = true;
        withRuby = true;

        extraPackages = with pkgs; [
          git
          ripgrep
          fd
        ];
      };

      # LazyVim config linked from the nvim submodule in the base repo
      xdg.configFile."nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${baseDir}/modules/editor/nvim";
    };
}
