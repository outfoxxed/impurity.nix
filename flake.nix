{
  outputs = _: {
    nixosModules = rec {
      impurity = import ./default.nix;
      default = impurity;
    };
  };
}
