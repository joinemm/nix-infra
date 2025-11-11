{ pkgs, lib, ... }:
let
  vpn-status = pkgs.writeShellScriptBin "vpn-status" ''
    VPNS=()
    systemctl is-active --quiet openconnect-tii.service && VPNS+=("TII")
    systemctl is-active --quiet openvpn-ficolo.service && VPNS+=("FICOLO")
    systemctl is-active --quiet openfortivpn-office.service && VPNS+=("OFFICE")
    systemctl is-active --quiet wg-quick-airvpn.service && VPNS+=("AIRVPN")
    echo "''${VPNS[@]}" | ${lib.getExe pkgs.gnused} 's/ / + /g'
  '';
in
{
  programs.wlogout.enable = true;

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    style = ./waybar.css;

    settings = {
      mainBar = {
        height = 35;
        spacing = 0;
        modules-left = [
          "river/tags"
          "tray"
          "custom/lock"
          "custom/power"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/inhibitor"
          "custom/vpn"
          "network"
          "bluetooth"
          "pulseaudio"
          "backlight"
          "memory"
          "cpu"
          "battery"
        ];

        "custom/lock" = {
          format = "";
          on-click = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        };

        "custom/power" = {
          format = "";
          on-click = "${lib.getExe pkgs.wlogout}";
        };

        "custom/inhibitor" = {
          format = "{icon}";
          exec = "${lib.getExe pkgs.sway-audio-idle-inhibit} --dry-print-both-waybar";
          return-type = "json";
          format-icons = {
            output = " ";
            input = " ";
            output-input = "  ";
            none = "";
          };
        };

        "custom/vpn" = {
          format = " {text}";
          interval = 5;
          exec = "${vpn-status}/bin/vpn-status";
        };

        "river/tags" = {
          hide-vacant = true;
        };

        tray = {
          icon-size = 22;
          spacing = 6;
        };

        network = {
          format-wifi = "󰤨 {essid}";
          format-ethernet = " Wired";
          format-disconnected = " Disconnected";
          interval = 1;
          tooltip-format = "<span color='#FF1493'> 󰅧 </span>{bandwidthUpBytes}  <span color='#00BFFF'> 󰅢 </span>{bandwidthDownBytes}";
        };

        battery = {
          states = {
            warning = 10;
            critical = 5;
          };
          format-icons = [
            "󰂎"
            "󰁼"
            "󰁿"
            "󰂁"
            "󰁹"
          ];
          format-charging = "󱐋{capacity}%";
          interval = 1;
          format = "{icon} {capacity}%";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "right";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰖁";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
        };

        memory = {
          format = " {used:0.1f}Gb";
        };

        cpu = {
          format = " {usage}%";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [
            "󰃞"
            "󰃝"
            "󰃟"
            "󰃠"
          ];
        };

        bluetooth = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} ({device_battery_percentage}%)";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        };
      };
    };
  };

}
