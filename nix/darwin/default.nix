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
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv"; # List view
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Keyboard settings
    NSGlobalDomain = {
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    # Trackpad settings
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    # Login window settings
    loginwindow = {
      GuestEnabled = false;
    };

    # Screenshot settings
    screencapture = {
      location = "~/Screenshots";
      type = "png";
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
    taps = [
      "homebrew/bundle"
    ];
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
