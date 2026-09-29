{
  self,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.determinate.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;

  # revision of the flake the configuration was built from.
  # $ nixos-version --configuration-revision
  system.configurationRevision = toString (
    self.rev or self.dirtyRev or self.lastModified or "unknown"
  );

  documentation.nixos.enable = false;

  nix = {
    registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;

    # package = pkgs.lix;

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
}
