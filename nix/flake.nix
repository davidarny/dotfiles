{
  description = "NixOS configuration for macOS using nix-darwin";

  # Inputs are external dependencies that this flake uses
  inputs = {
    # Stable Nix Packages collection
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nix-darwin for macOS system configuration
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
    }:
    let
      # System-wide configuration settings
      systemConfig = {
        system = "aarch64-darwin"; # Apple Silicon macOS
        hostname = "Davids-MacBook-Pro-16";
        user = {
          name = "david_arutiunian";
          home = "/Users/david_arutiunian";
        };
      };
    in
    {
      # Darwin system configuration
      darwinConfigurations = {
        ${systemConfig.hostname} = nix-darwin.lib.darwinSystem {
          system = systemConfig.system;

          # Pass special arguments to all modules
          specialArgs = {
            inherit systemConfig;
          };

          # System configuration modules
          modules = [
            # Base Darwin configuration
            ./modules/darwin

            # home-manager configuration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${systemConfig.user.name} = import ./modules/home;
              };
            }
          ];
        };
      };
    };
}
