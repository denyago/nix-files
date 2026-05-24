{ config, inputs, ... }:
let
  flakeConfig = config;
in
{
  flake.modules.darwin.homebrew =
    { config, lib, ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      nix-homebrew = {
        enable = true;
        user = flakeConfig.username;
        enableRosetta = false;
        autoMigrate = true;
      };

      homebrew = {
        enable = true;
        onActivation.cleanup = "zap";

        casks = [
          # Core utilities
          "alt-tab"
          "bartender"
          "monitorcontrol"
          "rectangle"
          "the-unarchiver"
          "istat-menus"
          "grandperspective"

          # Browsers / general apps
          "brave-browser"
          "libreoffice"
          "spotify"

          # Dev tools
          "iterm2"
          "visual-studio-code"
          "docker-desktop"
          "obsidian"

          # QuickLook helpers
          "quicklook-csv"
          "quicklook-json"
        ];
      };

      home-manager.users.${flakeConfig.username}.programs.zsh.initContent = lib.mkOrder 800 ''
        eval "$(${config.homebrew.prefix}/bin/brew shellenv)"
        export FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
      '';
    };
}
