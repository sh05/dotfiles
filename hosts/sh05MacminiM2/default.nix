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
    "Xcode" = 497799835;
  };

  # Personal-only casks (exclude these on work hosts)
  homebrew.casks = [
    "google-chrome"
    "slack"
    "multipass"
  ];

  # 電源設定（常時稼働のMac mini向け。MacBookには適用しない）
  power = {
    sleep = {
      computer = "never"; # 自動スリープしない
      display = 10; # ディスプレイは10分でオフ
      harddisk = 10; # ディスクは10分でスリープ
    };
    restartAfterPowerFailure = true; # 停電後に自動再起動
  };

  # Enable SSH (optional, can be disabled if not needed)
  # services.openssh.enable = true;
}
