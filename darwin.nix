{ config, pkgs, lib, ... }:

let
  # Home profile: the HM user named "di"
  isHomeProfile =
    (config.home-manager.users.di.home.username or "") == "di";

  workCasks = [
    # Core utilities
    "alt-tab"
    "bartender"
    "monitorcontrol"
    "rectangle"
    "the-unarchiver"
    "istat-menus"

    # Browsers / general apps
    "brave-browser"
    "libreoffice"
    "spotify"

    # Dev tools
    "iterm2"
    "visual-studio-code"
    "docker-desktop"
    "insomnia"
    "obsidian"

    # QuickLook helpers
    "quicklook-csv"
    "quicklook-json"
  ];

  homeOnlyCasks = [
    # Personal dev tools
    "intellij-idea"
    "virtualbox"
    "visualvm"
    "cyberduck"
    "qmk-toolbox"

    # Security / crypto
    "keybase"
    "keepassxc"
    "gpg-suite"

    # AI / local LLMs
    "anythingllm"

    # Media / creative
    "gimp"
    "shotcut"
    "fbreader"
    "simple-comic"
    "handbrake-app"
    "vlc"

    # Sync / VPN
    "syncthing-app"
    "mullvad-vpn"

    # Communication / personal
    "telegram"
    "whatsapp"
  ];
in
{
  # Required
  system.stateVersion = 6;

  nix.settings.experimental-features = "nix-command flakes";

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.di = {
    # If the user already exists in macOS, nix-darwin won't recreate it,
    # but this lets Home Manager know the correct home directory.
    home = "/Users/di";
    shell = pkgs.zsh;  # optional, but nice
  };

  # Your primary macOS user
  system.primaryUser = "di";

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    taps = [
      "homebrew/cask"
    ];

    casks =
      workCasks
      ++ lib.optionals isHomeProfile homeOnlyCasks;
  };

  fonts = {
  packages = with pkgs; [
  nerd-fonts."_0xproto"
  nerd-fonts."_3270"
  nerd-fonts."adwaita-mono"
  nerd-fonts."agave"
  nerd-fonts."anonymice"
  nerd-fonts."arimo"
  nerd-fonts."atkynson-mono"
  nerd-fonts."aurulent-sans-mono"
  nerd-fonts."bigblue-terminal"
  nerd-fonts."bitstream-vera-sans-mono"
  nerd-fonts."blex-mono"
  nerd-fonts."caskaydia-cove"
  nerd-fonts."caskaydia-mono"
  nerd-fonts."code-new-roman"
  nerd-fonts."comic-shanns-mono"
  nerd-fonts."commit-mono"
  nerd-fonts."cousine"
  nerd-fonts."d2coding"
  nerd-fonts."daddy-time-mono"
  nerd-fonts."dejavu-sans-mono"
  nerd-fonts."departure-mono"
  nerd-fonts."droid-sans-mono"
  nerd-fonts."envy-code-r"
  nerd-fonts."fantasque-sans-mono"
  nerd-fonts."fira-code"
  nerd-fonts."fira-mono"
  nerd-fonts."geist-mono"
  nerd-fonts."go-mono"
  nerd-fonts."gohufont"
  nerd-fonts."hack"
  nerd-fonts."hasklug"
  nerd-fonts."heavy-data"
  nerd-fonts."hurmit"
  nerd-fonts."im-writing"
  nerd-fonts."inconsolata"
  nerd-fonts."inconsolata-go"
  nerd-fonts."inconsolata-lgc"
  nerd-fonts."intone-mono"
  nerd-fonts."iosevka"
  nerd-fonts."iosevka-term"
  nerd-fonts."iosevka-term-slab"
  nerd-fonts."jetbrains-mono"
  nerd-fonts."lekton"
  nerd-fonts."liberation"
  nerd-fonts."lilex"
  nerd-fonts."m+"
  nerd-fonts."martian-mono"
  nerd-fonts."meslo-lg"
  nerd-fonts."monaspace"
  nerd-fonts."monofur"
  nerd-fonts."monoid"
  nerd-fonts."mononoki"
  nerd-fonts."noto"
  nerd-fonts."open-dyslexic"
  nerd-fonts."overpass"
  nerd-fonts."profont"
  nerd-fonts."proggy-clean-tt"
  nerd-fonts."recursive-mono"
  nerd-fonts."roboto-mono"
  nerd-fonts."sauce-code-pro"
  nerd-fonts."shure-tech-mono"
  nerd-fonts."space-mono"
  nerd-fonts."symbols-only"
  nerd-fonts."terminess-ttf"
  nerd-fonts."tinos"
  nerd-fonts."ubuntu"
  nerd-fonts."ubuntu-mono"
  nerd-fonts."ubuntu-sans"
  nerd-fonts."victor-mono"
  nerd-fonts."zed-mono"
  ];
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
  ## Safari
  ############################################################

  # ⚠ Safari prefs may fail without Full Disk Access
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

    # AC
    pmset -c displaysleep 0
    pmset -c sleep 0

    # Battery
    pmset -b displaysleep 2
    pmset -b sleep 10

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
