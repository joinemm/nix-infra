{ pkgs, ... }:
{
  home.packages = [ (pkgs.polybar.override { pulseSupport = true; }) ];

  xdg.configFile = {
    "polybar/config.ini".source = ./polybar.ini;
    "polybar/redshift.sh".source = pkgs.writeShellScript "redshift.sh" ''
      checkIfRunning() {
        if [ $(systemctl --user is-active redshift) == "active" ]; then
          return 0
        else
          return 1
        fi
      }

      changeModeToggle() {
        if checkIfRunning ; then
          systemctl --user stop redshift
        else
          systemctl --user start redshift
        fi
      }

      case $1 in
        toggle)
          changeModeToggle
          ;;
        temperature)
          if checkIfRunning ; then
            CURRENT_TEMP=$(redshift -p 2> /dev/null  | grep "Color temperature" | sed 's/.*: //')
            echo "$CURRENT_TEMP"
          else
            echo "off"
          fi
          ;;
      esac
    '';
    "polybar/vpn.sh".source = pkgs.writeShellScript "vpn.sh" ''
      VPNS=()
      systemctl is-active --quiet openconnect-tii.service && VPNS+=("TII")
      systemctl is-active --quiet openvpn-ficolo.service && VPNS+=("FICOLO")
      systemctl is-active --quiet openfortivpn-office.service && VPNS+=("OFFICE")
      systemctl is-active --quiet wg-quick-airvpn.service && VPNS+=("AIRVPN")
      echo "''${VPNS[@]}" | sed 's/ / + /g'
    '';
  };

  # Fix tray icons for steam, spotify
  systemd.user.services.snixembed = {
    Unit = {
      Description = "Proxy StatusNotifierItems as XEmbedded systemtray-spec icons";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.snixembed}/bin/snixembed";
      Restart = "always";
    };
  };

}
