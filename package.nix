{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  bash,
  coreutils,
  jq,
  curl,
  desync,
  p7zip,
  xxHash,
}:

# YeetPatch: fetches the upstream tarball and provides
#   $out/share/yeetpatch          untouched copy, as shipped
#   $out/libexec/yeetpatch        script patched for Nix (see below)
#   $out/bin/yeetpatch            ready-to-run command
#
# Patches (each fails the build if upstream changes the line, so nothing
# silently stops working):
#   - desync is taken from nixpkgs instead of expected next to the script
#   - every config value can be set from the environment
#   - INSTALL_DIR defaults to ~/Games/VotV
#   - BACKUPS_DIR moves out of the (read-only) script folder into
#     $XDG_DATA_HOME/yeetpatch/backups
#   - help text says `yeetpatch` instead of the store path and drops the
#     "edit the script" / "desync next to the script" notes
stdenvNoCC.mkDerivation {
  pname   = "yeetpatch";
  version = "latest4";

  src = fetchurl {
    url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
    sha256 = "sha256-zlvwkHlixxudPagUDYnbBP/R4fFZbBE+lmS5Vngvjcs=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # The tarball has no top-level directory, so unpack into our own folder
  # (unpacking into "." would also pick up the builder's env-vars file)
  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xf $src -C source
    runHook postUnpack
  '';
  sourceRoot = "source";

  dontConfigure = true;
  dontBuild     = true;
  dontFixup     = true;   # keep share/ byte-for-byte as shipped

  installPhase = ''
    runHook preInstall

    # Untouched copy
    mkdir -p $out/share/yeetpatch
    cp -r . $out/share/yeetpatch/

    # Patched script
    mkdir -p $out/libexec/yeetpatch
    substitute YeetPatch.sh $out/libexec/yeetpatch/YeetPatch.sh \
      --replace-fail 'DESYNC_BIN="$SCRIPT_DIR/desync"' \
                     'DESYNC_BIN="$(command -v desync)"' \
      --replace-fail 'if [[ -x "$DESYNC_BIN" ]]; then' \
                     'if [[ -n "$DESYNC_BIN" ]]; then' \
      --replace-fail 'MANIFEST_URL="https://votv.dev/patcher_assets/patch_manifest.json"' \
                     'MANIFEST_URL="''${MANIFEST_URL:-https://votv.dev/patcher_assets/patch_manifest.json}"' \
      --replace-fail 'EXE_PATH=""' \
                     'EXE_PATH="''${EXE_PATH:-}"' \
      --replace-fail 'INSTALL_DIR=""' \
                     'INSTALL_DIR="''${INSTALL_DIR:-$HOME/Games/VotV}"' \
      --replace-fail 'CACHE_DIR=""' \
                     'CACHE_DIR="''${CACHE_DIR:-}"' \
      --replace-fail 'STORE_URL="https://votv.dev/patcher_assets/256-1024-4096-store"' \
                     'STORE_URL="''${STORE_URL:-https://votv.dev/patcher_assets/256-1024-4096-store}"' \
      --replace-fail 'SAVEGAME_DIR=""' \
                     'SAVEGAME_DIR="''${SAVEGAME_DIR:-}"' \
      --replace-fail 'INSTALL_CATALOG_URL="https://votv.dev/patcher_assets/index_manifest.json"' \
                     'INSTALL_CATALOG_URL="''${INSTALL_CATALOG_URL:-https://votv.dev/patcher_assets/index_manifest.json}"' \
      --replace-fail 'BACKUPS_DIR="$SCRIPT_DIR/backups"' \
                     'BACKUPS_DIR="''${BACKUPS_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/yeetpatch/backups}"' \
      \
      --replace-fail '$0 update' \
                     'yeetpatch update' \
      --replace-fail '$0 install' \
                     'yeetpatch install' \
      --replace-fail '(or set EXE_PATH in the script)' \
                     '(or set EXE_PATH)' \
      --replace-fail 'Config (edit at top of script):' \
                     'Config (environment variables; on NixOS also programs.yeetpatch.*):' \
      --replace-fail 'Where to fetch desync if missing (local ./desync used)' \
                     'Unused here: desync is provided by Nix' \
      --replace-fail 'desync binary is placed next to this script if not present.' \
                     'desync, 7z, jq, xxhsum and curl are provided by Nix.'

    # Command: runs the script through Nix's bash with every tool it checks
    # for first on PATH (7z, jq, xxhsum, sha256sum, curl, desync)
    makeWrapper ${bash}/bin/bash $out/bin/yeetpatch \
      --add-flags $out/libexec/yeetpatch/YeetPatch.sh \
      --prefix PATH : ${lib.makeBinPath [ desync jq curl p7zip xxHash coreutils ]}

    runHook postInstall
  '';

  meta = {
    description = "YeetPatch, the Voices of the Void patcher, ready to run on Nix";
    homepage    = "https://votv.dev";
    platforms   = [ "x86_64-linux" ];
    mainProgram = "yeetpatch";
  };
}