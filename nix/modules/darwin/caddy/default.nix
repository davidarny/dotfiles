# Caddy web server configuration
{ systemConfig, ... }:
{
  # Post-activation script to set up Caddy configuration
  system.activationScripts.postActivation.text = ''
    # Create symlink for Caddy configuration
    sudo ln -sf ${systemConfig.user.home}/.dotfiles/Caddyfile /opt/homebrew/etc/Caddyfile
  '';
}
