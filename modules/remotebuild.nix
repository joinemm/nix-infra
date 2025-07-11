{ user, ... }:
{
  nix = {
    distributedBuilds = true;

    buildMachines = [
      {
        hostName = "hetzarm.vedenemo.dev";
        system = "aarch64-linux";
        maxJobs = 40;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        sshUser = "jrautiola";
        sshKey = "${user.home}/.ssh/id_ed25519";
      }
      {
        hostName = "builder.vedenemo.dev";
        system = "x86_64-linux";
        maxJobs = 16;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        sshUser = "jrautiola";
        sshKey = "${user.home}/.ssh/id_ed25519";
      }
    ];
  };

  programs.ssh.knownHosts = {
    "hetzarm.vedenemo.dev".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
    "builder.vedenemo.dev".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
  };
}
