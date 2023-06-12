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
          pkgs.python310
          pkgs.python310Packages.virtualenv
          pkgs.python310Packages.lxml
        ];
      };
    };
}
