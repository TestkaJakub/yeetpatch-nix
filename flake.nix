{
  description = "yeetpatch — Voices of the Void patcher, unpacked as shipped";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}