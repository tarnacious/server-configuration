{ description = "{{ tarnbarford_fqdn }} website";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
    in {
      nixosConfigurations.{{ tarnbarford_vm_name }} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./configuration.nix ];
      };

      packages.${system}.{{ tarnbarford_vm_name }}-image = (
        import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
          inherit pkgs lib;
          config = self.nixosConfigurations.{{ tarnbarford_vm_name }}.config;
          name = "{{ tarnbarford_vm_name }}";
          baseName = "{{ tarnbarford_vm_name }}";
          format = "qcow2";
          diskSize = {{ tarnbarford_disk_size }} * 1024;
        }
      );

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.nixpkgs-fmt pkgs.nixd ];
      };
    };
}
