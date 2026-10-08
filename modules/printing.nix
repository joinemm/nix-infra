{ pkgs, config, ... }: {
  services.printing = {
    enable = true;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_DCP-L3510CDW_proxy";
        description = "Brother DCP-L3510CDW via NAS";
        deviceUri = "ipp://print.lab.joinemm.dev/ipp/print";
        model = "everywhere";
      }
    ];
    ensureDefaultPrinter = "Brother_DCP-L3510CDW_proxy";
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
