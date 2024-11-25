{
  #     _   ___         ______            ____
  #    / | / (_)  __   / ____/___  ____  / __/____
  #   /  |/ / / |/_/  / /   / __ \/ __ \/ /_/ ___/
  #  / /|  / />  <   / /___/ /_/ / / / / __(__  )
  # /_/ |_/_/_/|_|   \____/\____/_/ /_/_/ /____/
  description = "Top level NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      localConfig = {
        system = "aarch64-darwin";
        hostname = "Davids-MacBook-Pro-16";
        user = {
          name = "david_arutiunian";
          home = "/Users/david_arutiunian";
        };
      };
    in
    {
      darwinConfigurations = {
        ${localConfig.hostname} = nix-darwin.lib.darwinSystem {
          system = localConfig.system;

          specialArgs = {
            inherit self localConfig;
          };

          modules = [
            ./darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${localConfig.user.name} = import ./home.nix;
              };
            }
          ];
        };
      };

      darwinPackages = self.darwinConfigurations.${localConfig.hostname}.pkgs;
    };
}
