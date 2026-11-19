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
            }
          );
          default = {
            default = { };
          };
          description = "Named config files written to ~/.config/dbhub/<name>.toml. Use several to switch sets of databases (e.g. with/without production) without a rebuild.";
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

        xdg.configFile = lib.mapAttrs' (
          cname: c: lib.nameValuePair "dbhub/${cname}.toml" { source = renderConfig (configSources c); }
        ) cfg.configs;
      };
    };
}
