# Source configuration modules in order
for config_file in ~/.config/zsh/*.zsh; do
  [[ "$config_file" != *"/zshrc" ]] && [[ -f "$config_file" ]] && source "$config_file"
done
