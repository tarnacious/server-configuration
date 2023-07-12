{
  description = "Shell to bootstrap a nix nixos machine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    nixpkgs-tarn.url = "github:tarnacious/nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-tarn }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          nixpkgs-tarn.nitrocli
        ];
      };
    };
}
