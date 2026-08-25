{ config, lib, ... }:
{
  home.activation.clearTofiDrunCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -f -- ${lib.escapeShellArg "${config.xdg.cacheHome}/tofi-drun"}
  '';

  programs.tofi = {
    enable = true;
    settings = {
      width = "100%";
      height = "100%";
      border-width = 0;

      outline-width = 0;
      padding-left = "35%";
      padding-top = "35%";

      result-spacing = 20;
      num-results = 5;
      font = "monospace";
      background-color = "#000A";
    };
  };
}
