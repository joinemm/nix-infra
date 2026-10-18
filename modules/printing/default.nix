{ pkgs, config, ... }: {
  services.printing = {
    enable = true;
    drivers = [
      (pkgs.writeTextDir "share/cups/model/brother-dcp-l3510cdw.ppd" (
        builtins.readFile ./brother-dcp-l3510cdw.ppd
      ))
    ];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_DCP-L3510CDW_proxy";
        description = "Brother DCP-L3510CDW via NAS";
        deviceUri = "ipp://print.lab.joinemm.dev/printers/brother";
        # "everywhere" queries the NAS during CUPS startup and fails offline.
        model = "brother-dcp-l3510cdw.ppd";
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
