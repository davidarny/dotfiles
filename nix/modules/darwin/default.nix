# This file configures macOS system-level settings using nix-darwin
{ systemConfig, ... }:
{
  # Import other modules
  imports = [
    ./caddy
    ./preferences
  ];

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true; # Allow proprietary software
  };

  # Nix package manager configuration
  nix = {
    # Automatic optimization of nix store
    optimise.automatic = true;

    # Nix daemon settings
    settings = {
      experimental-features = [
        "flakes" # Enable flakes support
        "nix-command" # Enable new nix command-line interface
      ];
      trusted-users = [
        "@admin" # Trust admin users
        systemConfig.user.name
      ];
    };

    # Garbage collection settings
    gc = {
      automatic = true;
      options = "--delete-older-than 30d"; # Remove packages older than 30 days
    };
  };

  # macOS system configuration
  system.stateVersion = 5; # System configuration version

  # Enable the Nix daemon service
  services.nix-daemon.enable = true;

  # User configuration
  users.users.${systemConfig.user.name} = {
    name = systemConfig.user.name;
    home = systemConfig.user.home;
  };
}
