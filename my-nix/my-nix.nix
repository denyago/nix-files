{ ... }:
{
  flake.modules.homeManager.my-nix =
    { pkgs, ... }:
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
          text = builtins.readFile ./cli.sh;
        })
      ];
    };
}
