{ config, ... }:
{
  flake.modules.darwin.nix-settings = {
    system.stateVersion = 6;

    nix.settings.experimental-features = "nix-command flakes";

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [ "pnpm-9.15.9" ];

    security.pam.services.sudo_local.touchIdAuth = true;

    users.users.${config.username} = {
      home = "/Users/${config.username}";
      shell = "/bin/zsh";
    };

    system.primaryUser = config.username;
  };
}
