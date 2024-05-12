{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.openssl
          pkgs.python311
          pkgs.python311Packages.ansible
          pkgs.python311Packages.ansible-core
        ];
        shellHook = ''
          if [ ! -e "./venv" ]; then
            python -m venv ./venv
          fi
          . ./venv/bin/activate
        '';
      };
    };
}
