# FZF configuration
if [[ -z "${FZF_BASE_DEFAULT_OPTS+x}" ]]; then
  export FZF_BASE_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-}"
fi

export FZF_DEFAULT_OPTS=$FZF_BASE_DEFAULT_OPTS'
  --color=fg:-1,fg+:#d0d0d0,bg:-1,bg+:#262626
  --color=hl:#bb9af7,hl+:#5fd7ff,info:#7aa2f7,marker:#9ece6a
  --color=prompt:#7dcfff,spinner:#9ece6a,pointer:#7dcfff,header:#9ece6a
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"
  --info="right"'

# FZF commands for file and directory search
if command -v fd >/dev/null 2>&1; then
  export FZF_CTRL_T_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
else
  export FZF_CTRL_T_COMMAND="find . -path '*/.git' -prune -o -print"
  export FZF_ALT_C_COMMAND="find . -path '*/.git' -prune -o -type d -print"
fi

# FZF preview settings
if command -v eza >/dev/null 2>&1; then
  fzf_dir_preview="eza --tree --color=always --icons=always {} | head -200"
else
  fzf_dir_preview="ls -la {}"
fi

if command -v bat >/dev/null 2>&1; then
  fzf_file_preview="bat -n --color=always --line-range :500 {}"
else
  fzf_file_preview="sed -n '1,500p' {}"
fi

if command -v dig >/dev/null 2>&1; then
  fzf_ssh_preview="dig {}"
else
  fzf_ssh_preview="printf '%s\n' {}"
fi

show_file_or_dir_preview="if [ -d {} ]; then $fzf_dir_preview; else $fzf_file_preview; fi"
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview '$fzf_dir_preview'"

# FZF custom path and directory generation
_fzf_compgen_path() {
  if command -v fd >/dev/null 2>&1; then
    fd --hidden --exclude .git . "$1"
  else
    find "$1" -path '*/.git' -prune -o -print
  fi
}
_fzf_compgen_dir() {
  if command -v fd >/dev/null 2>&1; then
    fd --type=d --hidden --exclude .git . "$1"
  else
    find "$1" -path '*/.git' -prune -o -type d -print
  fi
}

# Advanced FZF customization
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview "$fzf_dir_preview" "$@" ;;
    export|unset) fzf --preview 'printenv {}'               "$@" ;;
    ssh)          fzf --preview "$fzf_ssh_preview"          "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}
