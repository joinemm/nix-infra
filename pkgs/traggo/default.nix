{
  buildGo123Module,
  fetchFromGitHub,
  stdenv,
  pkgs,
  fetchYarnDeps,
  ...
}:
let
  version = "0.7.1";
  src = fetchFromGitHub {
    owner = "traggo";
    repo = "server";
    tag = "v${version}";
    hash = "sha256-TxWXadKpZ/yrGh4lTMABgLyqUK2SUOm92ImtTVksiX0=";
  };

  traggo-ui = stdenv.mkDerivation (finalAttrs: {
    pname = "traggo-ui";
    inherit src version;

    offlineCache = fetchYarnDeps {
      yarnLock = "${finalAttrs.src}/yarn.lock";
      hash = "sha256-BDQ7MgRWBRQQfjS5UCW3KJ0kJrkn4g9o4mU0ZH+vhX0=";
    };

    preConfigure = ''
      cd ui
    '';

    preBuild = ''
      yarn generate
    '';

    env.NODE_OPTIONS = "--openssl-legacy-provider";

    nativeBuildInputs = with pkgs; [
      yarnConfigHook
      yarnBuildHook
      yarnInstallHook
      nodejs
    ];

    installPhase = ''
      mkdir -p $out
      cp -r build/* $out
    '';
  });
in
buildGo123Module {
  pname = "traggo-server";
  inherit src version;

  nativeBuildInputs = with pkgs; [
    # Fails to build with the current gqlgen version in nixpkgs (0.17.78)
    (gqlgen.overrideAttrs {
      version = "0.17.53";
      src = fetchFromGitHub {
        owner = "99designs";
        repo = "gqlgen";
        tag = "v0.17.53";
        hash = "sha256-jrhxXTOMthso9VIMYEjE8RDi9Hm6Dz3G1oBYYTjMsRc=";
      };
      vendorHash = "sha256-wsuep7K5SlkTWCiOuzjrkODZgAsHDa9wO8nnwWQVYco=";
    })
  ];

  preBuild = ''
    # copy in the built ui
    mkdir ui/build
    cp -r ${traggo-ui}/* ui/build

    # skip mod tidy as it needs internet access
    printf "\nskip_mod_tidy: true" >> gqlgen.yml

    # generate graphql schema and model
    gqlgen
  '';

  ldflags = [
    "-X main.BuildDate=1970-01-01T00:00:00Z"
    "-X main.BuildMode=prod"
    "-X main.BuildVersion=v${version}"
  ];

  vendorHash = "sha256-hH3D4FQc4QgNyoLGABERQXd/cfHf6iYD0GmCg+Pp9Hs=";

  meta = {
    mainProgram = "server";
  };
}
