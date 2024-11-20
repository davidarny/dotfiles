{ self, ... }:
{
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  #$ darwin-rebuild changelog
  system.stateVersion = 5;

  system.defaults = {
    NSGlobalDomain.AppleICUForce24HourTime = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
    loginwindow.GuestEnabled = false;
    finder.FXPreferredViewStyle = "Nlsv";
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.activationScripts.postActivation.text = ''
    # Create symlink for Caddyfile
    sudo ln -sf /Users/david_arutiunian/.dotfiles/Caddyfile /opt/homebrew/etc/Caddyfile
  '';
}
