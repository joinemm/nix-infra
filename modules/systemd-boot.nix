{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
        consoleMode = "auto";
      };
      timeout = 1;
      efi.canTouchEfiVariables = true;
    };

    # quiet boot
    kernelParams = [
      "quiet"
      "udev.log_level=2"
    ];
    consoleLogLevel = 2;
  };
}
