#!/usr/bin/env bash

stow --adopt --target="$HOME" .
home-manager switch --flake ./nix --impure --verbose
darwin-rebuild switch --flake ./nix --impure --verbose
