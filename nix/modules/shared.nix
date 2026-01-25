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
    # Determinate Systems Nix installer manages Nix itself
    enable = false;
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
