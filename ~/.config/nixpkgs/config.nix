{
  allowUnfreePredicate = pkg: builtins.elem (builtins.parseDrvName pkg.name).name [
    "google-chrome"
  ];
}
