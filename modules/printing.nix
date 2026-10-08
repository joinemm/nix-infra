{ pkgs, config, ... }: {
  services.printing = {
    enable = true;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_DCP-L3510CDW";
        description = "Brother DCP-L3510CDW (Wi-Fi)";
        deviceUri = "ipp://192.168.1.30:631/ipp/print";
        model = "everywhere";
      }
    ];
    ensureDefaultPrinter = "Brother_DCP-L3510CDW";
  };

  hardware.sane = {
    enable = true;
    brscan5.enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  users.users.${config.owner}.extraGroups = [
    "lp"
    "scanner"
  ];

  environment.systemPackages = [
    pkgs.simple-scan
  ];
}
