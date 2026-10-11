{
  description = "yeetpatch — Voices of the Void patcher, ready to run on Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        yeetpatch = pkgs.callPackage ./package.nix { };
        default   = yeetpatch;
      });

      overlays.default = final: _prev: {
        yeetpatch = final.callPackage ./package.nix { };
      };

      nixosModules = rec {
        yeetpatch = import ./module.nix self;
        default   = yeetpatch;
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}