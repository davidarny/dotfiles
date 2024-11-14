{ pkgs, ... }:
{
  home.stateVersion = "24.05";
  home.username = "david_arutiunian";
  home.homeDirectory = "/Users/david_arutiunian";

  home.packages = [
    pkgs.git
    pkgs.neovim
    pkgs.nixfmt-rfc-style # nix code formatter
  ];

  # home.file.".config" = { source = ../.config; recursive = true; };
  # home.file.".git" = { source = ../.git; recursive = true; };
  # home.file.".local" = { source = ../.local; recursive = true; };
  # home.file.".ssh" = { source = ../.ssh; recursive = true; };

  xdg.enable = true;
  programs.home-manager.enable = true;
}
