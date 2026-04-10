{ config, ... }:
{
  flake.modules.homeManager.my-nix =
    { pkgs, lib, ... }:
    {
      home.file.".zsh/completions/_my-nix" = {
        source = ./_my-nix;
      };

      home.packages = [
        (pkgs.writeShellApplication {
          name = "my-nix";
          runtimeInputs = [
            pkgs.git
            pkgs.nix
          ];
          text = ''
            export MY_NIX_DIR="${config.nixDir}"
            ${builtins.readFile ./cli.sh}
          '';
        })
      ];
    };
}
