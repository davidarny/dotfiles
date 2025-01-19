# This file manages user-specific packages and configurations
{ pkgs, ... }:
{
  # Specify the state version to use for Home Manager
  home.stateVersion = "24.05";

  # User packages to install
  home.packages = with pkgs; [
    neovim
    ripgrep
  ];

  # Enable home-manager
  programs.home-manager.enable = true; # Required for home-manager to work properly
}
