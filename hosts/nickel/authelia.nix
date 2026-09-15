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
    authelia_immich_client_secret_digest = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
    authelia_mealie_client_secret_digest = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
    authelia_paperless_client_secret_digest = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
    authelia_audiobookshelf_client_secret_digest = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
    authelia_qui_client_secret_digest = {
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

      access_control = {
        default_policy = "two_factor";
        rules = [
          {
            domain = [
              "radarr.lab.joinemm.dev"
              "sonarr.lab.joinemm.dev"
            ];
            subject = "group:admin";
            policy = "one_factor";
          }
          {
            domain = [
              "radarr.lab.joinemm.dev"
              "sonarr.lab.joinemm.dev"
            ];
            policy = "deny";
          }
        ];
      };

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

      definitions.user_attributes.immich_role.expression = ''"admin" in groups ? "admin" : "user"'';

      identity_providers.oidc.claims_policies.grafana.id_token = [
        "email"
        "name"
        "groups"
        "preferred_username"
      ];
      identity_providers.oidc.claims_policies.immich.custom_claims.immich_role = { };
      identity_providers.oidc.scopes.immich.claims = [ "immich_role" ];
      identity_providers.oidc.authorization_policies = {
        admin_only = {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = "group:admin";
            }
          ];
        };
        family = {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = [
                "group:admin"
                "group:family"
              ];
            }
          ];
        };
      };
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
                authorization_policy: admin_only
                pkce_challenge_method: S256
                redirect_uris:
                  - https://grafana.lab.joinemm.dev/login/generic_oauth
                consent_mode: implicit
              - client_id: immich
                client_name: Immich
                client_secret: {{ secret "${config.sops.secrets.authelia_immich_client_secret_digest.path}" | squote }}
                authorization_policy: family
                claims_policy: immich
                pkce_challenge_method: S256
                redirect_uris:
                  - https://immich.lab.joinemm.dev/auth/login
                  - https://immich.lab.joinemm.dev/user-settings
                  - app.immich:///oauth-callback
                scopes:
                  - openid
                  - profile
                  - email
                  - immich
                consent_mode: implicit
              - client_id: mealie
                client_name: Mealie
                client_secret: {{ secret "${config.sops.secrets.authelia_mealie_client_secret_digest.path}" | squote }}
                authorization_policy: family
                pkce_challenge_method: S256
                redirect_uris:
                  - https://mealie.lab.joinemm.dev/login
                scopes:
                  - openid
                  - profile
                  - email
                  - groups
                consent_mode: implicit
              - client_id: paperless
                client_name: Paperless
                client_secret: {{ secret "${config.sops.secrets.authelia_paperless_client_secret_digest.path}" | squote }}
                authorization_policy: family
                pkce_challenge_method: S256
                redirect_uris:
                  - https://paperless.lab.joinemm.dev/accounts/oidc/authelia/login/callback/
                consent_mode: implicit
              - client_id: audiobookshelf
                client_name: Audiobookshelf
                client_secret: {{ secret "${config.sops.secrets.authelia_audiobookshelf_client_secret_digest.path}" | squote }}
                authorization_policy: family
                pkce_challenge_method: S256
                redirect_uris:
                  - https://shelf.lab.joinemm.dev/auth/openid/callback
                  - https://shelf.lab.joinemm.dev/auth/openid/mobile-redirect
                  - https://shelf.lab.joinemm.dev/audiobookshelf/auth/openid/callback
                  - https://shelf.lab.joinemm.dev/audiobookshelf/auth/openid/mobile-redirect
                consent_mode: implicit
              - client_id: qui
                client_name: Qui
                client_secret: {{ secret "${config.sops.secrets.authelia_qui_client_secret_digest.path}" | squote }}
                authorization_policy: admin_only
                pkce_challenge_method: S256
                redirect_uris:
                  - https://qbit.lab.joinemm.dev/api/auth/oidc/callback
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
