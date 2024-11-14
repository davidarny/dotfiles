# ⎇ dotfilezzz ⌥

<img width="1236" alt="terminal" src="https://github.com/davidarny/dotfiles/assets/17799810/6e98a6ae-82d8-4fba-ab46-fd1b03df2241">

## Installing

First install [Nix](https://nixos.org/):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```


Then run the `install.sh` script as follows:

```bash
./install.sh
```

This will create symlinks to the dotfiles in your home directory using [GNU stow](https://www.gnu.org/software/stow/) and install packages using [Nix](https://nixos.org/).

## Uninstalling

Run the `uninstall.sh` script as follows:

```bash
./uninstall.sh
```

This will remove the symlinks created by the `install.sh` script.
