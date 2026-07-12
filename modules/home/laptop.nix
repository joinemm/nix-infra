{
  services.poweralertd = {
    enable = true;
    extraArgs = [
      "-s"
      "-i"
      "line power"
    ];
  };
}
