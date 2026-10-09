{ lib, stdenvNoCC, fetchurl }:

# YeetPatch: fetches the upstream tarball and unpacks it untouched.
# Contents end up in $out/share/yeetpatch.
stdenvNoCC.mkDerivation {
  pname   = "yeetpatch";
  version = "latest4";

  src = fetchurl {
    url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
    sha256 = "sha256-zlvwkHlixxudPagUDYnbBP/R4fFZbBE+lmS5Vngvjcs=";
  };

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
  dontFixup     = true;   # keep files byte-for-byte as shipped

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/yeetpatch
    cp -r . $out/share/yeetpatch/
    runHook postInstall
  '';

  meta = {
    description = "YeetPatch, the Voices of the Void patcher (unpacked as shipped)";
    homepage    = "https://votv.dev";
    platforms   = [ "x86_64-linux" ];
  };
}