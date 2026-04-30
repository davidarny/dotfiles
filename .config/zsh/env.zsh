# Default tools
if command -v bat >/dev/null 2>&1; then
  export PAGER=bat
else
  export PAGER=less
fi

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

export VISUAL=$EDITOR

# XDG
export XDG_CONFIG_HOME="$HOME/.config"

# 1Password CLI
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Disable Corepack auto-pin
export COREPACK_ENABLE_AUTO_PIN=0

# ImageMagick for image.nvim
for homebrew_lib_dir in /opt/homebrew/lib /usr/local/lib; do
  if [[ -d "$homebrew_lib_dir" ]]; then
    case ":${DYLD_LIBRARY_PATH:-}:" in
      *":$homebrew_lib_dir:"*) ;;
      *) export DYLD_LIBRARY_PATH="$homebrew_lib_dir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" ;;
    esac
    break
  fi
done
unset homebrew_lib_dir
