# Denys' Nix files

Supposed to be shared across multiple computers.
So far, MacOS only. And this is the upstream for my personal laptop and work laptop that has some overrides.

## Quick start
- `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --prefer-upstream-nix`
- `nix run "nixpkgs#hello"`
- `git clone ... `
- `cd nix-files`
- `git submodule update --init --recursive`
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

Afterwards:
- go to iTerm2 settings and select one of the Nix -controlled profiles as default

## Continue

- On every change: `sudo nix run darwin-rebuild switch --flake .`
- Update packages (Nix and Brew) `./update.sh`
