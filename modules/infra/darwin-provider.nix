{ lib, config, inputs, ... }:
{
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };

  config.flake.darwinConfigurations = lib.mapAttrs (
    name:
    { module }:
    inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        module
        inputs.home-manager.darwinModules.home-manager
      ];
    }
  ) config.configurations.darwin;
}
