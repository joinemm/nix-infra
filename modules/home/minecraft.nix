{
  config,
  inputs,
  osConfig,
  pkgs,
  ...
}:
{
  imports = [ inputs.prismix.homeModules.default ];

  programs.prismlauncher = {
    enable = true;
    config = {
      language = "en_US";
      theme = "dark";
      iconTheme = "flat_white";
      cat.pack = "teawie";
      console = {
        font.name = "FiraCode Nerd Font";
        log.maxLines = 100000;
      };
      window = {
        minecraft.maximized = true;
        launcher.closeOn.launch = true;
      };
      java = {
        path = "${pkgs.jdk21}/bin/java";
        # https://github.com/DataDalton/Minecraft-Performance-Guide/blob/main/Java%20Arguments/README.md
        args = [
          "-XX:+UnlockExperimentalVMOptions"
          "-XX:+UnlockDiagnosticVMOptions"
          "-XX:+AlwaysActAsServerClassMachine"
          "-XX:+AlwaysPreTouch"
          "-XX:+DisableExplicitGC"
          "-XX:+UseNUMA"
          "-XX:NmethodSweepActivity=1"
          "-XX:ReservedCodeCacheSize=400M"
          "-XX:NonNMethodCodeHeapSize=12M"
          "-XX:ProfiledCodeHeapSize=194M"
          "-XX:NonProfiledCodeHeapSize=194M"
          "-XX:-DontCompileHugeMethods"
          "-XX:MaxNodeLimit=240000"
          "-XX:NodeLimitFudgeFactor=8000"
          "-XX:+UseVectorCmov"
          "-XX:+PerfDisableSharedMem"
          "-XX:+UseFastUnorderedTimeStamps"
          "-XX:+UseCriticalJavaThreadPriority"
          "-XX:ThreadPriorityPolicy=1"
          "-XX:AllocatePrefetchStyle=1"
          "-XX:+UseZGC"
          "-XX:-ZProactive"
          "-XX:-ZUncommit"
          "-XX:+ZGenerational"
        ];
        mem = {
          min = 4096;
          max = 4096;
        };
      };
    };

    settings = {
      DownloadsDir = config.xdg.userDirs.download;
      EnableFeralGamemode = osConfig.programs.gamemode.enable;
      EnableMangoHud = config.programs.mangohud.enable;
    };

    # instances required even when it's empty
    instances = { };
  };
}
