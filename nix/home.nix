{ pkgs, ... }:
{
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    neovim
    ripgrep
    nixfmt-rfc-style # nix code formatter
  ];

  programs.home-manager.enable = true;
}
