{ ... }:
{
  flake.modules.darwin.macos-activation = {
    system.activationScripts.powerAndTm.text = ''
      pmset -a lidwake 1
      pmset -a autorestart 1
      pmset -a standbydelay 86400

      /usr/bin/pmset -b displaysleep 30 sleep 30
      /usr/bin/pmset -c displaysleep 30 sleep 30

      # Disable Time Machine local snapshots
      if command -v tmutil >/dev/null 2>&1; then
        tmutil disable || true
      fi
    '';

    system.activationScripts.nvramBootChime.text = ''
      # Disable boot chime; ignore errors on locked-down systems
      /usr/sbin/nvram SystemAudioVolume=" " || true
    '';
  };
}
