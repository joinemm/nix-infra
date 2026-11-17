{
  config,
  lib,
  mkBackup,
  ...
}:
let
  # Keep in sync with the forced command in CoreELEC's /storage/.ssh/authorized_keys.
  # Native CoreELEC backup directories plus /flash for separate boot-file recovery.
  # GUI restore needs a YYYYMMDDhhmmss.tar copy with the extra flash/ entries removed.
  backupCommand = ''
    set -e
    archive=/storage/backup/coreelec.tar

    tar -C / -cf "$archive.partial" \
      storage/.kodi \
      storage/.config \
      storage/.cache \
      storage/.ssh \
      flash

    mv "$archive.partial" "$archive"
    cat "$archive"
  '';
in
{
  sops.secrets.kodi_ssh_private_key = { };

  programs.ssh = {
    knownHosts.kodi = {
      hostNames = [ "192.168.1.220" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2E4TjCD7rEbKlTHJ+dTFyXq0MQnGzNsET0DQulSgeT";
    };
    extraConfig = ''
      Host kodi
        HostName 192.168.1.220
        User root
        IdentityFile ${config.sops.secrets.kodi_ssh_private_key.path}
        IdentitiesOnly yes
        BatchMode yes
        StrictHostKeyChecking yes
    '';
  };

  services.restic.backups.kodi = mkBackup "kodi" {
    command = [
      "ssh"
      "kodi"
      backupCommand
    ];
    extraBackupArgs = [ "--stdin-filename=coreelec.tar" ];
    timerConfig = {
      OnCalendar = lib.mkForce "*-*-* 04:00:00";
      RandomizedDelaySec = lib.mkForce "15m";
    };
  };
}
