{ ... }:
{
  flake.modules.homeManager.theme-set =
    { pkgs, ... }:
    let
      theme-set = pkgs.writeShellApplication {
        name = "theme-set";
        runtimeInputs = [ pkgs.python3 ];
        runtimeEnv.SET_AUTO_PY = "${./theme-set/set-auto.py}";
        text = builtins.readFile ./theme-set/theme-set.sh;
      };

      theme-toggle = pkgs.writeShellApplication {
        name = "theme-toggle";
        runtimeEnv.THEME_SET = "${theme-set}/bin/theme-set";
        text = builtins.readFile ./theme-set/theme-toggle.sh;
      };
    in
    {
      home.packages = [
        theme-set
        theme-toggle
      ];
    };
}
