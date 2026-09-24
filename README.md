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
  - `.config/nvim/` - Neovim configuration
  - `.config/tmux/tmux.conf` - Tmux configuration
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
| `tm` | `tmux` | Open Tmux |
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

## Prerequisites

### System Requirements

- macOS
- [Homebrew](https://brew.sh)
- [GNU stow](https://www.gnu.org/software/stow/)

### Required Dependencies

These need to be installed manually:

- [Zsh](https://www.zsh.org/) - Shell
- [Antidote](https://antidote.sh/) - Zsh plugin manager
- [Ghostty](https://ghostty.org/) - Terminal emulator
- [Tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [fd](https://github.com/sharkdp/fd) - File finder
- [bat](https://github.com/sharkdp/bat) - Cat clone with syntax highlighting
- [bat-extras](https://github.com/eth-p/bat-extras) - Bat-powered man page viewer
- [eza](https://github.com/eza-community/eza) - Modern ls replacement
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd command
- [starship](https://starship.rs/) - Cross-shell prompt
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

- macOS on Apple Silicon
- Command Line Tools for Xcode: `xcode-select --install`
- [Homebrew](https://brew.sh) package manager
- [just](https://github.com/casey/just) and [gh](https://cli.github.com): `brew install just gh`
- Desktop apps, installed manually (the Brewfile holds only CLI tools):
  - [1Password](https://1password.com/downloads/mac), signed in, with Settings → Developer → Integrate with 1Password CLI enabled
  - [Zed](https://zed.dev), the target of `just file-defaults`
- SSH, set up manually: the 1Password SSH agent config (`~/.config/1Password/ssh/agent.toml`) and the public keys in `~/.ssh/*.pub`. gh uses SSH once the dotfiles are linked.

### 2. Clone and Bootstrap

The repository is private and the 1Password SSH agent is not configured yet, so clone over HTTPS through `gh`:

```bash
gh auth login
gh repo clone davidarny/dotfiles ~/.dotfiles
cd ~/.dotfiles
just bootstrap
```

`just bootstrap` installs the Brewfile, links the dotfiles with stow, installs the mise runtimes (bun, node, ...), resolves MCP secrets from 1Password, loads the LaunchAgent that publishes them to GUI apps, installs global skills and Bun packages, restores Claude Code and Codex settings and MCP servers, installs yazi plugins, and applies file associations. It is safe to rerun and stops with a hint when it needs you, for example to sign in to 1Password or to quit Claude and Codex before their configs are restored. tmux installs TPM and its plugins on first start.

### 3. Verify

```bash
just doctor
```

`just doctor` only reads and reports broken or missing links, empty MCP secrets, missing Brewfile packages, MCP servers whose command does not exist, missing skills, and missing tmux or yazi plugins. Reload your shell afterwards with `source ~/.zshrc`.

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
brew uninstall tmux fzf fd bat eza zoxide starship lazygit yazi ripgrep diff-so-fancy ...
brew uninstall --cask ghostty
```

### 3. Remove Configuration Files

Clean up remaining configuration files:

```bash
# Remove ZSH configuration
rm -rf ~/.zshrc ~/.zsh_history ~/.cache/antidote ~/.cache/zsh/antidote-plugins.zsh ~/.cache/zsh/antidote-post-completion-plugins.zsh

# Remove tool-specific configs
rm -rf ~/.config/ghostty
rm -rf ~/.config/nvim
rm -rf ~/.config/tmux
rm -rf ~/.config/yazi
rm -rf ~/.config/starship.toml
...
```
