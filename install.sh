#!/bin/bash

function ask() {
	read -p "$1 (Y/n): " resp
	if [ -z "$resp" ]; then
		response_lc="y"
	else
		response_lc=$(echo "$resp" | tr '[:upper:]' '[:lower:]')
	fi

	[ "$response_lc" = "y" ]
}

if ask "Do you want to install vim?"; then
	stow --target $HOME vim
fi

if ask "Do you want to install zsh?"; then
	mkdir -p $HOME/.config/zsh
	stow --target $HOME/.config/zsh zsh
	stow --target $HOME zshrc
fi

if ask "Do you want to install nvim?"; then
	mkdir -p $HOME/.config/nvim
	stow --target $HOME/.config/nvim nvim
fi

if ask "Do you want to install git?"; then
	stow --target $HOME git
fi

if ask "Do you want to install tmux?"; then
	stow --target $HOME tmux
fi

if ask "Do you want to install bin?"; then
	stow --target $HOME/.local/bin bin
fi

if ask "Do you want to install zellih?"; then
	mkdir -p $HOME/.config/zellij/layout
	stow --target $HOME/.config/zellij zellij
fi
