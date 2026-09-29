{
  self,
  pkgs,
  lib,
  config,
  ...
}:
{
  # disable beeping motherboard speaker
  boot.blacklistedKernelModules = [ "pcspkr" ];

  # use the latest kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
  };

  console = {
    packages = with pkgs; [
      terminus_font
    ];
    # https://files.ax86.net/terminus-ttf/README.Terminus.txt
    # v = all language sets
    # 22 = size
    # n = normal
    font = "ter-v22n";
    earlySetup = true;
    colors = [
      "000000" # black
      "ff5555" # red
      "50fa7b" # green
      "f1fa8c" # yellow
      "bd93f9" # blue
      "ff79c6" # magenta
      "8be9fd" # cyan
      "bfbfbf" # white
      "4d4d4d" # bright black
      "ff6e67" # bright red
      "5af78e" # bright green
      "f4f99d" # bright yellow
      "caa9fa" # bright blue
      "ff92d0" # bright magenta
      "9aedfe" # bright cyan
      "e6e6e6" # bright white
    ];
  };

  security = {
    polkit = {
      enable = true;

      # allow me to use systemd without password every time
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${config.owner}") {
            return polkit.Result.YES;
          }
        });
      '';
    };

    sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
        Defaults passwd_timeout=0
      '';
    };
  };

  environment = {
    # uninstall all default packages that I don't need
    defaultPackages = lib.mkForce [ ];

    systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.nix-show-deployment
    ]
    ++ (with pkgs; [
      git
      vim
      wget
      fastfetch
      pciutils
      usbutils
      dig
      tree
      rsync
      jq
      efibootmgr
      e2fsprogs
    ]);

    variables = {
      DO_NOT_TRACK = 1;
    };
  };
}
