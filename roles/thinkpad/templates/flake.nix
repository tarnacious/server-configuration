{
  description = "Local NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-tarn.url = "github:tarnacious/nixpkgs";

    nvim-config = {
      url = "github:tarnacious/nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-tarn, nvim-config }:
    let
      system = "x86_64-linux";

      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${system};
      };

      overlay-tarn = final: prev: {
        pkgs-tarn = nixpkgs-tarn.legacyPackages.${system};
      };

      overlay-nvim = final: prev: {
        nvim-config-pkg = nvim-config.packages.${system}.default;
      };

    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ ... }: {
            nixpkgs.overlays = [
              overlay-unstable
              overlay-tarn
              overlay-nvim
            ];
          })
          ./configuration.nix
        ];
      };
    };
}

