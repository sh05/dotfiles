{
  pkgs,
  username,
  ...
}:
{
  # Primary user for user-specific settings (required by nix-darwin)
  system.primaryUser = username;

  # macOS system defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
      tilesize = 16;
      autohide-delay = 0.0; # 即座に表示
      autohide-time-modifier = 0.5; # 表示アニメーション高速化
      orientation = "left"; # Dock位置
      show-process-indicators = true; # 実行中アプリの●表示
      mineffect = "scale"; # 最小化エフェクト（高速）
      launchanim = false; # 起動バウンドアニメーション無効化
      expose-animation-duration = 0.1; # Mission Controlアニメーション高速化
      expose-group-apps = true; # Mission Controlでアプリをグループ化
      magnification = true; # 拡大機能有効
      largesize = 128; # 拡大時のサイズ
      minimize-to-application = true; # アプリケーションに最小化
      # ホットコーナー設定
      wvous-br-corner = 14; # 右下: クイックメモ
      wvous-br-modifier = 0; # 修飾キーなし
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv"; # List view
      ShowPathbar = true;
      ShowStatusBar = false;
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
      # キーボード設定
      AppleKeyboardUIMode = 2;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # 追加設定
      AppleShowScrollBars = "Always";
      AppleScrollerPagingBehavior = true;
      AppleWindowTabbingMode = "manual";
      AppleInterfaceStyle = "Dark"; # ダークモード
      AppleInterfaceStyleSwitchesAutomatically = true; # 自動切替有効
      NSWindowResizeTime = 0.001; # リサイズアニメーション高速化
      # 追加設定
      "com.apple.keyboard.fnState" = false; # fnキー: 特殊キー優先
      AppleSpacesSwitchOnActivate = true; # アプリ切替時にスペース移動
    };

    # Trackpad settings
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      FirstClickThreshold = 1; # クリック感度: 中（0:軽い, 1:中, 2:強い）
      ActuationStrength = 1; # 通常のクリック音
      TrackpadThreeFingerTapGesture = 0; # 3本指タップ無効
    };

    # Control Center settings
    controlcenter = {
      BatteryShowPercentage = true; # バッテリー残量%表示
      Bluetooth = true; # Bluetooth表示
      Sound = true; # 音量表示
    };

    # Menu bar clock settings
    menuExtraClock = {
      ShowDayOfWeek = true; # 曜日表示
      ShowSeconds = false; # 秒非表示
    };

    # Login window settings
    loginwindow = {
      GuestEnabled = false;
    };

    # Software update settings
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = true;
    };

    # Accessibility settings
    universalaccess = {
      reduceMotion = true; # アニメーション削減
      reduceTransparency = false; # 透明度は維持
      closeViewScrollWheelToggle = true; # Ctrl+スクロールでズーム
      mouseDriverCursorSize = 2.5; # カーソルサイズ（大きめ）
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
      NSGlobalDomain = {
        AppleMenuBarVisibleInFullscreen = true; # フルスクリーンでメニューバー表示
        AppleMiniaturizeOnDoubleClick = false; # ダブルクリックで最小化無効
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
