{
  callPackage,
  floppy-src,
  lib,
  makeWrapper,
  pyproject-build-systems,
  pyproject-nix,
  python312,
  stdenvNoCC,
  uv2nix,
}:

let
  version = "26.9.10";
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = floppy-src; };
  pythonSet = (callPackage pyproject-nix.build.packages { python = python312; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
    ]
  );
  virtualenv = pythonSet.mkVirtualEnv "floppy-${version}-env" workspace.deps.default;
  wrapperArgs = ''
    --set-default COMMIT_SHA "${floppy-src.rev}" \
    --set-default VERSION "${version}"
  '';
in
stdenvNoCC.mkDerivation {
  pname = "floppy";
  inherit version;
  src = floppy-src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/floppy "$TMPDIR/data" "$TMPDIR/logs"
    cp -R src/. $out/lib/floppy/
    chmod -R u+w $out/lib/floppy

    SECRET=build-time-placeholder \
      FLOPPY_DATA_DIR="$TMPDIR/data" \
      LOG_DIR="$TMPDIR/logs" \
      ${virtualenv}/bin/python $out/lib/floppy/manage.py collectstatic --noinput

    makeWrapper ${virtualenv}/bin/python $out/bin/floppy-manage \
      --add-flags "$out/lib/floppy/manage.py" \
      ${wrapperArgs}
    makeWrapper ${virtualenv}/bin/gunicorn $out/bin/floppy \
      --add-flags "--chdir $out/lib/floppy" \
      --add-flags "--config python:config.gunicorn" \
      --add-flags "config.wsgi:application" \
      ${wrapperArgs}
    makeWrapper ${virtualenv}/bin/celery $out/bin/floppy-celery \
      --add-flags "--workdir $out/lib/floppy" \
      ${wrapperArgs}
    makeWrapper ${virtualenv}/bin/floppy-mcp $out/bin/floppy-mcp

    runHook postInstall
  '';

  meta = {
    description = "Self-hosted all-in-one media tracker";
    homepage = "https://github.com/dannyvfilms/Floppy";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "floppy";
  };
}
