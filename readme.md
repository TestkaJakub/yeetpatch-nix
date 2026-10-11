# 🛸 yeetpatch-nix (v1.0.0)

A simple Nix flake that packages the [YeetPatch](https://votv.dev) patcher for Voices of the Void as a ready-to-run `yeetpatch` command, with everything it needs already in place.

## Functionality

| Command                     | Description                             | Example                                   |
| --------------------------- | --------------------------------------- | ----------------------------------------- |
| `update <path/to/VotV.exe>` | Updates an existing install             | `yeetpatch update ~/Games/VotV/VotV.exe`  |
| `install`                   | Installs the game into `INSTALL_DIR`    | `yeetpatch install`                       |
| `install -c <dir>`          | Installs using a custom cache directory | `yeetpatch install -c ~/.cache/yeetpatch` |
| `install --no-backup`       | Installs without keeping a backup       | `yeetpatch install --no-backup`           |

## Installation

### Nix (flakes)

Run without installing:

```sh
nix run github:TestkaJakub/yeetpatch-nix -- update ~/Games/VotV/VotV.exe
```

Install to your profile:

```sh
nix profile add github:TestkaJakub/yeetpatch-nix
```

### NixOS

Add yeetpatch-nix as a flake input:

```nix
# flake.nix
inputs.yeetpatch = {
  url                    = "github:TestkaJakub/yeetpatch-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then either enable the module (recommended, see [NixOS module](#nixos-module)):

```nix
imports = [ inputs.yeetpatch.nixosModules.default ];
programs.yeetpatch.enable = true;
```

or just add the package:

```nix
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

## Configuration

Upstream expects you to edit these at the top of the script. Here they're read from the environment instead:

| Variable              | Default                            | Description                             |
| --------------------- | ---------------------------------- | --------------------------------------- |
| `INSTALL_DIR`         | `~/Games/VotV`                     | Destination folder for `install`        |
| `EXE_PATH`            | *(empty)*                          | Default path to `VotV.exe` for `update` |
| `CACHE_DIR`           | *(empty, no cache)*                | desync cache folder (or pass `-c`)      |
| `SAVEGAME_DIR`        | *(empty, no backup)*               | Saves folder to back up as `.tar.gz`    |
| `BACKUPS_DIR`         | `~/.local/share/yeetpatch/backups` | Where save backups go                   |
| `NOTICE_URL`          | upstream notice                    | Startup notice; set empty to disable    |
| `MANIFEST_URL`        | upstream manifest                  | Patch manifest                          |
| `STORE_URL`           | upstream store                     | desync store                            |
| `INSTALL_CATALOG_URL` | upstream catalog                   | Version catalog (or pass `--catalog`)   |

```sh
INSTALL_DIR=~/somewhere/else yeetpatch install
```

### NixOS module

On NixOS the same settings can be set declaratively. They become the defaults of the `yeetpatch` command, and environment variables still override them per run.

```nix
programs.yeetpatch = {
  enable     = true;
  installDir = "/home/you/Games/VotV";
  exePath    = "/home/you/Games/VotV/WindowsNoEditor/VotV.exe";
  cacheDir   = "/home/you/.cache/yeetpatch";

  launcher = {
    enable          = true;                # "Update VotV" app-launcher entry
    terminalCommand = "wezterm start --";
  };
};
```

| Option                      | Description                                                                    |
| --------------------------- | ------------------------------------------------------------------------------ |
| `enable`                    | Install the `yeetpatch` command                                                |
| `package`                   | The yeetpatch package to use                                                   |
| `installDir`                | `INSTALL_DIR`                                                                  |
| `exePath`                   | `EXE_PATH`, so `yeetpatch update` works without an argument                    |
| `cacheDir`                  | `CACHE_DIR`                                                                    |
| `saveGameDir`               | `SAVEGAME_DIR`                                                                 |
| `backupsDir`                | `BACKUPS_DIR`                                                                  |
| `noticeUrl`                 | `NOTICE_URL`; `""` disables the notice, `null` keeps upstream's                |
| `extraEnvironment`          | Any other variable, e.g. `{ STORE_URL = "…"; }`                                |
| `launcher.enable`           | Add an "Update VotV" app-launcher entry (requires `exePath`)                   |
| `launcher.terminalCommand`  | Terminal prefix for the entry, e.g. `"wezterm start --"`; `null` = `Terminal=true` |

Paths must be absolute strings: `~` and `$HOME` are not expanded.

### What the package does for you

- puts every tool the script checks for (`desync`, `7z`, `jq`, `xxhsum`, `sha256sum`, `curl`) on its PATH, so nothing needs to sit next to the script,
- reads all config from the environment instead of requiring edits to the script,
- moves save backups out of the script folder, which is read-only in the Nix store,
- runs the script through Nix's `bash`.

Each patch fails the build if upstream changes the line it targets, so an update can't silently break the command. The original, untouched files are kept in `share/yeetpatch`.

## Versioning

Tags follow `v<version>-nixos-<release>`:

- `<version>` is the version of this packaging ([semver](https://semver.org)). Upstream YeetPatch has no version number of its own.
- `<release>` is the NixOS release the tag targets.

| Tag                  | NixOS |
| -------------------- | ----- |
| `v1.0.0-nixos-26.05` | 26.05 |
| `v1.0.0-nixos-25.11` | 25.11 |

The default branch always targets the current NixOS release. To pin a version, or to stay on an older release, use a tag as the flake ref:

```nix
inputs.yeetpatch.url = "github:TestkaJakub/yeetpatch-nix/v1.0.0-nixos-25.11";
```

## Updating

The upstream URL always points at the latest release, so the build fails with a hash mismatch whenever YeetPatch publishes a new version. To update:

1. replace `sha256` in `package.nix` with the hash Nix reports,
2. bump the patch version (e.g. `1.0.0` → `1.0.1`) in `package.nix` and in this README's title,
3. commit and tag it, e.g. `v1.0.1-nixos-26.05`.

## Contributing

Issues and pull requests are welcome. For bigger changes, please open an issue first to discuss what you'd like to change.

## License

This repository only contains Nix packaging. YeetPatch itself is not part of this repository; it is downloaded from [votv.dev](https://votv.dev) at build time and remains under its authors' terms.