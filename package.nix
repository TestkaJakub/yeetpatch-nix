{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  bash,
  jq,
  curl,
  desync,
}:

# YeetPatch: fetches the upstream tarball and provides
#   $out/share/yeetpatch          untouched copy, as shipped
#   $out/libexec/yeetpatch        script patched for Nix (see below)
#   $out/bin/yeetpatch            ready-to-run command
#
# Patches (each fails the build if upstream changes the line, so nothing
# silently stops working):
#   - desync is taken from nixpkgs instead of expected next to the script
#   - INSTALL_DIR can be set from the environment, defaulting to ~/Games/VotV
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
      --replace-fail 'DESYNC_BIN="$SCRIPT_DIR/desync"' 'DESYNC_BIN="$(command -v desync)"' \
      --replace-fail 'if [[ -x "$DESYNC_BIN" ]]; then' 'if [[ -n "$DESYNC_BIN" ]]; then' \
      --replace-fail 'INSTALL_DIR=""' 'INSTALL_DIR="''${INSTALL_DIR:-$HOME/Games/VotV}"'

    # Command: runs the script through Nix's bash (no reliance on its shebang)
    # with its tools first on PATH
    makeWrapper ${bash}/bin/bash $out/bin/yeetpatch \
      --add-flags $out/libexec/yeetpatch/YeetPatch.sh \
      --prefix PATH : ${lib.makeBinPath [ desync jq curl ]}

    runHook postInstall
  '';

  meta = {
    description = "YeetPatch, the Voices of the Void patcher, ready to run on Nix";
    homepage    = "https://votv.dev";
    platforms   = [ "x86_64-linux" ];
    mainProgram = "yeetpatch";
  };
}