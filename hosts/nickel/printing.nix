{ config, ... }:
{
  services.printing = {
    enable = true;
    startWhenNeeded = false;
    # CUPS rejects non-localhost Host headers on loopback connections.
    # nginx connects via nickel's LAN address; port 8631 stays firewalled.
    listenAddresses = [ "*:8631" ];
    allowFrom = [
      "localhost"
      "192.168.1.20"
    ];
    browsed.enable = false;
    webInterface = true;
    extraConf = ''
      # The packaged systemd unit still launches cupsd in on-demand mode.
      IdleExitTimeout 0
      ServerAlias print.lab.joinemm.dev nickel.local
    '';
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "brother";
        description = "Brother DCP-L3510CDW via nickel";
        deviceUri = "ipp://192.168.1.30/ipp/print";
        model = "everywhere";
        ppdOptions = {
          PageSize = "A4";
          printer-is-shared = "true";
          printer-error-policy = "retry-job";
        };
      }
    ];
    ensureDefaultPrinter = "brother";
  };

  services.nginx.virtualHosts."print.lab.joinemm.dev" = {
    # Keep printing and scanning on the same LAN/Tailscale endpoint.
    serverAliases = [ "nickel.local" ];
    useACMEHost = "lab.joinemm.dev";
    addSSL = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 80;
      }
      {
        addr = "0.0.0.0";
        port = 443;
        ssl = true;
      }
      {
        addr = "0.0.0.0";
        port = 631;
      }
    ];
    extraConfig = ''
      # Redirect browser HTTP without redirecting IPP on port 631.
      if ($server_port = 80) {
        return 308 https://$host$request_uri;
      }
    '';
    locations."/" = {
      # Preserve TLS to CUPS so authenticated web operations work, too.
      proxyPass = "$scheme://192.168.1.20:8631";
      recommendedProxySettings = false;
      extraConfig = ''
        # CUPS must return the public port in its IPP URLs.
        proxy_set_header Host $host:$server_port;
        proxy_http_version 1.1;
        proxy_request_buffering off;
      '';
    };
    locations."/eSCL/" = {
      proxyPass = "http://192.168.1.30";
      extraConfig = ''
        # Keep scan-job URLs returned in Location headers on the proxy.
        proxy_redirect ~^https?://[^/]+(/eSCL/.*)$ $1;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 631 ];

  # Avahi does not notice Nix replacing the service file's symlink target.
  systemd.services.avahi-daemon.restartTriggers = [
    config.environment.etc."avahi/services/printer.service".source
  ];

  # Advertise nginx's public port, not CUPS's internal listener.
  # CUPS supplies the print queue's UUID and full capabilities over IPP.
  services.avahi.extraServiceFiles.printer = ''
    <?xml version="1.0" standalone='no'?>
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
      <name>Brother DCP-L3510CDW via nickel</name>
      <service>
        <type>_ipp._tcp</type>
        <subtype>_universal._sub._ipp._tcp</subtype>
        <port>631</port>
        <txt-record>txtvers=1</txt-record>
        <txt-record>qtotal=1</txt-record>
        <txt-record>rp=printers/brother</txt-record>
        <txt-record>ty=Brother DCP-L3510CDW series</txt-record>
        <txt-record>product=(Brother DCP-L3510CDW series)</txt-record>
        <txt-record>pdl=application/pdf,image/jpeg,image/pwg-raster</txt-record>
        <txt-record>Color=T</txt-record>
        <txt-record>Duplex=T</txt-record>
      </service>
      <service>
        <type>_uscan._tcp</type>
        <port>631</port>
        <txt-record>txtvers=1</txt-record>
        <txt-record>vers=2.63</txt-record>
        <txt-record>rs=eSCL</txt-record>
        <txt-record>ty=Brother DCP-L3510CDW series</txt-record>
        <txt-record>UUID=e3248000-80ce-11db-8000-ac50ded8d585</txt-record>
        <txt-record>pdl=application/pdf,image/jpeg</txt-record>
        <txt-record>cs=binary,grayscale,color</txt-record>
        <txt-record>is=platen</txt-record>
        <txt-record>duplex=F</txt-record>
      </service>
    </service-group>
  '';

}
