{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  # Usage in steam launch options: game-wrapper %command%
  game-wrapper = pkgs.writeShellScriptBin "game-wrapper" ''
    # save LD_PRELOAD value.
    # It is set to empty for gamescope, but reset back to it's original value for the game process.
    # This fixes stuttering after 30 minutes of gameplay, but doesn't break steam overlay.
    LD_PRELOAD_SAVED="$LD_PRELOAD"
    export LD_PRELOAD=""

    APPID="''${SteamGameId:-''${STEAM_COMPAT_APP_ID:-unknown}}"
    REPLAY_DIR="$HOME/videos/replay/$APPID"
    mkdir -p "$REPLAY_DIR"

    GSR_PID=""

    if ! pgrep -f gpu-screen-recorder >/dev/null 2>&1; then
    gpu-screen-recorder \
      -w screen \
      -v no \
      -fm vfr \
      -a "default_output|default_input" \
      -c mkv \
      -q ultra \
      -r 60 \
      -o "$REPLAY_DIR" \
      >/tmp/gsr-"$APPID".log 2>&1 &
    GSR_PID=$!
    echo "Replay recording into $REPLAY_DIR"
    fi

    cleanup() {
      if [ -n "$GSR_PID" ] && kill -0 "$GSR_PID" 2>/dev/null; then
        kill -INT "$GSR_PID"
        wait "$GSR_PID" || true
      fi
    }
    trap cleanup EXIT INT TERM

    exec gamemoderun \
      gamescope -r 144 -w 3440 -h 1440 -f -F pixel \
      --mangoapp \
      --force-grab-cursor \
      -- \
      env LD_PRELOAD="$LD_PRELOAD_SAVED" \
      "$@"
  '';

  # amdvlk is deprecated, but it's the only driver that runs cs2 well for me
  oldPkgs = import inputs.nixpkgs-stable { inherit (pkgs.stdenv.hostPlatform) system; };

  amdvlk-run = pkgs.writeShellScriptBin "amdvlk-run" ''
    export VK_DRIVER_FILES="${oldPkgs.amdvlk}/share/vulkan/icd.d/amd_icd64.json:${oldPkgs.pkgsi686Linux.amdvlk}/share/vulkan/icd.d/amd_icd32.json"
    exec "$@"
  '';

  save-replay = pkgs.writeShellScriptBin "save-replay" ''
    if pkill -USR1 -f gpu-screen-recorder; then
      ${lib.getExe' pkgs.libnotify "notify-send"} "Saved replay"
    else
      ${lib.getExe' pkgs.libnotify "notify-send"} "No replay buffer running"
    fi
  '';
in
{
  imports = [
    inputs.nix-gaming.nixosModules.platformOptimizations
  ];

  programs = {
    steam = {
      enable = true;
      platformOptimizations.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          reaper_freq = 5;
          desiredgov = "performance";
          renice = 10;
          ioprio = 0;
          inhibit_screensaver = 0;
          disable_splitlock = 1;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
          amd_performance_level = "high";
        };
      };
    };

    gamescope.enable = true;

    # for minecraft
    java.enable = true;
  };

  users.default.extraGroups = [ "gamemode" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      # Add vulkan video encoding support
      extraPackages = with pkgs; [
        libva
      ];
    };

    # Xbox wireless controller driver
    xone.enable = true;
  };

  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      protontricks
      winetricks
      protonplus
      libva-utils
      lutris-free
      (bottles.override { removeWarningPopup = true; })
      (wineWow64Packages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      ludusavi
    ]
    ++ [
      game-wrapper
      amdvlk-run
      save-replay
    ];
}
