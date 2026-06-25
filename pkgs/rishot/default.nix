{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,

  bash,
  cliphist,
  coreutils,
  curl,
  imagemagick,
  kdePackages,
  libnotify,
  niri,
  quickshell,
  qt6,
  util-linux,
  wl-clipboard,
  xdg-utils,
}:

let
  qmlModules = [
    quickshell
    qt6.qt5compat
    qt6.qtdeclarative
    qt6.qtwayland
  ];
  qtPluginModules = [
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
  ];
  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" qmlModules;
  qtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" qtPluginModules;
  runtimePath = lib.makeBinPath [
    bash
    cliphist
    coreutils
    curl
    imagemagick
    kdePackages.kdialog
    libnotify
    niri
    quickshell
    util-linux
    wl-clipboard
    xdg-utils
  ];
in
stdenvNoCC.mkDerivation {
  pname = "rishot";
  version = "unstable-2026-06-23";

  src = fetchFromGitHub {
    owner = "Gakuseei";
    repo = "rishot";
    rev = "f05f53e8b5f3e47952b3c25567a097b66ceb2a49";
    hash = "sha256-NmYCNSwMBgfma2KjGF8nElswK4QxaIyLPjJQg3OwvOQ=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/rishot
    cp -R src $out/share/rishot/src

    install -Dm755 bin/rishot $out/bin/rishot
    install -Dm644 rishot.desktop $out/share/applications/rishot.desktop
    install -Dm644 packaging/rishot.svg $out/share/icons/hicolor/scalable/apps/rishot.svg
    install -Dm644 packaging/rishot.svg $out/share/rishot/src/rishot.svg
    install -Dm644 README.md $out/share/doc/rishot/README.md
    install -Dm644 LICENSE $out/share/licenses/rishot/LICENSE

    patchShebangs $out/bin/rishot
    wrapProgram $out/bin/rishot \
      --set-default RISHOT_CONFIG_DIR $out/share/rishot/src \
      --prefix QML_IMPORT_PATH : ${qmlImportPath} \
      --prefix QML2_IMPORT_PATH : ${qmlImportPath} \
      --prefix QT_PLUGIN_PATH : ${qtPluginPath} \
      --prefix PATH : ${runtimePath}

    runHook postInstall
  '';

  meta = {
    description = "Wayland screenshot and annotation overlay built on Quickshell";
    homepage = "https://github.com/Gakuseei/rishot";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "rishot";
  };
}
