{
  description = "NixOS configuration with two or more channels";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-tarn.url = "github:tarnacious/nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-tarn }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        # use this variant if unfree packages are needed:
        # unstable = import nixpkgs-unstable {
        #   inherit system;
        #   config.allowUnfree = true;
        # };

      };
      overlay-tarn = final: prev: {
        pkgs-tarn = nixpkgs-tarn.legacyPackages.${prev.system};
      };
    in {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Overlays-module makes "pkgs.unstable" available in configuration.nix
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable overlay-tarn ]; })
          ./configuration.nix
        ];
      };
    };
}

