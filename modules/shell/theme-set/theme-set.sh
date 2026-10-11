# Usage: theme-set dark|light|auto
# iTerm2 (Theme: Automatic) swaps its (Light)/(Dark) palettes with macOS.
# SET_AUTO_PY is provided by theme-set.nix.

set_auto() {
  python3 "$SET_AUTO_PY" "$1" ||
    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool "$1"
}

set_dark_mode() {
  osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $1"
}

case "${1:-}" in
  dark)
    set_auto false
    set_dark_mode true
    label="Dark"
    ;;
  light)
    set_auto false
    set_dark_mode false
    label="Light"
    ;;
  auto)
    set_auto true
    sleep 1
    if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
      label="Auto (Dark)"
    else
      label="Auto (Light)"
    fi
    ;;
  *)
    echo "usage: theme-set dark|light|auto" >&2
    exit 2
    ;;
esac

osascript -e "display notification \"$label\" with title \"Theme\""
