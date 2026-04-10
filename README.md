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
    packages/       (extra homebrew casks, CLI tools)
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
}
```

3. Create `flake.nix`:

```nix
{
  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
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

## Updating shared config

```bash
cd base && git pull origin master && cd ..
git add base && git commit -m "Update base"
my-nix apply
```

## Daily usage (`my-nix`)

`my-nix` works from any directory.

| Command | Description |
|---------|-------------|
| `my-nix apply` | Apply nix-darwin configuration |
| `my-nix upgrade` | Update flake inputs + Homebrew, preview changes, apply |
| `my-nix cleanup` | Delete old generations, garbage collect, optimise store |
