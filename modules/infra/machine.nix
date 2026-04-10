{ config, lib, ... }:
let
  darwin = config.flake.modules.darwin;
  hm = config.flake.modules.homeManager;
in
{
  configurations.darwin.${config.hostname}.module = {
    imports = lib.attrValues darwin;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      users.${config.username} = {
        imports = lib.attrValues hm;
      };
    };
  };
}
