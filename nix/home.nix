{ pkgs, ... }:
{
  home.stateVersion = "24.05";
  home.username = "david_arutiunian";
  home.homeDirectory = "/Users/david_arutiunian";

  home.packages = [
    pkgs.git
    pkgs.neovim
    pkgs.ripgrep
    pkgs.nixfmt-rfc-style # nix code formatter
  ];

  xdg.enable = true;
  programs.home-manager.enable = true;
}
