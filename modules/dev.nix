{
  inputs,
  pkgs,
  config,
  ...
}:
{

  environment.systemPackages = [
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.bubblewrap # For codex
  ];

  environment.variables = {
    GOPATH = "/home/${config.owner}/.local/share/go";
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune.enable = true;
  };

  # visit astro dev instance from another device such as phone
  networking.firewall.allowedTCPPorts = [ 4321 ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc # C compiler runtime
      openssl # TLS/SSL library
      curl # HTTP client library
      glib # Core library
      util-linux # Linux utilities
      glibc # C standard library
      icu # Unicode support
      libunwind # Stack unwinding
      libuuid # UUID generation
      zlib # Compression library
      libsecret # Secure credential storage
      freetype # Font rendering
      libglvnd # OpenGL vendor library
      libnotify # Desktop notifications
      SDL2 # Graphics library
      vulkan-loader # Vulkan API loader
      gdk-pixbuf # Image loading library
      fuse # Filesystem in userspace
    ];
  };
}
