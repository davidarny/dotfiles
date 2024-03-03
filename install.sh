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

if ask "Do you want to install .vimrc?"; then
	stow --target $HOME vim
fi

if ask "Do you want to install .zshrc?"; then
	mkdir -p $HOME/.config/zsh
	stow --target $HOME/.config/zsh zsh
	stow --target $HOME zshrc
fi

if ask "Do you want to install nvim?"; then
	mkdir -p $HOME/.config/nvim
	stow --target $HOME/.config/nvim nvim
fi

if ask "Do you want to install .gitconfig?"; then
	stow --target $HOME git
fi

if ask "Do you want to install .tmux.conf?"; then
	stow --target $HOME tmux
fi
