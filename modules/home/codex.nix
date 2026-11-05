{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  sshConfig = (pkgs.formats.toml { }).generate "codex-ssh-config.toml" {
    ssh_servers = lib.mapAttrs' (
      pattern: block:
      lib.nameValuePair (lib.head (lib.splitString " " pattern)) {
        host = block.data.HostName;
        user = block.data.User or config.home.username;
        port = block.data.Port or 22;
      }
    ) (lib.filterAttrs (_: block: block.data ? HostName) config.programs.ssh.settings);
  };
in
{
  imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

  programs.mcp.enable = true;
  mcp-servers.programs.nixos.enable = true;

  mcp-servers.settings.servers.ssh = {
    command = lib.getExe' pkgs.nodejs "npx";
    args = [
      "--yes"
      "mcp-ssh-manager@4.0.2"
    ];
    env = {
      SSH_CONFIG_PATH = "${config.home.homeDirectory}/.codex/ssh-config.toml";
      PREFER_TOML_CONFIG = "true";
    };
  };
  # Allow time for npx to download the pinned server on first launch.
  programs.mcp.servers.ssh.startup_timeout_sec = 120;

  home.file.".codex/ssh-config.toml".source = sshConfig;

  programs.codex = {
    enable = true;
    package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    enableMcpIntegration = true;
    # Preserve settings and allow Codex to update its configuration.
    mutableSettings = true;

    settings = {
      personality = "pragmatic";

      tui = {
        status_line = [
          "model-with-reasoning"
          "current-dir"
          "git-branch"
          "context-remaining"
          "codex-version"
          "total-input-tokens"
          "total-output-tokens"
          "thread-credits"
          "estimated-thread-cost"
          "fast-mode"
        ];
        status_line_use_colors = true;
      };
    };
  };
}
