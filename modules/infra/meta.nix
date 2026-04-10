{ lib, ... }:
{
  options = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    email = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    nixDir = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "Absolute path to the overlay repo on disk";
    };
    fullName = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "Full name (used in git config, etc.)";
    };
    hostname = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "Machine hostname (used as darwinConfigurations key)";
    };
  };
}
