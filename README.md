Quick start:
- `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --prefer-upstream-nix`
- `nix run "nixpkgs#hello"`
- `git clone ... `
- `cd nix-files`
- edit the username and email in the `user-profile.nix`
- `sudo nix run nix-darwin -- switch --flake .`
- restart some MacOS processes:

```
# Restart Finder (for Finder, global domain, and file-related settings)
killall Finder

# Restart Dock (for Dock settings)
killall Dock

# Restart SystemUIServer (for global domain, menu bar, and UI-related preferences)
killall SystemUIServer

# Restart cfprefsd (preferences daemon, helps with caching issues)
killall cfprefsd
```

... or reboot.

And on every change: `sudo nix run darwin-rebuild switch --flake .`
