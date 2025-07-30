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
          on-click = "loginctl lock-session";
        };

        "custom/power" = {
          format = "";
          on-click = "wlogout";
        };

        "custom/vpn" = {
          format = " {text}";
          interval = 5;
          exec = "vpn-status";
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
          tooltip-format = "{:L%Y 年 %m 月 %d 日, %A}";
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
