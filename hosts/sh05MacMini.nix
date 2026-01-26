{
  pkgs,
  username,
  hostname,
  ...
}:
{
  # Host-specific configuration for sh05MacMini
  networking = {
    hostName = "sh05MacMini";
    computerName = "sh05MacMini";
  };

  # Enable SSH (optional, can be disabled if not needed)
  # services.openssh.enable = true;
}
