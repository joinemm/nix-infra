{ pkgs, self, ... }:
let
  inherit (self.packages.${pkgs.system}) glide-browser;
in
{
  home.packages = [ glide-browser ];

  xdg.desktopEntries = {
    glide = {
      name = "Glide";
      genericName = "Web Browser";
      exec = "glide %u";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
      ];
      type = "Application";
    };
  };
}
