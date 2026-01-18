# dot.files

🌌 Elegant dotfiles for the modern developer | Powered by [GNU stow](https://www.gnu.org/software/stow/)

🎨 A meticulously crafted development environment featuring:

- 🚀 Blazing-fast ZSH setup with custom plugins
- 🎯 Neovim config with LSP & treesitter
- 🖥️ Beautiful terminal setup (Ghostty, Tmux)
- 🎮 Git-centric workflow with LazyGit
- 🌟 Tokyo Night theme across all tools

✨ Zero-friction setup for macOS development environment

## What's Included

- **Shell Configuration**
  - `.zshrc` - ZSH shell configuration
  - Custom ZSH configurations in `.config/zsh/`
- **Development Tools**
  - `.gitconfig` - Git configuration
  - `.vimrc` - Vim configuration
  - `nvim/` - Neovim configuration
  - `.tmux.conf` - Tmux configuration
- **Terminal Utilities**
  - `.config/ghostty/` - Ghostty terminal configuration
  - `.config/starship.toml` - Starship prompt configuration
  - `.config/bat/` - Bat (cat alternative) configuration
  - `.config/eza/` - Eza (ls alternative) configuration
  - `.config/lazygit/` - LazyGit configuration
  - `.config/yazi/` - Yazi file manager configuration
  - `.config/fastfetch/` - System information tool configuration

## Shell Customization

### Aliases

**File Listing**
| Alias | Command | Description |
|-------|---------|-------------|
| `l` | `eza -1A --group-directories-first --color=always` | List files |
| `la` | `eza -la --git --git-repos --group-directories-first --color=always --octal-permissions --time-style=long-iso` | Detailed list with git info |
| `tree` | `eza --tree --group-directories-first --color=always` | Tree view |
| `ls` | `l` | Alias for list |
| `t` | `l` | Short alias for list |

**Tools**
| Alias | Command | Description |
|-------|---------|-------------|
| `tm` | `tmux` | Open Tmux |
| `lg` | `lazygit` | Open LazyGit |
| `yz` | `yazi` | Open Yazi file manager |
| `ff` | `fastfetch` | System info |
| `rg` | `rg --hidden --smart-case ...` | Ripgrep with defaults |

**System**
| Alias | Command | Description |
|-------|---------|-------------|
| `reload` | `source ~/.zshrc` | Reload ZSH configuration |
| `c` | `clear` | Clear terminal screen |
| `man` | `batman` | Open man pages with bat |
| `rf` | `trash` | Move to Trash |
| `allowapp` | `sudo xattr -r -d com.apple.quarantine` | Remove quarantine |
| `dsclean` | `fd -H '^\\.DS_Store$' -tf -X rm` | Remove .DS_Store files |
| `lnclean` | `fd . --type l ...` | Remove broken symlinks |

**Editors**
| Alias | Command | Description |
|-------|---------|-------------|
| `e` | `$EDITOR` | Open editor |
| `E` | `sudo -e` | Open editor as root |

**Services**
| Alias | Command | Description |
|-------|---------|-------------|
| `caddystart` | `caddy start --config ~/.config/caddy/caddy.json` | Start Caddy |
| `caddystop` | `caddy stop` | Stop Caddy |

### Functions

| Function | Description                                           | Usage                              |
| -------- | ----------------------------------------------------- | ---------------------------------- |
| `migrate_npm_globals` | Migrate npm global packages to a new Node.js version | `migrate_npm_globals 20` |
| `zsh_refresh_init_cache` | Refresh cached init scripts for shell tools | `zsh_refresh_init_cache` |

## Prerequisites

### System Requirements

- macOS
- [Homebrew](https://brew.sh)
- [GNU stow](https://www.gnu.org/software/stow/)

### Required Dependencies

These need to be installed manually:

- [Zsh](https://www.zsh.org/) - Shell
- [Zinit](https://github.com/zdharma-continuum/zinit) - Zsh plugin manager
- [Ghostty](https://ghostty.org/) - Terminal emulator
- [Tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [fd](https://github.com/sharkdp/fd) - File finder
- [bat](https://github.com/sharkdp/bat) - Cat clone with syntax highlighting
- [eza](https://github.com/eza-community/eza) - Modern ls replacement
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd command
- [starship](https://starship.rs/) - Cross-shell prompt
- [fnm](https://github.com/Schniz/fnm) - Fast Node.js version manager
- [git](https://git-scm.com/) - Version control
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - Git diff enhancer
- [lazygit](https://github.com/jesseduffield/lazygit) - Git TUI
- [yazi](https://github.com/sxyazi/yazi) - Terminal file manager
- [1Password CLI](https://1password.com/downloads/command-line/) - Password manager CLI
- [Neovim](https://neovim.io/) - Text editor
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast text search

## Installing

### 1. Prerequisites

Before installation, ensure you have:

- macOS installed
- Command Line Tools for Xcode: `xcode-select --install`
- [Homebrew](https://brew.sh) package manager
- [GNU stow](https://www.gnu.org/software/stow/): `brew install stow`

### 2. Clone and Link Dotfiles

1. Clone this repository:

```bash
git clone git@gitlab.com:waosdx/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Create symlinks using GNU stow:

```bash
./link.sh
```

This will:

- Back up any existing dotfiles
- Create symbolic links in your home directory
- Set up all configurations (zsh, tmux, neovim, etc.)

### 3. Post-Installation

1. Reload your shell:

```bash
source ~/.zshrc
```

2. Install Zinit for ZSH plugin management:

```bash
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
```

3. Install required dependencies:

```bash
brew install tmux fzf fd bat eza zoxide starship fnm lazygit yazi ripgrep diff-so-fancy
brew install --cask ghostty
```

## Uninstalling

### 1. Remove Symlinks

Remove all symlinks created by GNU stow:

```bash
./unlink.sh
```

### 2. Clean Up Package Managers

2. Remove Homebrew packages (optional):

```bash
# List all installed packages first
brew leaves

# Remove specific packages
brew uninstall tmux fzf fd bat eza zoxide starship fnm lazygit yazi ripgrep diff-so-fancy ...
brew uninstall --cask ghostty
```

### 3. Remove Configuration Files

Clean up remaining configuration files:

```bash
# Remove ZSH configuration
rm -rf ~/.zshrc ~/.zsh_history ~/.zinit

# Remove tool-specific configs
rm -rf ~/.config/ghostty
rm -rf ~/.config/nvim
rm -rf ~/.config/tmux
rm -rf ~/.config/yazi
rm -rf ~/.config/starship.toml
...
```
