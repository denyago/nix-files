{ ... }:
{
  flake.modules.darwin.homebrew = {
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
        "disk-inventory-x"

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
  };

  flake.modules.homeManager.homebrew-shell =
    { lib, ... }:
    {
      programs.zsh.initContent = lib.mkOrder 800 ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
      '';
    };
}
