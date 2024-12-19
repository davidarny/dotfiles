# ⎇ dotfilezzz ⌥

<img width="1236" alt="terminal" src="https://github.com/davidarny/dotfiles/assets/17799810/6e98a6ae-82d8-4fba-ab46-fd1b03df2241">

## Installing

First install [Lix](https://lix.systems/install):

```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

Then install nix-darwin:

```bash
nix run nix-darwin -- switch --flake ~/.config/nix-darwin
```

Then run the `link.sh` script as follows:

```bash
./link.sh
```

This will create symlinks to the dotfiles in your home directory using [GNU stow](https://www.gnu.org/software/stow/) and install packages using [Nix](https://nixos.org/).

## Uninstalling

Run the `unlink.sh` script as follows:

```bash
./unlink.sh
```

This will remove the symlinks created by the `link.sh` script.
