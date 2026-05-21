{
  pkgs,
  username,
  hostname,
  ...
}:
{
  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Nix settings
  nix = {
    # nix-darwin manages the Nix daemon and /etc/nix/nix.conf
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = 5;
}
