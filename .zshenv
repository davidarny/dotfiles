source ~/.config/zsh/env.zsh
source ~/.config/zsh/aliases.zsh

# Codex 0.156 runs each command in a plain zsh -c: no .zprofile, no .zshrc, and
# none of the functions its shell snapshot captured. Load .zshrc in the shell
# Codex starts, not in the scripts that shell runs, so Codex gets the shell the
# other agents do.
if [[ -n $CODEX_THREAD_ID && ! -o interactive && ${$(ps -o comm= -p $PPID 2>/dev/null):t} == codex ]]; then
  source ~/.zshrc >/dev/null 2>&1
fi
