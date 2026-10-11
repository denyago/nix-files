{ config, ... }:
{
  flake.modules.darwin.skhd = {
    # Needs the Accessibility permission on first run (System Settings > Privacy & Security)
    services.skhd = {
      enable = true;
      # launchd's PATH may not include the Home Manager profile, so use the absolute path
      skhdConfig = ''
        cmd + shift - t : /etc/profiles/per-user/${config.username}/bin/theme-toggle
      '';
    };
  };
}
