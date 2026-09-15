{
  config,
  pkgs,
  ...
}:
let
  domain = "auth.lab.joinemm.dev";
  instance = "main";
  service = "authelia-${instance}.service";
in
{
  sops.secrets = {
    authelia_users_database = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
    authelia_jwt_secret.restartUnits = [ service ];
    authelia_storage_encryption_key.restartUnits = [ service ];
    authelia_oidc_hmac_secret.restartUnits = [ service ];
    authelia_oidc_issuer_private_key.restartUnits = [ service ];
    authelia_grafana_client_secret_digest = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
  };

  services.authelia.instances.${instance} = {
    enable = true;

    secrets = {
      jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
      oidcHmacSecretFile = config.sops.secrets.authelia_oidc_hmac_secret.path;
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_oidc_issuer_private_key.path;
    };

    settings = {
      theme = "auto";
      default_2fa_method = "webauthn";
      server.address = "tcp://127.0.0.1:9091/";

      authentication_backend = {
        password_change.disable = true;
        password_reset.disable = true;
        file = {
          path = config.sops.secrets.authelia_users_database.path;
          search.case_insensitive = true;
        };
      };

      access_control.default_policy = "two_factor";

      session.cookies = [
        {
          domain = "lab.joinemm.dev";
          authelia_url = "https://${domain}";
        }
      ];

      storage.local.path = "/var/lib/authelia-${instance}/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-${instance}/notifications.txt";
      webauthn = {
        enable_passkey_login = true;
        experimental_enable_passkey_uv_two_factors = true;
        # selection_criteria.user_verification = "discouraged";
      };

      identity_providers.oidc.claims_policies.grafana.id_token = [
        "email"
        "name"
        "groups"
        "preferred_username"
      ];
    };

    settingsFiles = [
      (pkgs.writeText "authelia-oidc-clients.yml" ''
        identity_providers:
          oidc:
            clients:
              - client_id: grafana
                client_name: Grafana
                client_secret: {{ secret "${config.sops.secrets.authelia_grafana_client_secret_digest.path}" | squote }}
                claims_policy: grafana
                authorization_policy: one_factor
                pkce_challenge_method: S256
                redirect_uris:
                  - https://grafana.lab.joinemm.dev/login/generic_oauth
                consent_mode: implicit
      '')
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      proxyWebsockets = true;
    };
  };
}
