{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  with-gpu-record = pkgs.writeShellScriptBin "with-gpu-record" ''
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

    exec "$@"
  '';

  with-gamemode = pkgs.writeShellScriptBin "with-gamemode" ''
    # save LD_PRELOAD value.
    # It is set to empty for gamescope, but reset back to it's original value for the game process.
    # This fixes stuttering after 30 minutes of gameplay, but doesn't break steam overlay.
    LD_PRELOAD_SAVED="$LD_PRELOAD"
    export LD_PRELOAD=""

    # detect resolution
    res="$(wlr-randr | awk '/current/ {print $1; exit}')"
    width=''${res%x*}
    height=''${res#*x}

    # detect refresh rate
    refresh="$(wlr-randr | awk '/current/ {print $3}' | xargs printf "%.0f")"

    exec gamemoderun \
      gamescope -r $refresh -w $width -h $height -f -F pixel \
      --mangoapp \
      --force-grab-cursor \
      -- \
      env LD_PRELOAD="$LD_PRELOAD_SAVED" \
      "$@"
  '';

  # Usage in steam launch options: game-wrapper %command%
  game-wrapper = pkgs.writeShellScriptBin "game-wrapper" ''
    with-gpu-record with-gamemode "$@"
  '';

  # amdvlk is deprecated upstream, but it's the only driver that runs cs2 with good fps
  amdvlk-run =
    let
      oldPkgs = import inputs.nixpkgs-stable { inherit (pkgs.stdenv.hostPlatform) system; };
    in
    pkgs.writeShellScriptBin "amdvlk-run" ''
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
    inputs.nix-gaming.nixosModules.wine
  ];

  environment.systemPackages = [
    with-gpu-record
    with-gamemode
    game-wrapper
    amdvlk-run
    save-replay
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

  programs.wine = {
    enable = true;
    package = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-ge;
    binfmt = true;
    ntsync = true;
  };
}
