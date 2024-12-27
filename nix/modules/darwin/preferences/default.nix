# macOS system preferences configuration
{ ... }:
{
  # macOS system defaults
  system.defaults = {
    # Global domain settings
    NSGlobalDomain = {
      AppleICUForce24HourTime = true; # Use 24-hour time
      AppleShowAllExtensions = true; # Show all file extensions
    };

    # Login window settings
    loginwindow = {
      GuestEnabled = false; # Disable guest account
    };

    # Finder settings
    finder = {
      FXPreferredViewStyle = "Nlsv"; # List view
      ShowPathbar = true; # Show path bar
      ShowStatusBar = true; # Show status bar
    };
  };
}
