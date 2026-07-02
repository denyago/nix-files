# denyago-nix-files

Shared nix-darwin + Home Manager base modules using the [Dendritic pattern](https://github.com/vic/dendritic).

This repo is a **library of feature modules**. It doesn't build a machine on its own -- it's consumed as a git submodule by environment-specific overlay repos (home laptop, work laptop, etc.) that provide identity and extra packages.

## How it works

```
overlay repo (home or work)
  flake.nix ------> import-tree ./base/modules   (shared features)
  |                  import-tree ./modules         (overlay-specific)
  |
  base/  <--- git submodule pointing here
  modules/
    identity.nix    (username, email, nixDir)
    packages/       (extra Homebrew casks, Nix GUI apps, CLI tools)
    ...
```

See [doc/architecture.md](doc/architecture.md) for full details.

## Quick start: creating a new overlay

1. Create a new repo and add this one as a submodule:

```bash
mkdir my-nix && cd my-nix && git init
git submodule add <this-repo-url> base
git submodule update --init --recursive
```

2. Create `modules/identity.nix`:

```nix
{
  username = "myuser";
  fullName = "My Name";
  email = "me@example.com";
  nixDir = "/Users/myuser/my-nix";
  hostname = "My-MacBook-Pro";

  # Optional: git identity for commits to base and nvim submodules.
  # When set, `my-nix commit` uses this identity for base/nvim repos
  # and the default git config for the overlay repo.
  # baseContributor.name = "My Name";
  # baseContributor.email = "me@example.com";
  # baseContributor.sshKey = "$HOME/.ssh/my_key";
}
```

3. Create `flake.nix`:

```nix
{
  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        (inputs.import-tree ./base/modules)
        (inputs.import-tree ./base/my-nix)
        (inputs.import-tree ./modules)
      ];
    };
}
```

4. Build and apply:

```bash
nix flake lock
sudo nix run nix-darwin -- switch --flake .
```

5. Restart macOS services or reboot:

```bash
killall Finder Dock SystemUIServer cfprefsd
```

6. In iTerm2, select one of the Nix-managed profiles as default.

## Adding overlay-specific packages

Create modules under `modules/` in your overlay repo. Each module registers features under unique attribute keys:

```nix
# modules/packages/cli-tools.nix
{ ... }:
{
  flake.modules.homeManager.cli-tools-extra = { pkgs, ... }: {
    home.packages = with pkgs; [ some-tool another-tool ];
  };
}
```

Attribute keys must be unique across base + overlay (e.g. `cli-tools-extra`, not `cli-tools`).

### macOS GUI apps with Nix

Nix-managed macOS apps should be declared through the shared `my.guiApps` option from overlay-specific Darwin modules:

```nix
# modules/packages/gui-apps.nix
{ ... }:
{
  flake.modules.darwin.gui-apps-extra = { pkgs, ... }: {
    my.guiApps = with pkgs; [ librewolf ];
  };
}
```

The base module adds `my.guiApps` to `environment.systemPackages`. nix-darwin then collects package `Applications/*.app` bundles and syncs them into `/Applications/Nix Apps` during activation.

Use this for apps that exist in nixpkgs and produce a usable macOS app bundle. Keep Homebrew casks for apps that are unavailable in nixpkgs, require Homebrew-specific installers, or need vendor-managed background services.

When moving an app from Homebrew casks to Nix:

1. Add the package to `my.guiApps` and apply the configuration.
2. Verify the app launches from `/Applications/Nix Apps`.
3. Remove the cask from `homebrew.casks`.
4. Uninstall the old cask manually if you need to avoid `brew zap` deleting app data.
5. Re-pin Dock items or reset default apps if macOS still points to the old `/Applications/<App>.app` path.

## Daily usage (`my-nix`)

`my-nix` works from any directory.

| Command | Description |
|---------|-------------|
| `my-nix apply` | Apply nix-darwin configuration, then commit & push |
| `my-nix commit` | Commit & push changes across nvim, base, and overlay repos |
| `my-nix upgrade` | Pull submodules, update packages/Homebrew within the current release, apply, then commit & push |
| `my-nix do-release-upgrade <release|latest>` | Bump nixpkgs, nix-darwin, and Home Manager to a release train or to `latest`, then run the upgrade flow |
| `my-nix cleanup` | Delete old generations, garbage collect, optimise store |

### Commit flow

`my-nix commit` (also runs automatically after `apply` and `upgrade`) walks through repos inside-out:

1. **nvim** — the LazyVim config submodule
2. **base** — the shared modules submodule
3. **overlay** — your environment-specific repo

For each dirty repo it shows a diff summary, prompts for a commit message (with a sensible default), and offers to push. If `baseContributor` is configured in `identity.nix`, commits to nvim and base use that identity and SSH key, while the overlay uses your default git config.
