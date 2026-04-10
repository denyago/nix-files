{ config, ... }:
{
  flake.modules.homeManager.my-nix =
    { pkgs, lib, ... }:
    {
      home.file.".zsh/completions/_my-nix" = {
        source = ./completions/_my-nix;
      };

      programs.zsh.initContent = lib.mkOrder 550 ''
        fpath=("$HOME/.zsh/completions" $fpath)
      '';

      home.packages = [
        (pkgs.writeShellApplication {
          name = "my-nix";
          runtimeInputs = [
            pkgs.git
            pkgs.nix
          ];
          text = ''
            export MY_NIX_DIR="${config.nixDir}"
            ${builtins.readFile ./scripts/cli.sh}
          '';
        })
      ];
    };
}
