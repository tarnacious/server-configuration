{
  description = "Australia DigitalOcean image";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.australia = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix ];
    };
    packages.${system} = {
      image = self.nixosConfigurations.australia.config.system.build.digitalOceanImage;
      default = self.packages.${system}.image;
    };
  };
}
