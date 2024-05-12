{
  description = "Basic NixOS System Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    trains.url = "github:tarnacious/train-tracker";
  };

  outputs = { self, nixpkgs, trains }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          trains = trains;
        };
        modules = [
          ({ config, pkgs, ... }: {})
          ./configuration.nix
        ];
      };
    };
}
