# Architecture

This repo uses the [Dendritic pattern](https://github.com/vic/dendritic) -- a Nixpkgs module system convention where every `.nix` file is a top-level module and each file implements a single feature.

## Principles

1. **One feature per file.** Each `.nix` file under `modules/` declares exactly one concern. Files can be renamed or moved freely -- `import-tree` discovers them by scanning the directory.

2. **No conditionals for environment differences.** Instead of `if isHomeProfile then ...`, environment-specific packages live in separate overlay repos. The base repo contains only what's shared across all machines.

3. **Overlay composition via submodule.** Overlay repos (home, work) add this repo as a git submodule at `base/` and layer extra modules on top. The Nix module system merges everything automatically.

4. **Auto-collection.** `machine.nix` uses `lib.attrValues config.flake.modules.darwin` to collect all registered feature modules. Adding a new module file is enough -- no import list to maintain.

5. **No `specialArgs`.** Shared data (username, email, paths) flows through flake-parts `config` options, not through `specialArgs` or function arguments.

## Directory layout

```
modules/
  infra/                    Infrastructure / wiring
    flake-parts.nix         Imports flake-parts flakeModules.modules
    systems.nix             Supported systems (aarch64-darwin)
    meta.nix                Declares shared options: username, email, nixDir
    darwin-provider.nix     configurations.darwin option -> flake.darwinConfigurations
    machine.nix             Consumer: composes the darwin config from all modules
    home-manager-base.nix   Shared HM settings (stateVersion, enable)

  system/                   macOS system-level configuration
    nix-settings.nix        Nix daemon settings, nixpkgs config, Touch ID sudo
    macos-defaults.nix      NSGlobalDomain, Finder, Dock, screenshots, etc.
    macos-activation.nix    Power management, boot chime activation scripts
    macos-privacy.nix       Disable Apple Intelligence, Siri, Spotlight suggestions

  packages/                 Package management
    homebrew.nix            Shared Homebrew casks and brews
    cli-tools.nix           Shared CLI tools (ripgrep, git, nodejs, go, etc.)
    fonts.nix               Nerd Fonts
    github-distributed/     Pre-built binaries fetched from GitHub releases (see below)
      nvfetcher.toml        Source specs (one [entry] per tool)
      _sources/             Generated lockfile — committed to git, do not edit
      <tool>.nix            One module file per tool

  shell/                    Shell and terminal
    zsh.nix                 Zsh + oh-my-zsh configuration
    git.nix                 Git user configuration (uses config.email)
    iterm2.nix              iTerm2 dynamic profiles + darwin preferences
    iterm2/                 iTerm2 profile JSON files

  editor/                   Code editors
    neovim.nix              Neovim + LazyVim (symlinks to nvim/ submodule)
    nvim/                   Git submodule: LazyVim config

my-nix/                     CLI tool (top-level, almost standalone)
  my-nix.nix                Flake-parts module: builds + installs the CLI
  scripts/
    cli.sh                  Main script (apply, commit, upgrade, cleanup)
    update.sh               Upgrade logic (pull submodules + flake update + brew + preview)
    commit.sh               Inside-out commit & push flow (nvim → base → overlay)
  completions/
    _my-nix                 Zsh completions
```

## How modules work

### Feature modules

Each feature module is a flake-parts module that registers lower-level (darwin or home-manager) config under `flake.modules`:

```nix
# modules/packages/cli-tools.nix
{ ... }:
{
  flake.modules.homeManager.cli-tools = { pkgs, ... }: {
    home.packages = with pkgs; [ ripgrep fd jq ... ];
  };
}
```

```nix
# modules/system/macos-defaults.nix
{ ... }:
{
  flake.modules.darwin.macos-defaults = {
    system.defaults.dock.autohide = true;
    # ...
  };
}
```

A single file can register both darwin and home-manager modules (see `iterm2.nix`).

### Provider (`darwin-provider.nix`)

Declares a `configurations.darwin` option and maps it to `flake.darwinConfigurations`:

```nix
options.configurations.darwin = lib.mkOption {
  type = lib.types.lazyAttrsOf (lib.types.submodule {
    options.module = lib.mkOption { type = lib.types.deferredModule; };
  });
};
```

### Consumer (`machine.nix`)

Collects all registered modules and composes the final darwin configuration:

```nix
configurations.darwin.${config.hostname}.module = {
  imports = lib.attrValues config.flake.modules.darwin;
  home-manager.users.${config.username} = {
    imports = lib.attrValues config.flake.modules.homeManager;
  };
};
```

### Meta options (`meta.nix`)

Declares options that all modules can read:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `username` | string | — | macOS username |
| `fullName` | string | — | Full name (git config, etc.) |
| `email` | string | — | Git email |
| `nixDir` | string | — | Absolute path to the overlay repo |
| `hostname` | string | — | Machine hostname (darwinConfigurations key) |
| `baseContributor.name` | string | `""` | Git author name for base/nvim commits |
| `baseContributor.email` | string | `""` | Git author email for base/nvim commits |
| `baseContributor.sshKey` | string | `""` | SSH key path for pushing to base/nvim repos |

These are set by `identity.nix` in each overlay repo. The `baseContributor` options are useful when the overlay uses a different git identity than the base repo (e.g. work email vs personal email).

## Overlay repos

An overlay repo has this structure:

```
my-overlay/
  flake.nix            # dual import-tree: base/modules + ./modules
  base/                # git submodule -> this repo
  modules/
    identity.nix       # sets username, email, nixDir
    packages/          # extra homebrew casks, CLI tools
    shell/             # extra shell config
```

The overlay's `flake.nix` imports both module trees:

```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      (inputs.import-tree ./base/modules)
      (inputs.import-tree ./base/my-nix)
      (inputs.import-tree ./modules)
    ];
  };
```

Overlay modules register under unique attribute keys (e.g. `cli-tools-extra`, `homebrew-extra`) so they don't collide with base module keys.

## Pinning external binaries with nvfetcher

[nvfetcher](https://github.com/berberman/nvfetcher) tracks upstream releases (GitHub tags, PyPI, etc.) and generates a `_sources/generated.nix` lockfile that derivations read instead of hardcoded hashes.

### When to use it

Use `nvfetcher` for packages that aren't in nixpkgs and are distributed as pre-built binaries (e.g. a GitHub release asset). Don't use it for things already in nixpkgs — just take the package from `pkgs` directly.

### Convention: `github-distributed/` directory

Pre-built GitHub release binaries live under a `github-distributed/` subdirectory inside any `packages/` directory (base or overlay). This keeps the tooling (`nvfetcher.toml`, `_sources/`) and the tool modules co-located and clearly separated from nixpkgs-sourced packages.

```
packages/
  cli-tools.nix
  github-distributed/
    nvfetcher.toml          ← one [entry] per tool
    _sources/
      generated.nix         ← committed lockfile, do not edit manually
      generated.json
    my-tool.nix             ← one .nix file per tool
```

`import-tree` skips `_`-prefixed directories, so `_sources/` is never accidentally imported.

### Adding a new tool

1. Add an entry to `github-distributed/nvfetcher.toml`:

```toml
[my-tool]
src.github = "owner/repo"
src.tag = "latest"
fetch.url = "https://github.com/owner/repo/releases/download/$ver/my-tool-macos-aarch64"
fetch.url-template = true
```

2. Regenerate the lockfile:

```bash
cd modules/packages/github-distributed
nvfetcher -c nvfetcher.toml -o _sources
```

3. Create `github-distributed/my-tool.nix`:

```nix
{ ... }:
{
  flake.modules.homeManager.my-tool =
    { pkgs, ... }:
    let
      sources = pkgs.callPackage ./_sources/generated.nix { };
      my-tool = pkgs.stdenv.mkDerivation {
        inherit (sources.my-tool) pname version src;
        dontUnpack = true;
        installPhase = "install -Dm755 $src $out/bin/my-tool";
      };
    in
    { home.packages = [ my-tool ]; };
}
```

4. Commit `nvfetcher.toml`, `_sources/generated.nix`, and `my-tool.nix` together — the lockfile belongs in git, same as `flake.lock`.

### Auto-update

`my-nix upgrade` automatically runs nvfetcher for every `nvfetcher.toml` found in the overlay repo before building. No manual step needed after the initial setup.

## Key technologies

| Technology | Role |
|------------|------|
| [flake-parts](https://flake.parts) | Top-level flake configuration framework |
| [import-tree](https://github.com/vic/import-tree) | Auto-import all `.nix` files from a directory tree |
| [nix-darwin](https://github.com/nix-darwin/nix-darwin) | macOS system configuration |
| [home-manager](https://github.com/nix-community/home-manager) | User-level dotfile and package management |
| `deferredModule` | Nixpkgs type for modules that can be merged before evaluation |
