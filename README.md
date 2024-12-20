# dot.files

🌌 Elegant dotfiles for the modern developer | Powered by [nix-darwin](https://nix-community.github.io/nix-darwin/) & [GNU stow](https://www.gnu.org/software/stow/)

🎨 A meticulously crafted development environment featuring:
• 🚀 Blazing-fast ZSH setup with custom plugins
• 🎯 Neovim config with LSP & treesitter
• 🖥️ Beautiful terminal setup (Kitty, Tmux, Zellij)
• 🎮 Git-centric workflow with LazyGit
• 🌟 Tokyo Night theme across all tools
• 🔧 Nix-managed packages & dependencies

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
  - `kitty/` - Kitty terminal configuration
  - `starship.toml` - Starship prompt configuration
  - `bat/` - Bat (cat alternative) configuration
  - `eza/` - Eza (ls alternative) configuration
  - `lazygit/` - LazyGit configuration
  - `zellij/` - Zellij terminal multiplexer configuration
  - `yazi/` - Yazi file manager configuration
  - `fastfetch/` - System information tool configuration
- **Nix Configuration**
  - `nix/darwin.nix` - nix-darwin system configuration
  - `nix/home.nix` - Home Manager configuration
  - `nix/flake.nix` - Nix flake configuration

## Shell Customization

### Aliases

**Terminal Utilities**
| Alias | Command | Description |
|-------|---------|-------------|
| `c` | `clear` | Clear terminal screen |
| `t` | `eza --color=always --long --git --icons=always --no-time --group-directories-first` | List files with git info and icons |
| `man` | `batman` | Open man pages with bat |

**Navigation**
| Alias | Command | Description |
|-------|---------|-------------|
| `dev` | `cd ~/Developer` | Navigate to Developer directory |
| `..` | `cd ..` | Navigate to parent directory |

**Terminal Multiplexers**
| Alias | Command | Description |
|-------|---------|-------------|
| `zj` | `zellij` | Open Zellij |
| `zjs` | `zellij-sessionizer` | Open Zellij session picker |
| `tm` | `tmux` | Open Tmux |
| `tms` | `tmux-sessionizer` | Open Tmux session picker |

**Development Tools**
| Alias | Command | Description |
|-------|---------|-------------|
| `lg` | `lazygit` | Open LazyGit |
| `yz` | `yazi` | Open Yazi file manager |

**System Configuration**
| Alias | Command | Description |
|-------|---------|-------------|
| `zs` | `source ~/.zshrc` | Reload ZSH configuration |
| `dms` | `darwin-rebuild switch -v --flake ~/.dotfiles/nix` | Rebuild nix-darwin configuration |
| `ngc` | `nix-collect-garbage -d` | Clean up old Nix generations |

### Functions

| Function | Description                                        | Usage         |
| -------- | -------------------------------------------------- | ------------- |
| `nmg`    | Migrate npm global packages to new Node.js version | `nmg version` |

## Prerequisites

### System Requirements

- macOS
- [Nix package manager](https://nixos.org/download.html)
- [Homebrew](https://brew.sh)
- [GNU stow](https://www.gnu.org/software/stow/)

### Required Dependencies

These need to be installed manually:

- [Zsh](https://www.zsh.org/) - Shell
- [Zinit](https://github.com/zdharma-continuum/zinit) - Zsh plugin manager
- [Kitty](https://sw.kovidgoyal.net/kitty/) - Terminal emulator
- [Tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [fd](https://github.com/sharkdp/fd) - File finder
- [bat](https://github.com/sharkdp/bat) - Cat clone with syntax highlighting
- [eza](https://github.com/eza-community/eza) - Modern ls replacement
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd command
- [starship](https://starship.rs/) - Cross-shell prompt
- [fnm](https://github.com/Schniz/fnm) - Fast Node.js version manager
- [gh](https://cli.github.com/) - GitHub CLI
- [git](https://git-scm.com/) - Version control
- [lazygit](https://github.com/jesseduffield/lazygit) - Git TUI
- [zellij](https://zellij.dev/) - Terminal workspace
- [yazi](https://github.com/sxyazi/yazi) - Terminal file manager
- [1Password CLI](https://1password.com/downloads/command-line/) - Password manager CLI

### Home Manager Packages

These are automatically installed via `home.nix`:

- [Neovim](https://neovim.io/) - Text editor
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast text search
- [nixfmt-rfc-style](https://github.com/TawanScott/nixfmt-rfc-style) - Nix code formatter

## Installing

### 1. Prerequisites

Before installation, ensure you have:

- macOS installed
- Command Line Tools for Xcode: `xcode-select --install`
- [Homebrew](https://brew.sh) package manager
- [GNU stow](https://www.gnu.org/software/stow/): `brew install stow`

### 2. Install Nix via Lix

[Lix](https://lix.systems) provides a user-friendly way to install and manage Nix:

```bash
# Install Lix
curl -sSf -L https://install.lix.systems/lix | sh -s -- install

# Configure nix-darwin
nix run nix-darwin -- switch --flake ~/.config/nix-darwin
```

### 3. Clone and Link Dotfiles

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/dot.files.git ~/.dotfiles
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

### 4. Post-Installation

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
   brew install kitty tmux fzf fd bat eza zoxide starship fnm gh lazygit zellij yazi
   ```

## Uninstalling

### 1. Remove Symlinks

Remove all symlinks created by GNU stow:

```bash
./unlink.sh
```

### 2. Clean Up Package Managers

1. Remove Nix-related configurations:

   ```bash
   # Remove nix-darwin
   sudo rm -rf ~/.nix-defexpr
   sudo rm -rf /etc/nix

   # Remove Nix package manager
   sudo rm -rf /nix
   ```

2. Remove Homebrew packages (optional):

   ```bash
   # List all installed packages first
   brew leaves

   # Remove specific packages
   brew uninstall kitty tmux fzf fd bat eza zoxide starship fnm gh lazygit zellij yazi
   ```

### 3. Remove Configuration Files

Clean up remaining configuration files:

```bash
# Remove ZSH configuration
rm -rf ~/.zshrc ~/.zsh_history ~/.zinit

# Remove tool-specific configs
rm -rf ~/.config/kitty
rm -rf ~/.config/nvim
rm -rf ~/.config/tmux
rm -rf ~/.config/zellij
rm -rf ~/.config/yazi
rm -rf ~/.config/starship.toml
```
