{ ... }:
{
  # Host-specific configuration for sh05MacminiM2
  networking = {
    hostName = "sh05MacminiM2";
    computerName = "sh05MacminiM2";
  };

  # Personal Mac App Store apps (exclude these on work hosts)
  homebrew.masApps = {
    "Kindle" = 302584613;
    "LINE" = 539883307;
  };

  # Enable SSH (optional, can be disabled if not needed)
  # services.openssh.enable = true;
}
