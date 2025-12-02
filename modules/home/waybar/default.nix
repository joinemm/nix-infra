{ pkgs, lib, ... }:
let
  vpn-status = pkgs.writeShellScript "vpn-status" ''
    VPNS=()
    systemctl is-active --quiet openconnect-tii.service && VPNS+=("TII")
    systemctl is-active --quiet openfortivpn-office.service && VPNS+=("Office")
    systemctl is-active --quiet wg-quick-airvpn.service && VPNS+=("AirVPN")
    echo "''${VPNS[@]}" | ${lib.getExe pkgs.gnused} 's/ / + /g'
  '';

  span = size: icon: "<span size='${toString size}pt'>${icon}</span>";
  spanList = size: items: map (x: span size x) items;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ./style.css;

    settings.main = {
      reload_style_on_change = true;
      height = 30;
      spacing = 0;
      modules-left = [
        "river/tags"
        "tray"
        "clock#date"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "custom/vpn"
        "network"
        "bluetooth"
        "pulseaudio"
        "backlight"
        "memory"
        "cpu"
        "battery"
      ];

      "custom/vpn" = {
        format = "󰌆 {text}";
        interval = 1;
        exec = "${vpn-status}";
      };

      "river/tags" = {
        hide-vacant = true;
      };

      tray = {
        icon-size = 20;
        spacing = 6;
      };

      network = {
        interval = 1;
        format = "{icon}";
        format-disconnected = "󰤮";
        format-ethernet = span 15 "󰈀";
        format-wifi = "{icon} {essid}";
        format-icons = [
          "󰤯"
          "󰤟"
          "󰤢"
          "󰤥"
          "󰤨"
        ];
        tooltip-format-disconnected = "Disconnected";
        tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
        tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
      };

      clock = {
        interval = 1;
        format = "{:%H:%M}";
        format-alt = "{:%H:%M:%S}";
      };

      "clock#date" = {
        format = "<i>{:%A, %B %d}</i>";
        tooltip-format = "<tt>{calendar}</tt>";
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
        tooltip-format = "Playing at {volume}%";
        format = "{icon} {volume}%";
        format-muted = span 14 "󰝟";
        format-icons = {
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = spanList 14 [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
        };
      };

      memory = {
        format = "${span 14 ""} {used:0.1f}Gb";
      };

      cpu = {
        format = "${span 13 ""} {usage}%";
      };

      battery = {
        format = "{icon} {capacity}% ";
        format-full = "󰂅";
        format-icons = {
          charging = [
            "󰢜"
            "󰂆"
            "󰂇"
            "󰂈"
            "󰢝"
            "󰂉"
            "󰢞"
            "󰂊"
            "󰂋"
            "󰂅"
          ];
          default = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };
        format-plugged = "";
        interval = 1;
        states = {
          critical = 5;
          warning = 15;
        };
        tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
        tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
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
        format-disabled = span 15 "󰂲";
        format-off = span 15 "󰂲";
        format = "${span 15 ""} {status}";
        format-connected = "${span 15 "󰂱"} {device_alias}";
        format-connected-battery = "${span 15 "{icon}"} {device_alias}";
        format-icons = [
          "󰤾"
          "󰤿"
          "󰥀"
          "󰥁"
          "󰥂"
          "󰥃"
          "󰥄"
          "󰥅"
          "󰥆"
          "󰥈"
        ];
        tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
      };
    };
  };
}
