{
  fetchFromGitHub,
  rustPlatform,
  pkgs,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "hypruler";
  version = "0.2.2";

  nativeBuildInputs = with pkgs; [
    pkg-config
    fontconfig
  ];

  buildInputs = with pkgs; [
    pkg-config
    libxkbcommon
  ];

  src = fetchFromGitHub {
    owner = "t4t5";
    repo = "hypruler";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cq59L3a6W0tp+fBgKsyACxA5cphVsaJmwBqatj/k5aw=";
  };

  cargoHash = "sha256-9ArhwLPFwyyD7lkgJ9nOxQcoS5ApfcUIvNdRiUafhu4=";
})
