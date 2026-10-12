{ inputs, ... }:
{
  flake.modules.darwin.graphify-overlay = {
    nixpkgs.overlays = [
      (final: _prev: {
        graphify = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.graphify;
      })
    ];
  };
}
