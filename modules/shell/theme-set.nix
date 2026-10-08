{ ... }:
{
  flake.modules.homeManager.theme-set =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "theme-set";
          text = ''
            case "''${1:-}" in
              dark) dark=true ;;
              light) dark=false ;;
              *)
                echo "usage: theme-set dark|light" >&2
                exit 2
                ;;
            esac

            # iTerm2 (Theme: Automatic) swaps its (Light)/(Dark) palettes with macOS
            osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $dark"
            osascript -e "display notification \"$1\" with title \"Theme\""
          '';
        })
        (pkgs.writeShellApplication {
          name = "theme-toggle";
          text = ''
            osascript <<'EOF'
            tell application "System Events"
              tell appearance preferences
                set dark mode to not dark mode
                set isDark to dark mode
              end tell
            end tell
            if isDark then
              display notification "Dark" with title "Theme"
            else
              display notification "Light" with title "Theme"
            end if
            EOF
          '';
        })
      ];
    };
}
