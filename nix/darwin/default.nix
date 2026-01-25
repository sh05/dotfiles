{
  pkgs,
  username,
  ...
}:
{
  # macOS system defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;
      autohide-delay = 0.0; # 即座に表示
      autohide-time-modifier = 0.5; # 表示アニメーション高速化
      orientation = "bottom"; # Dock位置
      show-process-indicators = true; # 実行中アプリの●表示
      mineffect = "scale"; # 最小化エフェクト（高速）
      launchanim = false; # 起動バウンドアニメーション無効化
      expose-animation-duration = 0.1; # Mission Controlアニメーション高速化
      expose-group-apps = true; # Mission Controlでアプリをグループ化

      # ホットコーナー
      wvous-tl-corner = 2; # 左上: Mission Control
      wvous-tr-corner = 4; # 右上: デスクトップ表示
      wvous-bl-corner = 11; # 左下: Launchpad
      wvous-br-corner = 13; # 右下: ロック画面
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv"; # List view
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true; # タイトルバーにフルパス表示
      _FXSortFoldersFirst = true; # フォルダを先頭にソート
      FXEnableExtensionChangeWarning = false; # 拡張子変更警告を無効化
      QuitMenuItem = true; # Finder終了メニュー表示
      FXDefaultSearchScope = "SCcf"; # 検索時にカレントフォルダを対象
      CreateDesktop = true; # デスクトップアイコン表示
      ShowExternalHardDrivesOnDesktop = true; # 外付けHDD表示
      ShowHardDrivesOnDesktop = false; # 内蔵HDD非表示
      ShowMountedServersOnDesktop = true; # サーバー表示
      ShowRemovableMediaOnDesktop = true; # リムーバブルメディア表示
    };

    # Global system settings
    NSGlobalDomain = {
      # キーボード設定（既存）
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # 追加設定
      AppleShowScrollBars = "WhenScrolling";
      AppleScrollerPagingBehavior = true;
      AppleWindowTabbingMode = "manual";
      AppleInterfaceStyle = "Dark"; # ダークモード強制
      AppleInterfaceStyleSwitchesAutomatically = false;
      NSWindowResizeTime = 0.001; # リサイズアニメーション高速化
    };

    # Trackpad settings
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
      FirstClickThreshold = 0; # クリック感度: 軽い（0:軽い, 1:中, 2:強い）
      ActuationStrength = 0; # サイレントクリック有効
      TrackpadThreeFingerTapGesture = 2; # 3本指タップで調べる
    };

    # Control Center settings
    controlcenter = {
      BatteryShowPercentage = true; # バッテリー残量%表示
      Bluetooth = true; # Bluetooth表示
      Sound = true; # 音量表示
    };

    # Menu bar clock settings
    menuExtraClock = {
      Show24Hour = true; # 24時間表示
      ShowDate = 1; # 日付表示（0:なし, 1:常時, 2:ホバー時）
      ShowDayOfWeek = true; # 曜日表示
      ShowSeconds = false; # 秒非表示
    };

    # Login window settings
    loginwindow = {
      GuestEnabled = false;
    };

    # Screenshot settings
    screencapture = {
      location = "~/Screenshots";
      type = "png";
      disable-shadow = true; # ウィンドウの影を無効化
      show-thumbnail = false; # 撮影後のサムネイル非表示（即座に保存）
      include-date = true; # ファイル名に日時を含める
    };

    # Software update settings
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = false; # macOS自動アップデート無効
    };

    # Accessibility settings
    universalaccess = {
      reduceMotion = true; # アニメーション削減
      reduceTransparency = false; # 透明度は維持
      closeViewScrollWheelToggle = true; # Ctrl+スクロールでズーム
    };

    # Custom user preferences
    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true; # .DS_Storeをネットワーク上に作成しない
        DSDontWriteUSBStores = true; # .DS_StoreをUSBに作成しない
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false; # 広告パーソナライズ無効
      };
      "com.apple.ImageCapture" = {
        disableHotPlug = true; # iPhone接続時に写真アプリを起動しない
      };
    };
  };

  # Security settings
  security.pam.services.sudo_local.touchIdAuth = true;

  # Homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    taps = [ ];
    brews = [
      "mas" # Mac App Store CLI
    ];
    casks = [
      # Terminal emulators
      "ghostty"

      # System utilities
      "karabiner-elements"
      "rectangle"
      "rancher"

      # Fonts
      "font-moralerspace"
      "font-moralerspace-nf"
      "font-hackgen"
      "font-hackgen-nerd"

      # Development tools
      "visual-studio-code"
      "orbstack"

      # Browsers
      "google-chrome"
      "arc"

      # Communication
      "slack"
      "discord"
      "zoom"

      # Other
      "1password"
      "raycast"
      "notion"

      # Productivity
      "cheatsheet"
      "clipy"
      "figma"
      "miro"
      "obsidian"

      # Streaming/Recording
      "obs"
      "elgato-stream-deck"
      "keycastr"

      # Utilities
      "multipass"
      "fliqlo"

      # Additional fonts
      "font-menlo-for-powerline"
    ];
    masApps = {
      "Kindle" = 302584613;
      "LINE" = 539883307;
      "Xcode" = 497799835;
    };
  };

  # Enable fonts
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
