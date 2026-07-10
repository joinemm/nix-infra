{ pkgs, ... }:
{
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = false;
      qemu.package = pkgs.qemu_kvm;
    };
  };

  environment.systemPackages = with pkgs; [ quickemu ];
}
