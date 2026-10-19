{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

{
  pname,
  version,
  hash,
}:

stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/owncloud/ocis/releases/download/v${version}/ocis-${version}-linux-amd64";
    inherit hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  installPhase = ''
    install -Dm755 "$src" "$out/bin/ocis"
  '';

  meta = {
    description = "ownCloud Infinite Scale";
    homepage = "https://owncloud.com/";
    license = lib.licenses.asl20;
    mainProgram = "ocis";
    platforms = [ "x86_64-linux" ];
  };
}
