{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # jira.tii.ae omits this intermediate from its TLS certificate chain.
  jiraIntermediate = pkgs.fetchurl {
    url = "https://secure.globalsign.com/cacert/gsrsaovsslca2018.crt";
    hash = "sha256-tnb/oxeeiBIJOhter+6HauemqvIxB42tG/shzSiTdko=";
  };
  jiraCaBundle = pkgs.runCommand "jira-ca-bundle.pem" { nativeBuildInputs = [ pkgs.openssl ]; } ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > "$out"
    openssl x509 -inform DER -in ${jiraIntermediate} >> "$out"
  '';
  sshGroups = {
    production = [
      "hetzci-prod"
      "testagent-prod"
      "testagent2-prod"
      "uae-azureci-prod"
      "uae-testagent-prod"
      "uae-testagent2-prod"
    ];
    builders = [
      "hetz86-1"
      "hetz86-builder"
      "hetz86-dbg-1"
      "hetz86-rel-2"
      "hetzarm"
      "hetzarm-dbg-1"
      "hetzarm-rel-1"
      "uae-azureci-az86-1"
      "uae-azureci-hetzarm-1"
    ];
    development = [
      "hetzci-dbg"
      "hetzci-dev"
      "nethsm-gateway-dev"
      "testagent-dbg"
      "testagent-dev"
    ];
    release = [
      "hetzci-release"
      "testagent-release"
    ];
    lab = [ "uae-lab-node1" ];
    infrastructure = [
      "ghaf-auth"
      "ghaf-fleetdm"
      "ghaf-lighthouse"
      "ghaf-log"
      "ghaf-monitoring"
      "ghaf-registry"
      "ghaf-webserver"
      "nethsm-gateway"
      "uae-azureci-registry"
      "uae-nethsm-gateway"
    ];
    personal = [
      "miso"
      "nickel"
      "oracle"
      "oxygen"
    ];
  };
  sshHostGroups = lib.concatMapAttrs (group: hosts: lib.genAttrs hosts (_: group)) sshGroups;
  sshGroupDescriptions = {
    production = "Ghaf production host (MCP read-only)";
    builders = "Ghaf Nix build host";
    development = "Ghaf development/debug host";
    release = "Ghaf release environment (MCP read-only)";
    lab = "Ghaf lab host";
    infrastructure = "Ghaf infrastructure service";
  };
  personalSshDescriptions = {
    miso = "Miso Bot production server";
    oxygen = "Web services and Syncthing server";
    nickel = "Home NAS and media server";
    oracle = "Personal Oracle Cloud server";
  };
  sshAuditDir = "${config.xdg.stateHome}/mcp-ssh/audit";
  sshConfig = (pkgs.formats.toml { }).generate "codex-ssh-config.toml" {
    ssh_servers =
      lib.mapAttrs'
        (
          pattern: block:
          let
            name = lib.head (lib.splitString " " pattern);
            group = sshHostGroups.${name};
          in
          lib.nameValuePair name (
            {
              host = block.data.HostName;
              user = block.data.User or config.home.username;
              port = block.data.Port or 22;
              # ssh2 uses the agent but does not discover OpenSSH's default key files.
              key_path = "${config.home.homeDirectory}/.ssh/id_ed25519";
              audit_log = "${sshAuditDir}/${name}.jsonl";
              inherit group;
              description = personalSshDescriptions.${name} or sshGroupDescriptions.${group};
            }
            //
              lib.optionalAttrs
                (lib.elem group [
                  "production"
                  "release"
                ])
                {
                  mode = "readonly";
                }
          )
        )
        (
          lib.filterAttrs (
            pattern: block:
            block.data ? HostName && builtins.hasAttr (lib.head (lib.splitString " " pattern)) sshHostGroups
          ) config.programs.ssh.settings
        );
  };
in
{
  sops.secrets.jira_access_token = { };

  programs.mcp = {
    enable = true;
    servers = {
      nixos = {
        command = lib.getExe pkgs.mcp-nixos;
        tools.nix.approval_mode = "approve";
      };

      atlassian = {
        command = lib.getExe' pkgs.uv "uvx";
        args = [
          "--python"
          (lib.getExe pkgs.python313)
          "mcp-atlassian==0.24.8"
        ];
        env = {
          JIRA_URL = "https://jira.tii.ae";
          JIRA_PERSONAL_TOKEN.file = config.sops.secrets.jira_access_token.path;
          JIRA_PROJECTS_FILTER = "SSRCSP";
          READ_ONLY_MODE = "false";
          REQUESTS_CA_BUNDLE = "${jiraCaBundle}";
        };
        # Allow time for uvx to download the pinned server on first launch.
        startup_timeout_sec = 120;
      };

      ssh = {
        command = lib.getExe' pkgs.nodejs "npx";
        args = [
          "--yes"
          "mcp-ssh-manager@4.0.2"
        ];
        env = {
          SSH_CONFIG_PATH = "${config.home.homeDirectory}/.codex/ssh-config.toml";
          PREFER_TOML_CONFIG = "true";
        };
        tools.ssh_list_servers.approval_mode = "approve";
        # Allow time for npx to download the pinned server on first launch.
        startup_timeout_sec = 120;
      };
    };
  };

  home.file.".codex/ssh-config.toml".source = sshConfig;
  home.activation.sshAuditDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 ${lib.escapeShellArg sshAuditDir}
  '';

  programs.codex = {
    enable = true;
    package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    enableMcpIntegration = true;
    # Preserve settings and allow Codex to update its configuration.
    mutableSettings = true;

    settings = {
      personality = "pragmatic";
      sandbox_workspace_write.network_access = true;

      tui = {
        # Match Foot's scrollback multiplier.
        mouse_scroll_speed = 6;
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
