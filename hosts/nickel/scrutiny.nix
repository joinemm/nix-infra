{ pkgs, ... }:
let
  # Backport https://github.com/AnalogJ/scrutiny/pull/1119 until released.
  # Pin both ends of the diff so later PR updates cannot change this build.
  scsiTemperaturePatch = pkgs.fetchurl {
    name = "scrutiny-scsi-temperature.patch";
    url = "https://github.com/AnalogJ/scrutiny/compare/ac2056d6c3cef4a8dd6fe3e0b8c002d9595da75f...3f2edcae43cd20ebf8d2d52113409e923a669b32.diff";
    hash = "sha256-qT7wfFhlwdzKsv4Rj7JTUSv4bHV6zQ19FuYBR4zYwYA=";
  };
  withScsiTemperature =
    package:
    package.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ scsiTemperaturePatch ];
    });
in
{
  services.scrutiny = {
    enable = true;
    package = (withScsiTemperature pkgs.scrutiny).overrideAttrs (old: {
      postCheck = (old.postCheck or "") + ''
        go test ./webapp/backend/pkg/models/collector ./webapp/backend/pkg/models/measurements
      '';
    });
    collector.enable = true;
    collector.package = withScsiTemperature pkgs.scrutiny-collector;
    settings.web.listen.port = 5500;
  };
}
