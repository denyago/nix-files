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
            pkgs.nvfetcher
          ];
          text = ''
            export MY_NIX_DIR="${config.nixDir}"
            export MY_NIX_BASE_CONTRIBUTOR_NAME="${config.baseContributor.name}"
            export MY_NIX_BASE_CONTRIBUTOR_EMAIL="${config.baseContributor.email}"
            export MY_NIX_BASE_CONTRIBUTOR_SSH_KEY="${config.baseContributor.sshKey}"
            ${builtins.readFile ./scripts/cli.sh}
          '';
        })
      ];
    };
}
