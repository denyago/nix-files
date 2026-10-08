"""Turn macOS "Auto" appearance (dark at night, light by day) on or off, applied immediately.

Usage: set-auto.py true|false

Writing the AppleInterfaceStyleSwitchesAutomatically default alone does not apply it until the next
sunrise/sunset, so this calls the same private SkyLight function that System Settings uses. Exits
non-zero if macOS no longer provides it, so the caller can fall back to the default.
"""

import ctypes
import sys

SKYLIGHT = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"

skylight = ctypes.CDLL(SKYLIGHT)
set_switches_automatically = skylight.SLSSetAppearanceThemeSwitchesAutomatically
set_switches_automatically.argtypes = [ctypes.c_bool]
set_switches_automatically.restype = None

set_switches_automatically(sys.argv[1] == "true")
