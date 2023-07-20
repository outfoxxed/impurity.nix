{
  outputs = _: {
    nixosModules = rec {
      impurity = import ./impurity.nix;
      default = impurity;
    };
  };
}
