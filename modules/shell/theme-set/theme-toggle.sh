# Cycles auto -> light -> dark -> auto.
# THEME_SET is provided by theme-set.nix.

if [ "$(defaults read -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null || echo 0)" = 1 ]; then
  next=light
elif defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  next=auto
else
  next=dark
fi

exec "$THEME_SET" "$next"
