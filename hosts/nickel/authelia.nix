{
  config,
  pkgs,
  ...
}:
let
  domain = "auth.lab.joinemm.dev";
  instance = "main";
  service = "authelia-${instance}.service";
  protectedServices = [
    "bazarr"
    "prometheus"
    "prowlarr"
    "radarr"
    "sonarr"
  ];
  forwardAuthLocations = {
    "/internal/authelia/authz" = {
      proxyPass = "http://127.0.0.1:9091/api/authz/auth-request";
      extraConfig = ''
        internal;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header Connection "";
        proxy_set_header X-Original-Method $request_method;
        proxy_set_header X-Original-URL $scheme://$host$request_uri;
        proxy_set_header X-Forwarded-For $remote_addr;
      '';
    };
    "/".extraConfig = ''
      auth_request /internal/authelia/authz;
      auth_request_set $redirection_url $upstream_http_location;
      error_page 401 =302 $redirection_url;
    '';
  };
in
{
  sops.secrets = {
    authelia_jwt_secret.restartUnits = [ service ];
    authelia_storage_encryption_key.restartUnits = [ service ];
    authelia_oidc_hmac_secret.restartUnits = [ service ];
    authelia_oidc_issuer_private_key.restartUnits = [ service ];
    authelia_smtp_password = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
    authelia_session_secret = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
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
    authelia_dawarich_client_secret_digest = {
      owner = "authelia-${instance}";
      restartUnits = [ service ];
    };
  };

  services.authelia.instances.${instance} = {
    enable = true;

    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets.lldap_admin_password.path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets.authelia_smtp_password.path;
    };

    secrets = {
      jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
      oidcHmacSecretFile = config.sops.secrets.authelia_oidc_hmac_secret.path;
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_oidc_issuer_private_key.path;
      sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
    };

    settings = {
      theme = "auto";
      default_2fa_method = "webauthn";
      server.address = "tcp://127.0.0.1:9091/";

      authentication_backend = {
        password_change.disable = true;
        password_reset.custom_url = "https://users.joinemm.dev";
        ldap = {
          implementation = "lldap";
          address = "ldap://127.0.0.1:${toString config.services.lldap.settings.ldap_port}";
          base_dn = config.services.lldap.settings.ldap_base_dn;
          user = "uid=admin,ou=people,${config.services.lldap.settings.ldap_base_dn}";
        };
      };

      access_control = {
        default_policy = "two_factor";
        rules = [
          {
            domain = map (service: "${service}.lab.joinemm.dev") protectedServices;
            subject = "group:admin";
            policy = "one_factor";
          }
          {
            domain = map (service: "${service}.lab.joinemm.dev") protectedServices;
            policy = "deny";
          }
        ];
      };

      session = {
        redis.host = config.services.redis.servers.authelia.unixSocket;
        cookies = [
          {
            domain = "lab.joinemm.dev";
            authelia_url = "https://${domain}";
          }
        ];
      };

      storage.local.path = "/var/lib/authelia-${instance}/db.sqlite3";
      notifier.smtp = {
        address = "submissions://smtp.migadu.com:465";
        username = "lab@joinemm.dev";
        sender = "Authelia <lab@joinemm.dev>";
        identifier = "auth.joinemm.dev";
        startup_check_address = "lab@joinemm.dev";
      };
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
              - client_id: dawarich
                client_name: Dawarich
                client_secret: {{ secret "${config.sops.secrets.authelia_dawarich_client_secret_digest.path}" | squote }}
                authorization_policy: family
                pkce_challenge_method: S256
                redirect_uris:
                  - https://dawarich.lab.joinemm.dev/users/auth/openid_connect/callback
                scopes:
                  - openid
                  - profile
                  - email
                consent_mode: implicit
      '')
    ];
  };

  services.redis.servers.authelia = {
    enable = true;
    group = "authelia-${instance}";
    appendOnly = true;
  };

  systemd.services."authelia-${instance}" = {
    requires = [ "redis-authelia.service" ];
    after = [ "redis-authelia.service" ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9091";
        proxyWebsockets = true;
      };
    };
  }
  // builtins.listToAttrs (
    map (service: {
      name = "${service}.lab.joinemm.dev";
      value.locations = forwardAuthLocations;
    }) protectedServices
  );
}
