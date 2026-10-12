{ ... }:
{
  flake.modules.homeManager.graphify-integration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.graphify;
    in
    {
      options.programs.graphify = {
        enable = lib.mkEnableOption "Graphify assistant integration";

        assistant = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "opencode"
              "claude"
            ]
          );
          default = null;
          description = "Assistant to configure with the global Graphify integration; opencode uses the v2-compatible Agent Skill.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.assistant != null;
            message = "programs.graphify.assistant must be set when programs.graphify.enable is true.";
          }
        ];
        home.packages = [ pkgs.graphify ];
        home.activation.graphifyInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          if [[ -n "''${DRY_RUN:-}" ]]; then
            echo "Skipping Graphify install in Home Manager dry-run mode."
          else
            (
              cd "$HOME"
              if [[ ${lib.escapeShellArg cfg.assistant} == opencode ]]; then
                ${pkgs.graphify}/bin/graphify install --platform agents
                rm -f "$HOME/.config/opencode/plugins/graphify.js" "$HOME/.opencode/plugins/graphify.js"
              else
                ${pkgs.graphify}/bin/graphify install --platform claude
              fi
            )
          fi
        '';
      };
    };
}
