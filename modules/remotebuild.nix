{ config, inputs, ... }:
let
  machines = import "${inputs.ghaf-infra}/hosts/machines.nix";
in
{
  nix = {
    distributedBuilds = true;
    buildMachines =
      let
        commonOptions = {
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          sshUser = "jrautiola";
          sshKey = "${config.users.default.home}/.ssh/id_ed25519";
        };
      in
      [
        (
          {
            hostName = "hetzarm.vedenemo.dev";
            system = "aarch64-linux";
            maxJobs = 40;
          }
          // commonOptions
        )
        (
          {
            hostName = "builder.vedenemo.dev";
            system = "x86_64-linux";
            maxJobs = 48;
          }
          // commonOptions
        )
      ];
  };

  programs.ssh.knownHosts = {
    "hetzarm.vedenemo.dev".publicKey = machines.hetzarm.publicKey;
    "builder.vedenemo.dev".publicKey = machines.hetz86-builder.publicKey;
  };
}
