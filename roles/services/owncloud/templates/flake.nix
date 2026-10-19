{ description = "ownCloud Infinite Scale";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          (import ./ocis-overlay.nix)
        ];
      };
      lib = pkgs.lib;
    in {
      nixosConfigurations.owncloud = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix

          {
            nixpkgs.overlays = [
              (import ./ocis-overlay.nix)
            ];
          }
        ];
      };

      packages.${system}.owncloud-image = (
        import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
          inherit pkgs lib;
          config = self.nixosConfigurations.owncloud.config;
          name = "owncloud";
          baseName = "owncloud";
          format = "qcow2";
          diskSize = 20 * 1024;
        }
      );

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.nixpkgs-fmt pkgs.nixd ];
      };
    };
}
