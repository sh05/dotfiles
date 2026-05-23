{ ... }:
{
  # Host-specific configuration for sh05MacMini
  networking = {
    hostName = "sh05MacMini";
    computerName = "sh05MacMini";
  };

  # Personal Mac App Store apps (exclude these on work hosts)
  homebrew.masApps = {
    "Kindle" = 302584613;
    "LINE" = 539883307;
  };

  # Enable SSH (optional, can be disabled if not needed)
  # services.openssh.enable = true;
}
