{ pkgs, lib, ... }:
{
  # overclock

  environment.systemPackages = with pkgs; [
    lact
    unigine-heaven
  ];

  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xfffd7fff" ];

  systemd.services.lactd = {
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      Description = "AMDGPU Control Daemon";
      After = [ "multi-user.target" ];
    };
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.lact} daemon";
      Nice = -10;
    };
  };

  # 2000 Mhz core clock
  # 1800 Mhz memory clock
  # 1100 mV max voltage
  environment.etc."lact/config.yaml".text = # yaml
    ''
      version: 5
      daemon:
        log_level: info
        admin_group: wheel
        disable_clocks_cleanup: false
      apply_settings_timer: 5
      gpus:
        1002:731F-1DA2:E411-0000:0b:00.0:
          fan_control_enabled: false
          power_cap: 220.0
          performance_level: auto
          max_core_clock: 2000
          max_memory_clock: 850
          max_voltage: 1110
    '';
}
