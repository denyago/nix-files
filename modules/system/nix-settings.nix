{ config, ... }:
{
  flake.modules.darwin.nix-settings = {
    system.stateVersion = 6;

    nix.settings.experimental-features = "nix-command flakes";
    nix.settings.extra-substituters = [ "https://cache.numtide.com" ];
    nix.settings.extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];

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
