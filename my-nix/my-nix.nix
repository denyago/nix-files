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
            export MY_NIX_BASE_CONTRIBUTOR_NAME="${config.baseContributor.name}"
            export MY_NIX_BASE_CONTRIBUTOR_EMAIL="${config.baseContributor.email}"
            ${builtins.readFile ./scripts/cli.sh}
          '';
        })
      ];
    };
}
