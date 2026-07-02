{ ... }:
{
  flake.modules.darwin.gui-apps =
    { config, lib, ... }:
    {
      options.my.guiApps = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          macOS GUI applications installed with Nix and exposed through
          nix-darwin's /Applications/Nix Apps activation step.
        '';
      };

      config = {
        environment.systemPackages = config.my.guiApps;
      };
    };
}
