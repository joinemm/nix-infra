{ config, ... }:
let
  domain = "users.joinemm.dev";
in
{
  sops.secrets.lldap_admin_password = {
    owner = "authelia-main";
    restartUnits = [
      "authelia-main.service"
      "lldap.service"
    ];
  };

  services.lldap = {
    enable = true;
    settings = {
      ldap_host = "127.0.0.1";
      http_host = "0.0.0.0";
      http_url = "https://${domain}";
      ldap_base_dn = "dc=joinemm,dc=dev";
      ldap_user_email = "admin@joinemm.dev";
      ldap_user_pass_file = "/run/credentials/lldap.service/admin-password";
      force_ldap_user_pass_reset = "always";
    };
  };

  systemd.services.lldap.serviceConfig.LoadCredential =
    "admin-password:${config.sops.secrets.lldap_admin_password.path}";

  services.nginx.virtualHosts.${domain} = {
    serverAliases = [ "users.lab.joinemm.dev" ];
    useACMEHost = "public-services";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.lldap.settings.http_port}";
      proxyWebsockets = true;
    };
  };
}
