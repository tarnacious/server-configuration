{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
          pkgs.python314
          pkgs.python314Packages.ansible
          pkgs.python314Packages.ansible-core
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
