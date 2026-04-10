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
}
