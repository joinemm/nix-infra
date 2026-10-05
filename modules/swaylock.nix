{
  config,
  lib,
  pkgs,
  ...
}:
let
  emptyPassword = pkgs.writeShellScript "swaylock-empty-password" ''
    # pam_exec sends the entered password on stdin, without a newline.
    if IFS= read -r -n 1; then
      exit 1
    fi
    exit 0
  '';
in
{
  security.pam.services = {
    swaylock = {
      fprintAuth = config.services.fprintd.enable;
      u2fAuth = false;

      rules.auth = lib.mkIf config.services.fprintd.enable {
        # Only an empty Enter starts fingerprint authentication.
        empty_password = {
          order = config.security.pam.services.swaylock.rules.auth.unix.order - 50;
          control = "[success=1 default=ignore]";
          modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
          args = [
            "quiet"
            "quiet_log"
            "expose_authtok"
            "${emptyPassword}"
          ];
        };
        unix = {
          control = lib.mkForce "[success=done default=die]";
          settings = {
            try_first_pass = lib.mkForce false;
            use_first_pass = true;
          };
        };
        fprintd.order = config.security.pam.services.swaylock.rules.auth.unix.order + 50;
      };
    };
  };
}
