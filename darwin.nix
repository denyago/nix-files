{ config, pkgs, lib, userProfile, workInternal, ... }:

let
  workCasks = [
    # Core utilities
    "alt-tab"
    "bartender"
    "monitorcontrol"
    "rectangle"
    "the-unarchiver"
    "istat-menus"
    "disk-inventory-x"

    # Browsers / general apps
    "brave-browser"
    "libreoffice"
    "spotify"

    # Dev tools
    "iterm2"
    "visual-studio-code"
    "docker-desktop"
    "obsidian"

    # QuickLook helpers
    "quicklook-csv"
    "quicklook-json"
  ];

  homeOnlyCasks = [
    # TO-BE-MOVED to work profile when needed
    "grammarly-desktop"

    # Personal dev tools
    "intellij-idea"
    "virtualbox"
    "visualvm"
    "qmk-toolbox"

    # Misk core utilities
    "cyberduck"
    "forklift"
    "keepingyouawake"
    "monitorcontrol"

    # Security / crypto
    "keybase"
    "keepassxc"
    "gpg-suite"
    "little-snitch"

    # AI / local LLMs
    "anythingllm"

    # Media / creative
    "gimp"
    "shotcut"
    "fbreader"
    "simple-comic"
    "handbrake-app"
    "vlc"

    # Sync / VPN / Privacy
    "syncthing-app"
    "mullvad-vpn"
    "librewolf"
    "macfuse"
    "nextcloud-vfs"

    # Communication / personal
    "telegram"
    "whatsapp"
  ];

  workBrews = [
    "python@3.12"
    "pipx"
  ];
in
{
  # Required
  system.stateVersion = 6;

  nix.settings.experimental-features = "nix-command flakes";

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.${userProfile.username} = {
    # If the user already exists in macOS, nix-darwin won't recreate it,
    # but this lets Home Manager know the correct home directory.
    home = "/Users/${userProfile.username}";
    shell = pkgs.zsh;  # optional, but nice
  };

  # Your primary macOS user
  system.primaryUser = userProfile.username;

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    taps = workInternal.taps;

    brews = workBrews ++ workInternal.brews;

    casks =
      workCasks
      ++ lib.optionals userProfile.isHomeProfile homeOnlyCasks
      ++ workInternal.casks;
  };

  fonts = {
    packages =
      let
        nerdFontsAll =
          pkgs.nerd-fonts;

        # Remove helper attrs that are not fonts
        nerdFontsOnly =
          builtins.removeAttrs nerdFontsAll [
            "override"
            "overrideDerivation"
            "recurseForDerivations"
          ];
      in
        builtins.attrValues nerdFontsOnly;
  };

  # Put profiles into /etc so nix-darwin can manage them
  environment.etc."iterm2/DynamicProfiles/denyago.json".source =
    ./macos/iterm2/DynamicProfiles/denyago.json;

  # Tell iTerm2 to load preferences from /etc/iterm2

  system.defaults.CustomUserPreferences."com.googlecode.iterm2" = {
    # Tell iTerm2 where to look for dynamic profiles
    DynamicProfilesPath = "/etc/iterm2/DynamicProfiles";
  };

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

    AppleLanguages = [ "en" "ua" "ru" ];
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
  ## Loginwindow
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
    "persistent-apps" = [];
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
  ## Screensaver
  ############################################################

  system.defaults.screensaver.askForPasswordDelay = 10;

  ############################################################
  ## Power Management Activation Script
  ############################################################

  system.activationScripts.powerAndTm.text = ''
    pmset -a lidwake 1
    pmset -a autorestart 1
    pmset -a standbydelay 86400

    /usr/bin/pmset -b displaysleep 30 sleep 30
    /usr/bin/pmset -c displaysleep 30 sleep 30

    # Disable Time Machine local snapshots
    if command -v tmutil >/dev/null 2>&1; then
      tmutil disable || true
    fi
  '';

  system.activationScripts.nvramBootChime.text = ''
    # Disable boot chime; ignore errors on locked-down systems
    /usr/sbin/nvram SystemAudioVolume=" " || true
  '';
}
