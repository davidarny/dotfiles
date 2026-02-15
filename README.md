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
| `l` | `eza -1A --group-directories-first --icons=always --tree --level=1` | List files |
| `la` | `eza -la --git --git-repos --group-directories-first --octal-permissions --time-style=long-iso --icons=always --tree --level=1` | Detailed list with git info |
| `tree` | `eza -A --tree --group-directories-first --icons=always` | Tree view |
| `t` | `l` | Short alias for list |

**Tools**
| Alias | Command | Description |
|-------|---------|-------------|
| `lg` | `lazygit` | Open LazyGit |
| `lzd` | `lazydocker` | Open LazyDocker |
| `yz` | `yazi` | Open Yazi file manager |
| `ff` | `fastfetch` | System info |
| `rg` | `rg --hidden --smart-case ...` | Ripgrep with defaults |
| `copypath` | `pwd \| pbcopy` | Copy working directory to clipboard |
| `ssh` | `TERM=xterm-256color command ssh` | SSH with compatible terminfo |

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
| `cds` | `caddy start --config ~/.config/caddy/caddy.json` | Start Caddy |
| `cdx` | `caddy stop` | Stop Caddy |

**AI**
| Alias | Command | Description |
|-------|---------|-------------|
| `ccc` | `claude --dangerously-skip-permissions` | Claude Code |
| `xxx` | `codex --yolo` | Codex |
| `ooo` | `opencode` | OpenCode |

### Functions

| Function | Description | Usage |
|----------|-------------|-------|
| `brew` | Wrapper that auto-syncs Brewfile after install/uninstall | `brew install <pkg>` |
| `tm` | Smart tmux launcher — attaches to existing session, restores from resurrect save, or starts new | `tm` |

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
- [just](https://github.com/casey/just): `brew install just`

### 2. Clone and Link Dotfiles

1. Clone this repository:

```bash
git clone git@gitlab.com:waosdx/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Create symlinks using GNU stow:

```bash
just link
```

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
just brew-install
```

## Uninstalling

### 1. Remove Symlinks

Remove all symlinks created by GNU stow:

```bash
just unlink
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
