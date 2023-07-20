# impurity.nix
impurity.nix is a nixos module for creating impure symlinks
to (usually configuraton) files.

### Why
Have you ever stored something like a configuration file you
aren't yet sure of, or a css style you've been tweaking in your
nixos configuration? It's rather slow to repeatedly `nixos-rebuild switch`
the system for every change, as each run usually takes a couple seconds.
impurity.nix allows changes to be made in real time.

Another case is when changing a program's settings through it's settings
interface. Usually if you lock an application's config files into nix, changes
made through the application don't persist as it can't save the files.
impurity.nix allows the application to change its configuration files
*inside* of your nix configuration.

### How
impurity.nix creates an intermediary symlink from the target file to the
corrosponding file in your nix configuration. This allows it to be seamlessly
modified by you or the application.

# Usage

### Module Setup
Add impurity to your nixos configuration, specifying the config root, and
create an additional impure system output.

```nix
# flake.nix

{
  inputs.impurity.url = "github:outfoxxed/impurity.nix";

  outputs = { self, nixpkgs, impurity, ... }: {
    nixosConfigurations = {
      example = nixpkgs.lib.nixosSystem {
        modules = [
          {
            imports = [ impurity.nixosModules.impurity ];
            impurity.configRoot = self;
          }

          # ...
        ];

        # ...
      };

      example-impure = self.nixosConfigurations.example.extendModules
        { modules = [ { impurity.enable = true; } ] };
    };
  };
}
```

To create impure symlinks, switch your configuration to the impure output.
You must set the environment variable `IMPURITY_PATH` to your config root.

Note: to access environment variables from a flake evaluation you must pass `--impure`.

Running this command from your config directory will impurely link specified files.
```sh
$ IMPURITY_PATH=$(pwd) sudo --preserve-env=IMPURITY_PATH nixos-rebuild switch --flake --impure .#example-impure
```
An alias or helper script is advised.

Changes made to linked files will be applied to the files inside your configuration. To lock your configuration back to a pure state after changes have been made, just switch to your normal configuration with `impurity.enable` set to `false`.

### Creating Impurity Links
impurity.nix adds an `impurity` attribute to the nixos module arguments.
This means you can directly access it from all modules.

The `link` function provided by the `impurity` attribute creates a direct symlink
when impurity is enabled, or references the path normally otherwise.

Example module:
```nix
{ impurity, ... }: {
  home-manager.users.example-user = {
    xdg.configFile."foobar.conf" = impurity.link ./foobar.conf;
  };
}
```

`foobar.conf` will be symlinked to the file in your nix config when
`impurity.enable` is true, or interpreted normally when it is false.

### Impurity Groups
Granular groups of impure symlinks may be created via `impurity.groupedLink`.

Example module:
```nix
{ impurity, ... }: {
  home-manager.users.example-user = {
    xdg.configFile."foo.conf" = impurity.link ./foo.conf;
    xdg.configFile."bar.conf" = impurity.groupedLink "bar" ./bar.conf;
    xdg.configFile."baz.conf" = impurity.groupedLink "baz" ./baz.conf;
  };
}
```

When `impurity.enable` is true, `foo.conf` will be unconditionally symlinked.
`bar.conf` and `baz.conf` are both conditionally symlinked based on the `bar` and `baz`
groups respectively.

Impurity groups can be enabled via the `IMPURITY_GROUPS` environment variable. It takes a space separated list of groups, or `*` to enable all groups. Don't forget to pass the `IMPURITY_GROUPS` variable into sudo.

Example command enabling `foo.conf` and `bar.conf` but not `baz.conf`:
```sh
$ IMPURITY_PATH=$(pwd) IMPURITY_GROUPS="bar" sudo --preserve-env=IMPURITY_PATH,IMPURITY_GROUPS nixos-rebuild switch --flake --impure .#example-impure
```
