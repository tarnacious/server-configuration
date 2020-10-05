with import <nixpkgs> {};
let
  my-python-packages = python-packages: [
    python-packages.pip
  ];
  my-python = python37.withPackages my-python-packages;
in
  pkgs.mkShell {
    buildInputs = [
      bashInteractive
      my-python
      libffi
      openssl
      libxml2
      libxslt
    ];
    shellHook = ''
      export PIP_PREFIX="$(pwd)/.build/pip_packages"
      export PATH=$PATH:$PIP_PREFIX/bin
      export PATH=$PATH:$(pwd)/scripts
      export PYTHONPATH="$(pwd)/.build/pip_packages/lib/python3.7/site-packages:$PYTHONPATH"
      unset SOURCE_DATE_EPOCH
    '';
  }
