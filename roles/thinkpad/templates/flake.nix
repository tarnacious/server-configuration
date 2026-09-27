{
  description = "Local NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-tarn.url = "github:tarnacious/nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";

    nvim-config = {
      url = "github:tarnacious/nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-tarn, llm-agents, nvim-config }:
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

      overlay-llm-agents = final: prev: {
        llm-agents = llm-agents.packages.${system};
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
              overlay-llm-agents
            ];
          })
          ./configuration.nix
        ];
      };
    };
}

