# DBHub (https://github.com/bytebase/dbhub): token-efficient database MCP server.
# Not in nixpkgs, so it's built from source (see ./_package.nix).
#
# Declarative config: sources/configs below are rendered to TOML files under
# ~/.config/dbhub/<config>.toml. Point an MCP client at one of them, e.g.
#   claude mcp add --scope user db -- dbhub --transport stdio --config ~/.config/dbhub/default.toml
{ ... }:
{
  flake.modules.homeManager.dbhub =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.dbhub;
      toml = pkgs.formats.toml { };

      nonNull = lib.filterAttrs (_: v: v != null);

      sourceModule =
        { name, ... }:
        {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Include this source in generated configs. Disabled sources are skipped in every generated config.";
            };
            type = lib.mkOption {
              type = lib.types.enum [
                "postgres"
                "mysql"
                "mariadb"
                "sqlserver"
                "sqlite"
              ];
              default = "postgres";
            };
            host = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = 5432;
            };
            database = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            user = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            dsn = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Connection string. May reference env vars as ${"$"}{VAR}; never put secrets here, it ends up in the nix store.";
            };
            sslmode = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "disable"
                  "require"
                  "verify-ca"
                  "verify-full"
                ]
              );
              default = "require";
            };
            awsIam = {
              enable = lib.mkEnableOption "RDS IAM authentication (token signed from AWS credentials)";
              region = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              profile = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Named AWS profile (shared config, incl. SSO or credential_process). Null = default SDK credential chain.";
              };
            };
            lazy = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Defer connecting until the first query, so an unreachable database (e.g. VPN down) doesn't block server startup.";
            };
            readonly = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Reject mutating statements in execute_sql. A guardrail, not a permission boundary: also use a least-privilege DB role.";
            };
            maxRows = lib.mkOption {
              type = lib.types.ints.positive;
              default = 1000;
            };
            extraSettings = lib.mkOption {
              type = toml.type;
              default = { };
              description = "Extra keys merged into this [[sources]] entry verbatim.";
            };
          };
        };

      sourceEntry =
        id: s:
        nonNull {
          inherit id;
          inherit (s)
            type
            host
            port
            database
            user
            dsn
            sslmode
            ;
          lazy = if s.lazy then true else null;
          aws_iam_auth = if s.awsIam.enable then true else null;
          aws_region = if s.awsIam.enable then s.awsIam.region else null;
          aws_profile = if s.awsIam.enable then s.awsIam.profile else null;
        }
        // s.extraSettings;

      toolEntries =
        id: s: [
          {
            name = "execute_sql";
            source = id;
            inherit (s) readonly;
            max_rows = s.maxRows;
          }
          {
            name = "search_objects";
            source = id;
          }
        ];

      enabledSources = lib.filterAttrs (_: s: s.enable) cfg.sources;

      renderConfig =
        names:
        let
          # Disabled sources are skipped silently, so toggling `enable` is enough.
          picked = lib.filterAttrs (id: _: lib.elem id names) enabledSources;
        in
        toml.generate "dbhub.toml" {
          sources = lib.mapAttrsToList sourceEntry picked;
          tools = lib.concatLists (lib.mapAttrsToList toolEntries picked);
        };

      # `sources = null` means "every enabled source".
      configSources = c: if c.sources == null then lib.attrNames enabledSources else c.sources;
    in
    {
      options.programs.dbhub = {
        enable = lib.mkEnableOption "DBHub database MCP server";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.callPackage ./_package.nix {
            sources = pkgs.callPackage ../github-distributed/_sources/generated.nix { };
          };
          description = "DBHub package.";
        };

        sources = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule sourceModule);
          default = { };
          description = "Database connections, keyed by source id.";
        };

        configs = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.sources = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                default = null;
                description = "Source ids included in this config; null = all enabled sources.";
              };
              options.register = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Register this config as a Claude Code MCP server (needs programs.dbhub.claudeCode.enable).";
              };
            }
          );
          default = {
            default = { };
          };
          description = "Named config files written to ~/.config/dbhub/<name>.toml. Use several to switch sets of databases (e.g. with/without production) without a rebuild.";
        };

        claudeCode = {
          enable = lib.mkEnableOption "registering the generated configs as Claude Code user-scope MCP servers on every home-manager switch";
          package = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            description = "Claude Code package providing the `claude` CLI. Null = use `claude` from PATH.";
          };
          serverPrefix = lib.mkOption {
            type = lib.types.str;
            default = "db";
            description = "MCP servers are named <serverPrefix>-<config name>.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions =
          lib.concatLists (
            lib.mapAttrsToList (
              cname: c:
              map (sid: {
                assertion = cfg.sources ? ${sid};
                message = "programs.dbhub.configs.${cname} references undefined source '${sid}'.";
              }) (configSources c)
            ) cfg.configs
          )
          ++ lib.mapAttrsToList (sid: s: {
            assertion = !s.awsIam.enable || s.awsIam.region != null;
            message = "programs.dbhub.sources.${sid}: awsIam.region is required when awsIam.enable = true.";
          }) enabledSources;

        home.packages = [ cfg.package ];

        # Claude keeps MCP servers in the mutable ~/.claude.json, which can't be a nix
        # symlink, so register through the CLI. Idempotent: unchanged entries are left
        # alone, changed ones replaced, and stale ones with our prefix removed.
        home.activation.dbhubClaudeMcp = lib.mkIf cfg.claudeCode.enable (
          lib.hm.dag.entryAfter [ "linkGeneration" ] (
            let
              claude = if cfg.claudeCode.package == null then "claude" else lib.getExe cfg.claudeCode.package;
              jq = lib.getExe pkgs.jq;
              prefix = cfg.claudeCode.serverPrefix;
              registered = lib.filterAttrs (_: c: c.register) cfg.configs;
              entry = cname: {
                name = "${prefix}-${cname}";
                command = lib.getExe cfg.package;
                args = [
                  "--transport"
                  "stdio"
                  "--config"
                  "${config.xdg.configHome}/dbhub/${cname}.toml"
                ];
              };
              entries = map entry (lib.attrNames registered);
              names = map (e: e.name) entries;
              register = e: ''
                want=$(${jq} -cn --arg c ${lib.escapeShellArg e.command} '[$c, ${builtins.toJSON e.args}]')
                have=$(${jq} -c --arg n ${lib.escapeShellArg e.name} '.mcpServers[$n] // empty | [.command, .args]' "$claude_json" 2>/dev/null || true)
                if [[ "$have" != "$want" ]]; then
                  run ${claude} mcp remove --scope user ${lib.escapeShellArg e.name} >/dev/null 2>&1 || true
                  run ${claude} mcp add-json --scope user ${lib.escapeShellArg e.name} ${
                    lib.escapeShellArg (
                      builtins.toJSON {
                        type = "stdio";
                        inherit (e) command args;
                      }
                    )
                  } || echo "warning: could not register MCP server ${e.name} with Claude Code" >&2
                fi
              '';
            in
            ''
              claude_json="$HOME/.claude.json"
              wanted=" ${lib.concatStringsSep " " names} "
              if [[ -f "$claude_json" ]]; then
                for name in $(${jq} -r '.mcpServers // {} | keys[] | select(startswith("${prefix}-"))' "$claude_json"); do
                  if [[ "$wanted" != *" $name "* ]]; then
                    run ${claude} mcp remove --scope user "$name" || true
                  fi
                done
              fi
              ${lib.concatMapStrings register entries}
            ''
          )
        );

        xdg.configFile = lib.mapAttrs' (
          cname: c: lib.nameValuePair "dbhub/${cname}.toml" { source = renderConfig (configSources c); }
        ) cfg.configs;
      };
    };
}
