{ ... }:
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

      # LazyVim config linked from the nvim submodule
      xdg.configFile."nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-files/nvim";
    };
}
