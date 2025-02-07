# --- Terminal Utilities ---

# Clear terminal screen
# Example: c
alias c="clear"

# List files with git info, icons, and directory grouping
# Flags:
#   --color=always: Force colored output
#   --long: Show detailed file information
#   --git: Show git status
#   --icons=always: Show file type icons
#   --no-time: Hide timestamps
#   --group-directories-first: Show directories before files
# Example: t
alias t="eza --color=always --long --git --icons=always --no-time --group-directories-first"

# Open man pages with bat for syntax highlighting
# Example: man git
alias man="batman"

# Interactive uninstall of global npm packages
# Usage: npmung
# Example:
#   npmung
#   -> opens fzf interface
#   -> select packages with Tab
#   -> press Enter to uninstall selected packages
alias npmung="npm list -g --no-unicode | awk '/(\+|\`)--/ {print $2}' | cut -c5- | fzf --multi | cut -d'@' -f1 | xargs npm un -g"

# Display system information
# Example: ff
alias ff="fastfetch"

# --- Navigation ---

# Quick access to Developer directory
# Example: dev
alias dev="cd ~/Developer"

# Go up one directory (shorthand for cd ..)
# Example: ..
alias ..="cd .."

# --- Terminal Multiplexers ---

# Launch Tmux terminal multiplexer
# Example: tm
alias tm="tmux"

# Launch Yazi file manager
# Example: yz
alias yz="yazi"

# Open Tmux session picker with fuzzy search
# Example: 
#   tms
#   -> opens fzf interface with available directories
#   -> select directory to create/attach session
alias tms="tmux-sessionizer"

# --- System Configuration ---

# Reload ZSH configuration
# Example: zs
alias zs="source ~/.zshrc"

# Reset macOS launchpad
# Example: lprst
alias lprst="sudo find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock"

# --- Development Tools ---

# Open LazyGit TUI
# Example: lg
alias lg="lazygit"

# --- Nix System Management ---

# Rebuild nix-darwin configuration
# Example: dms
# Note: This will apply changes from ~/.dotfiles/nix configuration
alias dms="darwin-rebuild switch -v --flake ~/.dotfiles/nix"

# Clean up old Nix generations to free disk space
# Example: ngc
# Note: This will remove old generations that are older than 30 days
alias ngc="nix-collect-garbage -d"

# Allow apps to run without quarantine
# Example: allowapp <app>
alias allowapp="sudo xattr -r -d com.apple.quarantine"
