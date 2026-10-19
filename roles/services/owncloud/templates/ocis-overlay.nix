final: prev:

let
  mkOcis = import ./ocis-bin.nix {
    inherit (final)
      lib
      stdenv
      fetchurl
      autoPatchelfHook
      ;
  };
in
{
  ocis_5-bin = mkOcis {
    pname = "ocis_5-bin";
    version = "5.0.9";
    hash = "sha256-tmUfDKLO35qCs1hauJQKhJhcnMhqOpcqDFtAggMFhLE=";
  };

  ocis_70-bin = mkOcis {
    pname = "ocis_70-bin";
    version = "7.0.1";
    hash = "sha256-MOLyuhslnKJlCbCgm+bAg/K1pFk8Q8miREOuap3egBQ=";
  };

  ocis_71-bin = mkOcis {
    pname = "ocis_71-bin";
    version = "7.1.4";
    hash = "sha256-l+x+pd95nDznGu7i7PQr6v56bA4ajO2Q+SE/8XYBMPc=";
  };

  ocis_72-bin = mkOcis {
    pname = "ocis_72-bin";
    version = "7.2.0";
    hash = "sha256-SPnT8OrEcYl/MlUhl7hnDl1SZHF+WV/+D33bfnFbSoY=";
  };

  ocis_73-bin = mkOcis {
    pname = "ocis_73-bin";
    version = "7.3.2";
    hash = "sha256-gS5EGYJoPZQjkHf48h4+nc5xQV09kERr161ZbEnCI7k=";
  };

  ocis_80-bin = mkOcis {
    pname = "ocis_80-bin";
    version = "8.0.6";
    hash = "sha256-DU+cs+uh1aYpx7QVFS60BIvOlv5cWE9phOjsbSoB1zo=";
  };

  ocis_81-bin = mkOcis {
    pname = "ocis_81-bin";
    version = "8.1.0";
    hash = "sha256-jhGTMZkegKZYQAiEwX5LX9irUuBzrhMzhlAKXVUD6yU=";
  };
}
