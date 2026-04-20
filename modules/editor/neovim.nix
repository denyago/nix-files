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

        # Prevent home-manager from writing init.lua to ~/.config/nvim/init.lua,
        # since the entire nvim config dir is managed via an out-of-store symlink.
        sideloadInitLua = true;
      };

      # LazyVim config linked from the nvim submodule in the base repo
      xdg.configFile."nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${baseDir}/modules/editor/nvim";
    };
}
