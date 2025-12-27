{ pkgs, ... }:
let
  gpgFingerprint = "87ECDD306614E5105299F0D4090EB48A4669AA54";

  yubikey-to-gpg = pkgs.writeShellScriptBin "import-gpg-yubikey" ''
    gpg --batch --yes --command-fd 0 --status-fd 1 --edit-card <<<'fetch'
    echo "${gpgFingerprint}:6:" | gpg --import-ownertrust
    gpg --list-keys
  '';
in
{
  home.packages = [ yubikey-to-gpg ];

  programs.gpg = {
    enable = true;

    # https://github.com/drduh/config/blob/master/gpg.conf
    settings = {
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;
    };

    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  services.gpg-agent = {
    enable = true;

    # https://github.com/drduh/config/blob/master/gpg-agent.conf
    enableSshSupport = true;
    defaultCacheTtl = 60;
    maxCacheTtl = 120;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = ''
      ttyname $GPG_TTY
    '';
  };
}
