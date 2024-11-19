#!/usr/bin/env bash

stow --adopt --target="$HOME" .

# check if --only-stow is set
only_stow=false
if [[ "$1" == "--only-stow" ]]; then
  only_stow=true
fi

# if --only-stow is not true then run home-manager and darwin-rebuild
if [[ "$only_stow" == false ]]; then
  home-manager switch --flake ./nix --impure --verbose
  darwin-rebuild switch --flake ./nix --impure --verbose
fi
