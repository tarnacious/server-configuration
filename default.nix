with import <nixpkgs> {};
let
  my-python-packages = python-packages: [
    python-packages.pip
  ];
  my-python = python36.withPackages my-python-packages;
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
      export PIP_PREFIX="$(pwd)/_build/pip_packages"
      export PYTHONPATH="$(pwd)/_build/pip_packages/lib/python3.6/site-packages:$PYTHONPATH" 
      unset SOURCE_DATE_EPOCH
    '';
  }
