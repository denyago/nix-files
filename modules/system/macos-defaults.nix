{ ... }:
{
  flake.modules.darwin.macos-defaults = {

    ############################################################
    ## NSGlobalDomain
    ############################################################

    system.defaults.NSGlobalDomain = {
      NSTableViewDefaultSizeMode = 2;
      AppleShowScrollBars = "Always";
      NSUseAnimatedFocusRing = false;
      NSWindowResizeTime = 0.001;

      # Save/print panels expanded
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      NSDocumentSaveNewDocumentsToCloud = false;

      # Typing
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # Keyboard navigation
      AppleKeyboardUIMode = 3;

      # Key repeat
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 1;
      InitialKeyRepeat = 10;

      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;

      NSTextShowsControlCharacters = true;
      AppleFontSmoothing = 1;

      AppleShowAllExtensions = true;
    };

    ############################################################
    ## Global preferences extending NSGlobalDomain
    ############################################################

    system.defaults.CustomUserPreferences.NSGlobalDomain = {
      AppleEnableMenuBarTransparency = false;

      AppleLanguages = [
        "en"
        "ua"
        "ru"
      ];
      AppleLocale = "en_GB@currency=EUR";

      HIDScrollZoomModifierMask = 262144;
      closeViewScrollWheelToggle = true;
      closeViewZoomFollowsFocus = true;

      WebKitDeveloperExtras = true;
    };

    ############################################################
    ## Loginwindow
    ############################################################

    system.defaults.CustomUserPreferences.loginwindow = {
      AdminHostInfo = "HostName";
      showInputMenu = true;
      SHOWFULLNAME = true;
    };

    ############################################################
    ## Screensaver
    ############################################################

    system.defaults.CustomUserPreferences."com.apple.screensaver" = {
      idleTime = 1800;
    };

    ############################################################
    ## Screenshots
    ############################################################

    system.defaults.screencapture = {
      location = "/tmp";
      type = "png";
      disable-shadow = true;
    };

    ############################################################
    ## Finder
    ############################################################

    system.defaults.finder = {
      AppleShowAllExtensions = true;
      QuitMenuItem = true;
      NewWindowTarget = "Home";

      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;

      ShowStatusBar = true;
      ShowPathbar = true;

      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;

      FXPreferredViewStyle = "Nlsv";
    };

    system.defaults.CustomUserPreferences.finder = {
      DisableAllAnimations = true;

      FXInfoPanesExpanded = {
        General = true;
        OpenWith = true;
        Privileges = true;
      };

      WarnOnEmptyTrash = false;
    };

    system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    system.defaults.CustomUserPreferences."com.apple.frameworks.diskimages" = {
      "skip-verify" = true;
      "skip-verify-locked" = true;
      "skip-verify-remote" = true;
      "auto-open-ro-root" = true;
      "auto-open-rw-root" = true;
    };

    ############################################################
    ## Dock
    ############################################################

    system.defaults.dock = {
      "mouse-over-hilite-stack" = true;
      tilesize = 36;
      mineffect = "scale";
      "minimize-to-application" = true;
      "enable-spring-load-actions-on-all-items" = true;
      "show-process-indicators" = true;
      "persistent-apps" = [ ];
      "static-only" = true;
      launchanim = false;
      "expose-animation-duration" = 0.1;
      "expose-group-apps" = false;
      "dashboard-in-overlay" = true;
      "mru-spaces" = false;

      autohide = true;
      "autohide-delay" = 0.0;
      "autohide-time-modifier" = 0.0;

      showhidden = false;
      "show-recents" = true;
    };

    system.defaults.CustomUserPreferences."com.apple.dashboard" = {
      mcx-disabled = true;
    };

    ############################################################
    ## Activity Monitor
    ############################################################

    system.defaults.ActivityMonitor = {
      IconType = 5;
      OpenMainWindow = true;
      ShowCategory = 100;
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    ############################################################
    ## Time Machine / Software Update
    ############################################################

    system.defaults.CustomUserPreferences."com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = true;
    };

    system.defaults.CustomUserPreferences."com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      ScheduleFrequency = 1;
      AutomaticDownload = 1;
      CriticalUpdateInstall = 1;
      ConfigDataInstall = 1;
    };

    system.defaults.CustomUserPreferences."com.apple.commerce" = {
      AutoUpdate = true;
      AutoUpdateRestartRequired = true;
    };

    system.defaults.CustomUserPreferences."com.apple.appstore" = {
      WebKitDeveloperExtras = true;
      ShowDebugMenu = true;
    };

    system.defaults.CustomUserPreferences."com.apple.ImageCapture" = {
      disableHotPlug = true;
    };

    ############################################################
    ## Terminal
    ############################################################

    system.defaults.CustomUserPreferences."com.apple.terminal" = {
      StringEncodings = [ 4 ];
      SecureKeyboardEntry = true;
      ShowLineMarks = 0;
    };

    ############################################################
    ## QuickTime
    ############################################################

    system.defaults.CustomUserPreferences."com.apple.QuickTimePlayerX" = {
      MGPlayMovieOnOpen = true;
    };

    ############################################################
    ## Screensaver password
    ############################################################

    system.defaults.screensaver.askForPasswordDelay = 10;
  };
}
