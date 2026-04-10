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
  };
}
