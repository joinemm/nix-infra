{ inputs, pkgs, ... }:
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    # inputs.dms.homeModules.niri
    inputs.dms-plugin-registry.modules.default
  ];

  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;

    plugins = {
      dankBatteryAlerts.enable = true;
      dankKDEConnect.enable = true;
      emojiLauncher.enable = true;
      niriScreenshot.enable = true;
      dankHooks.enable = true;
      dankBitwarden.enable = true;
      calculator.enable = true;
      developerUtilities.enable = true;
      dankPomodoroTimer.enable = true;
    };

    settings = builtins.fromJSON (builtins.readFile ./settings.json);
  };

  # dependencies
  services.kdeconnect.enable = true;

  programs.rbw = {
    enable = true;
  };

  home.packages = with pkgs; [
    libqalculate
    sshfs
  ];
}
