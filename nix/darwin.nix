{ self, localConfig, ... }:
{
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnfree = true;
      allowBroken = false;
    };
  };

  nix = {
    optimise = {
      automatic = true;
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "@admin"
        localConfig.user.name
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  system = {
    stateVersion = 5;
    configurationRevision = self.rev or self.dirtyRev or null;
    defaults = {
      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleShowAllExtensions = true;
      };
      loginwindow = {
        GuestEnabled = false;
      };
      finder = {
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
      };
    };
  };

  services.nix-daemon.enable = true;

  users.users.${localConfig.user.name} = {
    name = localConfig.user.name;
    home = localConfig.user.home;
  };

  system.activationScripts.postActivation.text = ''
    sudo ln -sf ${localConfig.user.home}/.dotfiles/Caddyfile /opt/homebrew/etc/Caddyfile
  '';
}
