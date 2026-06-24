{
  lib,
  rustPlatform,
  stdenv,
  fetchFromGitHub,

  cargo-tauri,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  pkg-config,
  wrapGAppsHook4,

  glib,
  libayatana-appindicator,
  librsvg,
  openssl,
  webkitgtk_4_1,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dev-manager-desktop";
  version = "1.99.18";

  src = fetchFromGitHub {
    owner = "webosbrew";
    repo = "dev-manager-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5N/sW8GIu5HrDYNXt8Kb3vmgBubC1bN0qQRKHW5fPjM=";
  };

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    hash = "sha256-HLpJpOiiwJVEzqW8mvvlWQczaS0V+phhAJo7HM+GxtA=";
  };

  cargoHash = "sha256-FE2XXDuK89wYEDOzdYkUEybtz34qjQbTshjoN9ovy4s=";

  nativeBuildInputs = [
    cargo-tauri.hook
    npmHooks.npmConfigHook
    nodejs
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = [
    glib
    libayatana-appindicator
    librsvg
    openssl
    webkitgtk_4_1
  ];

  checkFlags = [
    # test requires networking?
    "--skip=conn_pool::cmd::test::execute_command_timeout"

    # tests requiring Docker
    "--skip=conn_pool::cmd::test::execute_command_wrongpass"
    "--skip=conn_pool::cmd::test::execute_command_whoami_keyauth"
    "--skip=conn_pool::cmd::test::execute_command_false"
    "--skip=conn_pool::cmd::test::execute_command_noauth"
    "--skip=conn_pool::cmd::test::execute_command_whoami"
  ];

  preFixup = ''
    # https://github.com/tauri-apps/tauri/issues/10702
    gappsWrapperArgs+=(--set-default __NV_DISABLE_EXPLICIT_SYNC 1)
  '';

  meta = {
    description = "Simple tool to manage developer mode enabled or rooted webOS TV";
    license = lib.licenses.asl20;
    homepage = "https://github.com/webosbrew/dev-manager-desktop";
    mainProgram = "webos-dev-manager";
  };
})
