{
  writeShellApplication,
  src,
  keymap,
  stdenv,
  pkgs,
  ...
}:
let
  keymap-result = stdenv.mkDerivation {
    name = "keymap";
    inherit src;
    nativeBuildInputs = [ pkgs.keymap-drawer ];

    unpackPhase = ''
      cp -r $src/config .
    '';

    configurePhase = ''
      ls -la
      keymap parse --zmk-keymap config/${keymap} >keymap.yaml
      keymap draw keymap.yaml >keymap.svg
    '';

    installPhase = ''
      mkdir $out
      cp keymap.svg $out/
      chmod +w $out/keymap.svg
    '';
  };
in
writeShellApplication {
  name = "copy-keymap";
  text = ''
    cp ${keymap-result}/keymap.svg .
  '';
}
