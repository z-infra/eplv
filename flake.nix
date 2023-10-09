{
  description = "Phoenix Liveview Workspace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/2f3b6b3fcd9f";
    utils.url = "github:numtide/flake-utils";
    compat.url = "github:nix-community/flake-compat";
  };

  outputs = { self, nixpkgs, utils, compat }:
    utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = rec {
          main = pkgs.hello;
          default = main;
        };
        apps = rec {
          main = utils.lib.mkApp { drv = self.packages.${system}.default; };
          default = main;
        };
        devShells = rec {
          main = import ./devShell.nix { inherit pkgs; };
          default = main;
        };
      });

}
