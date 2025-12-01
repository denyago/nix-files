{
  description = "nix-darwin + Home Manager system for denyago";

  inputs = {
    # You used unstable, keeping it:
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations."Denyss-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      inherit system;

      modules = [
        ./darwin.nix

        # Home-manager as a nix-darwin module
        home-manager.darwinModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Back up existing dotfiles instead of refusing to overwrite
          home-manager.backupFileExtension = "bak";

          home-manager.users.di = import ./home.nix;
        }
      ];
    };
  };
}

