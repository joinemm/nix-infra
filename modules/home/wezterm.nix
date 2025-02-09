{ config, lib, ... }:
{
  options.programs.wezterm = {
    fontSize = lib.mkOption {
      type = lib.types.str;
      default = "10.0";
    };
  };

  config.programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig =
      let
        inherit (config.programs.wezterm) fontSize;
      in
      # lua
      ''
        local theme = "Dracula (Official)"
        local scheme = wezterm.color.get_builtin_schemes()[theme]
        scheme.background = "#101116"

        return {
          front_end = "WebGpu",
          audible_bell = "Disabled",
          font_size = ${fontSize},
          window_background_opacity = 0.85,
          hide_tab_bar_if_only_one_tab = true,

          font = wezterm.font_with_fallback({
            "monospace",
          }),


          visual_bell = {
            fade_in_duration_ms = 75,
            fade_out_duration_ms = 75,
            target = "CursorColor",
          },

          color_scheme = theme,
          color_schemes = {
            [theme] = scheme,
          },

          keys = {
            {
              key = "Enter",
              mods = "CTRL|SHIFT",
              action = wezterm.action.SpawnWindow,
            },
          },
        }
      '';
  };
}
