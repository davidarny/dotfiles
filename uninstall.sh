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

if ask "Do you want to uninstall .vimrc?"; then
	stow --delete --target $HOME vim
fi

if ask "Do you want to uninstall .zshrc?"; then
	stow --delete --target $HOME/.config/zsh zsh
	stow --delete --target $HOME zshrc
fi

if ask "Do you want to uninstall nvim?"; then
	stow --delete --target $HOME/.config/nvim nvim
fi

if ask "Do you want to uninstall .gitconfig?"; then
	stow --delete --target $HOME git
fi

if ask "Do you want to uninstall .tmux.conf?"; then
	stow --delete --target $HOME tmux
fi
