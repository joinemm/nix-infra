{ pkgs, ... }:
{
  services.poweralertd = {
    enable = true;
    package = pkgs.poweralertd.overrideAttrs (old: {
      # Complete session-bus authentication before waiting for battery events.
      # Otherwise the first notification after a long idle fails with ENOTCONN.
      postPatch = (old.postPatch or "") + ''
        substituteInPlace main.c \
          --replace-fail 'ret = sd_bus_open_system(&system_bus);' \
          'ret = sd_bus_flush(user_bus);
          if (ret < 0) {
              fprintf(stderr, "could not finish session bus connection: %s\n", strerror(-ret));
              goto finish;
          }
          ret = sd_bus_open_system(&system_bus);'
      '';
    });
    extraArgs = [
      "-s"
      "-i"
      "line power"
    ];
  };
}
