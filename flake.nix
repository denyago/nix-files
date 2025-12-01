{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.vim # pkgs.alejandra pkgs.statix pkgs.deadnix
        ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Use Touch ID for sudo authentication.
      security.pam.services.sudo_local.touchIdAuth = true;

      system.primaryUser = "di";

      #### General UI / UX (NSGlobalDomain) #######################################

  system.defaults.NSGlobalDomain = {
    NSTableViewDefaultSizeMode = 2;               # sidebar icon size: medium
    AppleShowScrollBars = "Always";               # Always show scrollbars

    NSUseAnimatedFocusRing = false;
    NSWindowResizeTime = 0.001;

    # Save / print panels expanded
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
    PMPrintingExpandedStateForPrint = true;
    PMPrintingExpandedStateForPrint2 = true;

    # Save to disk, not iCloud
    NSDocumentSaveNewDocumentsToCloud = false;

    # Typing / “smart” features
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;

    # Keyboard navigation / zoom
    AppleKeyboardUIMode = 3;

    # Key repeat
    ApplePressAndHoldEnabled = false;
    KeyRepeat = 1;
    InitialKeyRepeat = 10;

    AppleMeasurementUnits = "Centimeters";
    AppleMetricUnits = 1;     # ✔ 1 = metric, 0 = imperial

    # Text / rendering
    NSTextShowsControlCharacters = true;
    AppleFontSmoothing = 1;
  };

  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      AppleEnableMenuBarTransparency = false;
      # Language / locale
      AppleLanguages = [ "en" "ua" "ru" ];
      AppleLocale = "en_GB@currency=EUR";
      # Keyboard navigation / zoom
      HIDScrollZoomModifierMask = 262144;
      closeViewScrollWheelToggle = true;
      closeViewZoomFollowsFocus = true;
    };
  };

  #### Loginwindow / language menu ###########################################

  system.defaults.CustomUserPreferences.loginwindow = {
    AdminHostInfo = "HostName";    # show IP/hostname/etc on login screen
    showInputMenu = true;          # show language menu at login
  };

  #### Screenshots ###########################################################

  system.defaults.screencapture = {
    location = "/tmp";
    type = "png";
    disable-shadow = true;
  };

  #### Finder ###############################################################

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    QuitMenuItem = true;                        # allow ⌘+Q
    NewWindowTarget = "Home";
    ShowExternalHardDrivesOnDesktop = true;
    ShowHardDrivesOnDesktop = false;
    ShowMountedServersOnDesktop = true;
    ShowRemovableMediaOnDesktop = true;
    ShowStatusBar = true;
    ShowPathbar = true;
    _FXShowPosixPathInTitle = true;
    _FXSortFoldersFirst = true;
    FXDefaultSearchScope = "SCcf";              # search current folder
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "Nlsv";              # Default Finder folder view is the columns view
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

  # Global “show all extensions” still belongs to NSGlobalDomain:
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

  # DesktopServices (.DS_Store behaviour)
  system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
    DSDontWriteNetworkStores = true;
    DSDontWriteUSBStores = true;
  };

  # Disk image verification & auto-open behaviour
  system.defaults.CustomUserPreferences."com.apple.frameworks.diskimages" = {
    "skip-verify" = true;
    "skip-verify-locked" = true;
    "skip-verify-remote" = true;
    "auto-open-ro-root" = true;
    "auto-open-rw-root" = true;
  };

  #### Dock ##################################################################

  system.defaults.dock = {
    "mouse-over-hilite-stack" = true;
    tilesize = 36;
    mineffect = "scale";
    "minimize-to-application" = true;
    "enable-spring-load-actions-on-all-items" = true;
    "show-process-indicators" = true;

    # Clear default icons & show only open apps
    "persistent-apps" = [ ];
    "static-only" = true;

    launchanim = false;
    "expose-animation-duration" = 0.1;
    "expose-group-apps" = false;

    "dashboard-in-overlay" = true;
    "mru-spaces" = false; # Don’t rearrange spaces based on the most recent use

    autohide = true; # Don't autohide the dock.
    "autohide-delay" = 0.0;
    "autohide-time-modifier" = 0.0;

    showhidden = false;
    "show-recents" = true;
  };

#### Dashboard ###############################################################
system.defaults.CustomUserPreferences = {

  "com.apple.dashboard" = {
    mcx-disabled = true;
  };
};

  #### Activity Monitor ######################################################

  system.defaults.ActivityMonitor = {
  IconType = 5;            # CPU in Dock
  OpenMainWindow = true;

  # IMPORTANT: ShowCategory must be one of 100–107, not 0:
  # 100 = All Processes, 102 = My Processes, etc.
  ShowCategory = 100;      # 100 = All Processes

  SortColumn = "CPUUsage";
  SortDirection = 0;       # 0 = descending
};

  #### Safari & WebKit #######################################################

  system.defaults.CustomUserPreferences."com.apple.Safari" = {
    UniversalSearchEnabled = false;
    SuppressSearchSuggestions = true;
    WebKitTabToLinksPreferenceKey = true;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks" = true;
    ShowFullURLInSmartSearchField = true;
    HomePage = "about:blank";
    AutoOpenSafeDownloads = false;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled" = true;
    ShowFavoritesBar = false;
    ShowSidebarInTopSites = false;
    DebugSnapshotsUpdatePolicy = 2;
    IncludeInternalDebugMenu = true;
    FindOnPageMatchesWordStartsOnly = false;
    ProxiesInBookmarksBar = "()";
    IncludeDevelopMenu = true;
    WebKitDeveloperExtrasEnabledPreferenceKey = true;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
    WebContinuousSpellCheckingEnabled = true;
    WebAutomaticSpellingCorrectionEnabled = false;
    AutoFillFromAddressBook = false;
    AutoFillPasswords = false;
    AutoFillCreditCardData = false;
    AutoFillMiscellaneousForms = false;
    WarnAboutFraudulentWebsites = true;
    WebKitPluginsEnabled = false;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled" = false;
    WebKitJavaEnabled = false;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled" = false;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles" = false;
    WebKitJavaScriptCanOpenWindowsAutomatically = false;
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" = false;
    SendDoNotTrackHTTPHeader = true;
    InstallExtensionUpdatesAutomatically = true;
  };

  # Global WebKit developer extras
  system.defaults.CustomUserPreferences.NSGlobalDomain.WebKitDeveloperExtras = true;

  #### Time Machine ##########################################################

  system.defaults.CustomUserPreferences."com.apple.TimeMachine" = {
    DoNotOfferNewDisksForBackup = true;
  };

  #### Software Update / App Store ###########################################

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

  #### Photos ################################################################

system.defaults.CustomUserPreferences."com.apple.ImageCapture" = {
    disableHotPlug = true;
};

  #### Terminal ##############################################################

  system.defaults.CustomUserPreferences."com.apple.terminal" = {
    StringEncodings = [ 4 ];
    SecureKeyboardEntry = true;
    ShowLineMarks = 0;
  };

  #### QuickTime #############################################################

  system.defaults.CustomUserPreferences."com.apple.QuickTimePlayerX" = {
    MGPlayMovieOnOpen = true;
  };


      system.defaults.screensaver = { 
        askForPasswordDelay = 10;
      };

  #######################################################
  # Power management & TM: small activation script     #
  #######################################################

  system.activationScripts.postActivation.text = ''
  # General power settings
  pmset -a lidwake 1
  pmset -a autorestart 1
  pmset -a standbydelay 86400

  # Display sleep and system sleep (consistent values)
  # AC power:
  pmset -c displaysleep 0
  pmset -c sleep 0

  # Battery:
  pmset -b displaysleep 2
  pmset -b sleep 10

  # Disable Time Machine local snapshots
  if command -v tmutil >/dev/null 2>&1; then
    tmutil disable || true
  fi
  '';

    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."Denyss-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
