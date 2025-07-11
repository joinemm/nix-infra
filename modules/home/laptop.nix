{
  services.poweralertd = {
    enable = true;
    extraArgs = [
      "-i"
      "line power"
    ];
  };
}
