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
      showMissionControlGestureEnabled = true; # Mission Controlジェスチャ有効
      # ホットコーナー設定
      wvous-br-corner = 14; # 右下: クイックメモ
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
      FXRemoveOldTrashItems = true; # 30日経過したゴミ箱項目を自動削除
      NewWindowTarget = "Home"; # 新規ウィンドウをホームで開く
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
      NSAutomaticCapitalizationEnabled = true; # 自動大文字化
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = true; # 自動ピリオド挿入
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # 表示・ウィンドウ
      AppleShowAllExtensions = true; # 拡張子を常に表示
      AppleShowScrollBars = "Always";
      AppleScrollerPagingBehavior = true;
      AppleWindowTabbingMode = "manual";
      AppleInterfaceStyleSwitchesAutomatically = true; # 外観モード自動切替
      NSWindowResizeTime = 0.001; # リサイズアニメーション高速化

      # 入力デバイス
      "com.apple.keyboard.fnState" = false; # fnキー: 特殊キー優先
      "com.apple.trackpad.scaling" = 3.0; # トラックパッド速度
      "com.apple.trackpad.forceClick" = true; # 強めのクリック有効

      # スペース・操作
      AppleSpacesSwitchOnActivate = true; # アプリ切替時にスペース移動
      "com.apple.springing.enabled" = true; # スプリングフォルダ有効
      "com.apple.springing.delay" = 0.5; # スプリングフォルダの遅延
      "com.apple.sound.beep.feedback" = 1; # 音量変更時のフィードバック音
    };

    # Trackpad settings
    trackpad = {
      Clicking = true; # タップでクリック
      Dragging = false; # タップでドラッグ無効
      DragLock = false; # ドラッグロック無効
      TrackpadRightClick = true; # 2本指タップで右クリック
      TrackpadThreeFingerDrag = false; # 3本指ドラッグ無効
      TrackpadThreeFingerTapGesture = 0; # 3本指タップ無効
      FirstClickThreshold = 1; # クリック感度: 中（0:軽い, 1:中, 2:強い）
      SecondClickThreshold = 1; # 強めのクリック感度: 中
      ActuationStrength = 1; # 通常のクリック音
      ActuateDetents = true; # ハプティックフィードバック有効
      ForceSuppressed = false; # 強めのクリック検出を維持
      TrackpadCornerSecondaryClick = 0; # コーナークリックでの副クリック無効
      TrackpadMomentumScroll = true; # 慣性スクロール
      TrackpadPinch = true; # ピンチズーム
      TrackpadRotate = true; # 回転ジェスチャ
      TrackpadTwoFingerDoubleTapGesture = true; # 2本指ダブルタップ
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3; # 右端からのスワイプ
      TrackpadThreeFingerHorizSwipeGesture = 0; # 3本指水平スワイプ無効
      TrackpadThreeFingerVertSwipeGesture = 2; # 3本指垂直スワイプ
      TrackpadFourFingerHorizSwipeGesture = 2; # 4本指水平スワイプ
      TrackpadFourFingerVertSwipeGesture = 2; # 4本指垂直スワイプ
      TrackpadFourFingerPinchGesture = 2; # 4本指ピンチ
    };

    # Magic Mouse settings
    magicmouse = {
      MouseButtonMode = "OneButton"; # 全タップを左クリック扱い
    };

    # Control Center settings
    controlcenter = {
      BatteryShowPercentage = true; # バッテリー残量%表示
      Bluetooth = true; # Bluetooth表示
      Sound = true; # 音量表示
      Display = true; # ディスプレイ表示
      NowPlaying = true; # 再生中コントロール表示
      FocusModes = false; # 集中モードは非表示
    };

    # Menu bar clock settings
    menuExtraClock = {
      ShowDayOfWeek = true; # 曜日表示
      ShowAMPM = true; # AM/PM表示
      ShowDate = 2; # 日付非表示 (0:スペース次第, 1:常に, 2:表示しない)
      ShowSeconds = false; # 秒非表示
    };

    # Window Manager (Stage Manager) settings
    WindowManager = {
      GloballyEnabled = false; # Stage Manager無効
      AutoHide = false; # Stage Managerの自動非表示
      AppWindowGroupingBehavior = true; # アプリのウィンドウをグループ化
      HideDesktop = true; # デスクトップアイテムを非表示
      EnableTiledWindowMargins = false; # タイル化ウィンドウの余白なし
      StandardHideWidgets = false; # デスクトップウィジェットを表示
      StageManagerHideWidgets = false; # Stage Manager時のウィジェット表示
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
        ContextMenuGesture = 1; # 副クリックジェスチャ有効
        "com.apple.sound.beep.flash" = 0; # 警告音時に画面を点滅させない
        "com.apple.mouse.scaling" = 3.0; # マウス速度（nix-darwin に型付きオプションが無いため）
      };

      # Rectangle (ウィンドウ管理アプリ) の設定。
      # 旧 RectangleConfig.json を翻訳したもの。Rectangle は JSON ではなく
      # この defaults ドメインを読むため、宣言的に書き込む。
      # plist では defaults / shortcuts が同じ階層のフラットなキーになる。
      "com.knollsoft.Rectangle" = {
        # --- defaults ---
        allowAnyShortcut = true;
        almostMaximizeHeight = 0.0;
        almostMaximizeWidth = 0.0;
        alternateDefaultShortcuts = true;
        altThirdCycle = 0;
        alwaysAccountForStage = 0;
        applyGapsToMaximize = 0;
        applyGapsToMaximizeHeight = 0;
        attemptMatchOnNextPrevDisplay = 0;
        autoMaximize = 0;
        cascadeAllDeltaSize = 30.0;
        centeredDirectionalMove = 0;
        centerHalfCycles = 0;
        cornerSnapAreaSize = 20.0;
        curtainChangeSize = 0;
        doubleClickTitleBar = 0;
        doubleClickTitleBarRestore = 0;
        dragFromStage = 0;
        enhancedUI = 1;
        footprintAlpha = 0.3;
        footprintAnimationDurationMultiplier = 0.75;
        footprintBorderWidth = 2.0;
        footprintFade = 0;
        gapSize = 5.0;
        hideMenubarIcon = false;
        ignoreDragSnapToo = 0;
        ignoredSnapAreas = 0;
        landscapeSnapAreas = "[3,{\"action\":16},5,{\"compound\":-3},6,{\"action\":13},7,{\"compound\":-4},1,{\"action\":15},4,{\"compound\":-2},2,{\"action\":2},8,{\"action\":14}]";
        launchOnLogin = true;
        minimumWindowHeight = 0.0;
        minimumWindowWidth = 0.0;
        missionControlDragging = 0;
        missionControlDraggingAllowedOffscreenDistance = 25.0;
        missionControlDraggingDisallowedDuration = 250;
        moveCursor = 0;
        moveCursorAcrossDisplays = 0;
        notifiedOfProblemApps = false;
        obtainWindowOnClick = 0;
        portraitSnapAreas = "[7,{\"compound\":-6},8,{\"action\":14},4,{\"compound\":-5},1,{\"action\":15},6,{\"action\":13},5,{\"compound\":-5},2,{\"action\":2},3,{\"action\":16}]";
        relaunchOpensMenu = false;
        resizeOnDirectionalMove = false;
        screenEdgeGapBottom = 0.0;
        screenEdgeGapLeft = 0.0;
        screenEdgeGapRight = 0.0;
        screenEdgeGapsOnMainScreenOnly = false;
        screenEdgeGapTop = 0.0;
        shortEdgeSnapAreaSize = 145.0;
        showAllActionsInMenu = 0;
        sixthsSnapArea = 0;
        sizeOffset = 0.0;
        snapEdgeMarginBottom = 5.0;
        snapEdgeMarginLeft = 5.0;
        snapEdgeMarginRight = 5.0;
        snapEdgeMarginTop = 5.0;
        snapModifiers = 0;
        specifiedHeight = 1050.0;
        specifiedWidth = 1680.0;
        stageSize = 190.0;
        subsequentExecutionMode = 4;
        SUEnableAutomaticChecks = false;
        systemWideMouseDown = 0;
        todo = 0;
        todoMode = false;
        todoSidebarSide = 1;
        todoSidebarWidth = 400.0;
        traverseSingleScreen = 0;
        unsnapRestore = 0;
        windowSnapping = 0;
        # --- shortcuts (plist 上はトップレベルのフラットなキー) ---
        bottomHalf = {
          keyCode = 38;
          modifierFlags = 524288;
        };
        bottomLeft = {
          keyCode = 38;
          modifierFlags = 1572864;
        };
        bottomRight = {
          keyCode = 37;
          modifierFlags = 1572864;
        };
        leftHalf = {
          keyCode = 4;
          modifierFlags = 524288;
        };
        maximize = {
          keyCode = 36;
          modifierFlags = 1572864;
        };
        reflowTodo = {
          keyCode = 45;
          modifierFlags = 786432;
        };
        rightHalf = {
          keyCode = 37;
          modifierFlags = 524288;
        };
        toggleTodo = {
          keyCode = 11;
          modifierFlags = 786432;
        };
        topHalf = {
          keyCode = 40;
          modifierFlags = 524288;
        };
        topLeft = {
          keyCode = 4;
          modifierFlags = 1572864;
        };
        topRight = {
          keyCode = 40;
          modifierFlags = 1572864;
        };
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
      extraFlags = [ "--force" ];
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
      "font-hackgen"
      "font-hackgen-nerd"

      # Development tools
      "visual-studio-code"
      "orbstack"

      # Browsers
      "google-chrome"

      # Communication
      "slack"
      "discord"

      # Other
      "1password"
      "raycast"
      "notion"

      # Productivity
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
  };

  # Enable fonts
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
