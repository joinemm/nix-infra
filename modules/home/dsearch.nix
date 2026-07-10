{
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.danksearch.homeModules.default ];

  systemd.user.services.dsearch = {
    Unit.After = lib.mkForce [ "graphical-session.target" ];
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };

  programs.dsearch = {
    enable = true;
    config = {
      index_paths = [
        {
          path = "/home/${config.home.username}";
          exclude_dirs = [
            ".git"

            # JavaScript/Node.js
            "node_modules"
            "bower_components"
            ".npm"
            ".yarn"

            # Python
            "site-packages"
            "__pycache__"
            ".venv"
            "venv"
            ".tox"
            ".pytest_cache"
            ".eggs"

            # Build outputs
            "dist"
            "build"
            "out"
            "bin"
            "obj"

            # Rust
            "target"

            # Go
            "vendor"

            # Java/JVM
            ".gradle"
            ".m2"

            # Ruby
            "bundle"

            # Cache directories
            ".cache"
            ".parcel-cache"
            ".next"
            ".nuxt"

            # OS specific
            "Library"
            ".Trash-1000"

            # Databases
            ".postgresql"
            ".mysql"
            ".mongodb"
            ".redis"

            # Package manager caches
            "go"
            ".cargo"
            ".pyenv"
            ".rbenv"
            ".nvm"
            ".rustup"

            # IDE/Editor
            ".idea"
            ".vscode"
          ];
        }
      ];
    };
  };
}
