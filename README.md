Quick start:
- `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --prefer-upstream-nix`
- `nix run "nixpkgs#hello"`
- `git clone ... `
- `cd nix-files`
- `sudo nix run nix-darwin -- switch --flake .`

And on every change: `sudo nix run darwin-rebuild switch --flake .`
