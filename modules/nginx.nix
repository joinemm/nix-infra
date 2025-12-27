{
  pkgs,
  lib,
  config,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "joonas@rautiola.co";
  };

  security.dhparams = {
    enable = true;
    params.nginx = { };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    resolver.addresses = config.networking.nameservers;
    sslDhparam = config.security.dhparams.params.nginx.path;
    appendHttpConfig = ''
      proxy_headers_hash_max_size 512;
      proxy_headers_hash_bucket_size 128;
    '';

    # default server block when nothing else matches.
    # 444 will drop the connection
    virtualHosts."_" = {
      default = true;
      addSSL = true;
      sslCertificate = "/etc/nginx/dummy_ssl/default.crt";
      sslCertificateKey = "/etc/nginx/dummy_ssl/default.key";
      extraConfig = ''
        return 444;
      '';
    };
  };

  systemd.services.create-dummy-cert = {
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];

    serviceConfig = {
      Type = "oneshot";
      Restart = "no";
    };

    script = # sh
      ''
        DIR="/etc/nginx/dummy_ssl"
        if [[ ! -d "$DIR" ]]; then
          mkdir -p "$DIR"
          ${lib.getExe pkgs.openssl} req -x509 -nodes -newkey rsa:2048 \
            -keyout "$DIR/default.key" \
            -out "$DIR/default.crt" \
            -days 3650 \
            -subj "/CN=invalid"
          chown -R nginx:nginx "$DIR"
        fi
      '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
