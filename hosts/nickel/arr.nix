{
  config,
  pkgs,
  user,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixarr.nixosModules.default
  ];

  sops.secrets = {
    "wireguard.conf".owner = "root";
    recyclarr-secrets = {
      format = "binary";
      sopsFile = ./recyclarr_secrets;
      path = "${user.home}/.config/recyclarr/secrets.yml";
      owner = user.name;
    };
  };

  # allow me to access the files too
  users.users."${user.name}".extraGroups = [ "media" ];

  # https://github.com/NixOS/nixpkgs/issues/360592
  # sonarr is not updated to .NET 8 yet but 6 is marked as insecure
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  systemd.tmpfiles.rules = [
    "d '${config.nixarr.mediaDir}/torrents'             0755 torrenter media - -"
    "d '${config.nixarr.mediaDir}/torrents/.incomplete' 0755 torrenter media - -"
    "d '${config.nixarr.mediaDir}/torrents/.watch'      0755 torrenter media - -"
  ];

  # rebrand jellyfin web client assets
  nixpkgs.overlays = [
    (_: prev: {
      jellyfin-web =
        let
          assets = ./assets;
          dest = "$out/share/jellyfin-web";
        in
        prev.jellyfin-web.overrideAttrs {
          postInstall = ''
            cp -f ${assets}/banner.png ${dest}/assets/img/banner-light.png
            cp -f ${assets}/banner.png ${dest}/assets/img/banner-dark.png
            cp -f ${assets}/icon.png ${dest}/assets/img/icon-transparent.png
            cp -f ${assets}/icon.png ${dest}/favicon.png
            cp -f ${assets}/favicon.ico ${dest}/favicon.ico
          '';
        };
    })
  ];

  # enable vaapi on OS-level
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  # hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-media-sdk # QSV up to 11th gen
    ];
  };

  # The arr suite
  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/var/lib/nixarr";

    jellyfin.enable = true; # 8096

    prowlarr.enable = true; # 9696
    radarr.enable = true; # 7878
    sonarr.enable = true; # 8989
    bazarr.enable = true; # 6767
  };

  users.groups = {
    torrenter = { };
    cross-seed = { };
  };

  users.users.torrenter = {
    isSystemUser = true;
    group = "torrenter";
  };

  vpnNamespaces.wg = {
    enable = true;
    # wireguard config generated by airvpn
    wireguardConfigFile = config.sops.secrets."wireguard.conf".path;
    portMappings = [
      {
        from = config.services.deluge.web.port;
        to = config.services.deluge.web.port;
      }
    ];
    openVPNPorts = [
      {
        port = 41886;
        protocol = "both";
      }
    ];
    accessibleFrom = [
      "192.168.1.0/24"
      "10.0.0.0/8"
      "127.0.0.1"
    ];
  };

  # use deluge torrent client
  services.deluge = {
    enable = true;
    user = "torrenter";
    group = "media";
    web = {
      enable = true;
      openFirewall = true;
      port = 8112;
    };
  };

  # run deluge daemon inside the vpn
  systemd.services.deluged.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  # run deluge web ui inside the vpn.
  # while this doesn't matter for leaking of torrents,
  # it's required so the web ui can find the daemon
  systemd.services.delugeweb.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  home-manager.users.${user.name} = {
    home.stateVersion = config.system.stateVersion;
    xdg.configFile."recyclarr/recyclarr.yml".source = ./recyclarr.yml;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    intel-gpu-tools
    recyclarr
  ];
}