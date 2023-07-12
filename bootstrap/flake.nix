{
  description = "Shell to bootstrap a nix nixos machine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    nixpkgs-tarn.url = "github:tarnacious/nixpkgs/nitrocli";
  };

  outputs = { self, nixpkgs, nixpkgs-tarn }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      pkgs-tarn = import nixpkgs-tarn {
        inherit system;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs-tarn.nitrocli
        ];
      };
    };
}
