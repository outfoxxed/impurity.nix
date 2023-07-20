{ lib, config, pkgs, ... }: with lib; let
  relativePath = path: assert types.path.check path;
    with builtins; strings.removePrefix (toString config.impurity.configRoot) (toString path);

  impurityGroupEnabled = group: let
    impurityGroups = strings.splitString " " (builtins.getEnv "IMPURITY_GROUPS");
  in group == "*" || builtins.elem group impurityGroups;

  impurePath = let
    impurePathEnv = builtins.getEnv "IMPURITY_PATH";
  in if impurePathEnv == ""
     then throw "impurity.enable is true but IMPURITY_PATH is not set"
     else impurePathEnv;

  createImpurePath = path: let
    relative = (relativePath path);
    full = impurePath + relative;
  in pkgs.runCommand "impurity-${relative}" {} "ln -s ${full} $out";

in {
  options.impurity = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable impure symlinks";
    };

    configRoot = mkOption {
      type = types.path;
      description = "The root of your nixos configuration";
    };
  };

  config._module.args.impurity = rec {
    groupedLink = groupspec: path:
      assert types.path.check path; let
        groups =
          if groupspec == null
          then [ "" ]
          else if (types.listOf types.string).check groupspec
               then groupspec
               else assert types.string.check groupspec;
                 strings.splitString " " groupspec;
      in if config.impurity.enable && lists.any (group: impurityGroupEnabled group) groups
         then createImpurePath path
         else path;

    link = path: groupedLink null path;
  };
}
