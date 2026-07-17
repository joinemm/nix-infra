{
  self,
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  # disable beeping motherboard speaker
  boot.blacklistedKernelModules = [ "pcspkr" ];

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  zramSwap.enable = true;

  systemd.services."systemd-zram-setup@".restartIfChanged = false;

  # Tweaking the system's swap to take full advantage of zram.
  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  boot.kernel.sysctl = lib.mkIf config.zramSwap.enable {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

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

  services.fwupd = {
    enable = true;
    # https://github.com/nix-community/lanzaboote/issues/591
    package = pkgs.fwupd.overrideAttrs (old: {
      version = "2.1.6";
      src = pkgs.fetchFromGitHub {
        owner = "fwupd";
        repo = "fwupd";
        tag = "2.1.6";
        hash = "sha256-K8n1rPiLuHDybWPoAUQA7RY4J+Ga1fwNiaj48fHAh9A=";
      };
      patches = lib.filter (
        patch: baseNameOf patch != "0004-Get-the-efi-app-from-fwupd-efi.patch"
      ) old.patches;
      mesonFlags = lib.filter (flag: !lib.hasPrefix "-Defi_app_location=" flag) old.mesonFlags ++ [
        (lib.mesonOption "efi_app_location" (
          if lib.attrByPath [ "boot" "lanzaboote" "enable" ] false config then
            "/run/fwupd-efi"
          else
            "${pkgs.fwupd-efi}/libexec/fwupd/efi"
        ))
      ];
    });
  };

  systemd.services.fwupd-refresh.enable = false;

  nixpkgs.config.allowUnfree = true;

  # revision of the flake the configuration was built from.
  # $ nixos-version --configuration-revision
  system.configurationRevision = toString (
    self.rev or self.dirtyRev or self.lastModified or "unknown"
  );

  nix = {
    registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;

    package = pkgs.lix;

    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      accept-flake-config = true;
      allow-import-from-derivation = true;
      builders-use-substitutes = true;
      keep-derivations = true;
      keep-outputs = true;

      # https://bmcgee.ie/posts/2023/12/til-how-to-optimise-substitutions-in-nix/
      max-substitution-jobs = 128;
      http-connections = 128;
      max-jobs = "auto";

      extra-substituters = [
        "https://ghaf-dev.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    extraOptions = ''
      # Ensure we can still build when a binary cache is not accessible
      fallback = true
    '';
  };

  environment = {
    shells = with pkgs; [
      bashInteractive
      fish
    ];

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
