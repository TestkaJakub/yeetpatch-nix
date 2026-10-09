# 🛸 yeetpatch-nix

A simple Nix flake that fetches the [YeetPatch](https://votv.dev) Linux tarball for Voices of the Void and unpacks it as-is, untouched.

## Contents

After building, the unpacked tarball lives in `share/yeetpatch`:

| Where                                      | When                                 |
| ------------------------------------------ | ------------------------------------ |
| `result/share/yeetpatch`                   | after `nix build`                    |
| `/run/current-system/sw/share/yeetpatch`   | on NixOS, after adding to packages   |

## Installation

### Nix (flakes)

Build without installing:

```sh
nix build github:TestkaJakub/yeetpatch-nix
ls result/share/yeetpatch
```

On NixOS, add yeetpatch-nix as a flake input and include it in your packages:

```nix
# flake.nix
inputs.yeetpatch.url = "github:TestkaJakub/yeetpatch-nix";

# configuration.nix
environment.systemPackages = [
  inputs.yeetpatch.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

### Nix (without flakes)

```sh
git clone https://github.com/TestkaJakub/yeetpatch-nix.git
cd yeetpatch-nix
nix-build -E 'with import <nixpkgs> {}; callPackage ./package.nix {}'
```

## Updating

The upstream URL always points at the latest release, so the build fails with a hash mismatch whenever YeetPatch publishes a new version. Replace `sha256` in `package.nix` with the hash Nix reports and bump `version`.

## Contributing

Issues and pull requests are welcome. For bigger changes, please open an issue first to discuss what you'd like to change.

## License

This repository only contains Nix packaging. YeetPatch itself is not part of this repository; it is downloaded from [votv.dev](https://votv.dev) at build time and remains under its authors' terms.