{ pkgs, ... }:
{
  # Most software has the HIP libraries hard-coded. Workaround with tmpfiles
  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
        ];
      };
    in
    [
      "L+ /opt/rocm - - - - ${rocmEnv}"
    ];

  nixpkgs.config.rocmSupport = true;

  boot.kernelModules = [ "kvm-amd" ];

  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true;
    zluda.enable = true;
    overdrive.enable = true;
  };

  environment.systemPackages = with pkgs; [
    clinfo
  ];

  services.lact = {
    enable = true;
    # settings = {};
  };
}
