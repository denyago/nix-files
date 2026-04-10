{ ... }:
{
  flake.modules.darwin.fonts =
    { pkgs, ... }:
    {
      fonts = {
        packages =
          let
            nerdFontsAll = pkgs.nerd-fonts;

            # Remove helper attrs that are not fonts
            nerdFontsOnly = builtins.removeAttrs nerdFontsAll [
              "override"
              "overrideDerivation"
              "recurseForDerivations"
            ];
          in
          builtins.attrValues nerdFontsOnly;
      };
    };
}
