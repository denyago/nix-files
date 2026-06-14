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
        onActivation.cleanup = "none";
        onActivation.extraEnv.HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS = "1";
        onActivation.extraEnv.HOMEBREW_NO_ENV_HINTS = "1";

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

      environment.variables.HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS = "1";
      environment.variables.HOMEBREW_NO_ENV_HINTS = "1";

      home-manager.users.${flakeConfig.username}.programs.zsh.initContent = lib.mkOrder 800 ''
        unset HOMEBREW_UPGRADE_GREEDY HOMEBREW_UPGRADE_GREEDY_CASKS
        export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
        export HOMEBREW_NO_ENV_HINTS=1
        eval "$(${config.homebrew.prefix}/bin/brew shellenv)"
        export FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
      '';

      system.activationScripts.postActivation.text = lib.mkAfter (
        if flakeConfig.homebrewCleanup == "none" then
          ""
        else if flakeConfig.homebrewCleanup == "zap" then
          ''
            # Homebrew cleanup without deprecated brew bundle --cleanup
            if [ -f "${config.homebrew.prefix}/bin/brew" ]; then
              PATH="${config.homebrew.prefix}/bin:$PATH" \
              sudo \
                --preserve-env=PATH \
                --user=${flakeConfig.username} \
                --set-home \
                env \
                HOMEBREW_NO_AUTO_UPDATE=1 \
                HOMEBREW_NO_ENV_HINTS=1 \
                HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 \
                ${config.homebrew.prefix}/bin/brew bundle cleanup \
                  --force \
                  --zap \
                  --file='${config.homebrew.brewfile}'
            fi
          ''
        else
          ''
            # Homebrew cleanup without deprecated brew bundle --cleanup
            if [ -f "${config.homebrew.prefix}/bin/brew" ]; then
              PATH="${config.homebrew.prefix}/bin:$PATH" \
              sudo \
                --preserve-env=PATH \
                --user=${flakeConfig.username} \
                --set-home \
                env \
                HOMEBREW_NO_AUTO_UPDATE=1 \
                HOMEBREW_NO_ENV_HINTS=1 \
                HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 \
                ${config.homebrew.prefix}/bin/brew bundle cleanup \
                  --force \
                  --file='${config.homebrew.brewfile}'
            fi
          ''
      );
    };
}
