{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  name = "blocky-ui";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "ivvija";
    repo = name;
    rev = "v${version}";
    sha256 = "sha256-+owS2CVcKPSTscEoXBXZjLDqGlJH+lg6GOfZ4PfOg5M=";
  };

  vendorHash = "sha256-3xyV1TaKK7tiKz6crKikTF4Hf7m1IOyBRJt36i2a4mU=";

  # Add your assets to the output
  postInstall = ''
    mkdir -p $out/assets
    cp -r assets/* $out/assets/
  '';

  meta.mainProgram = "blocky-ui";
}
