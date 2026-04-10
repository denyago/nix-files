{ lib, ... }:
{
  options = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
    };
    email = lib.mkOption {
      type = lib.types.singleLineStr;
    };
  };
}
