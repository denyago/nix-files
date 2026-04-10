{ ... }:
{
  flake.modules.darwin.macos-privacy = {
    # Disable Apple Intelligence (Writing Tools, summaries, etc.)
    system.defaults.CustomUserPreferences."com.apple.AppleIntelligence" = {
      SiriNLPEnabled = false;
    };

    # Disable Siri
    system.defaults.CustomUserPreferences."com.apple.Siri" = {
      SiriPrefStashedStatusMenuVisible = false;
      StatusMenuVisible = false;
      SiriDataSharingOptIn = false;
      VoiceTriggerUserEnabled = false;
    };

    # Disable Siri assistant
    system.defaults.CustomUserPreferences."com.apple.assistant.support" = {
      "Assistant Enabled" = false;
    };

    # Disable Spotlight web/Siri suggestions
    system.defaults.CustomUserPreferences."com.apple.lookup.shared" = {
      LookupSuggestionsDisabled = true;
    };

    # Disable enhanced visual search in Photos
    system.defaults.CustomUserPreferences."com.apple.photos" = {
      VisualSearchEnabled = false;
    };
  };
}
