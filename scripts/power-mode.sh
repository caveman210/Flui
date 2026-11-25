#!/usr/bin/env bash
set -e

PROFILE_FILE="/sys/firmware/acpi/platform_profile"
CACHE_DIR="$HOME/.cache/quickshell/status"
mkdir -p "$CACHE_DIR"

if command -v powerprofilesctl >/dev/null 2>&1; then
    CURRENT=$(powerprofilesctl get)
    case "$CURRENT" in
        power-saver) NEXT="balanced" ;;
        balanced)    NEXT="performance" ;;
        *)           NEXT="power-saver" ;;
    esac
    powerprofilesctl set "$NEXT"
    [ "$NEXT" = "power-saver" ] && NEXT="low-power"
elif [ -r "$PROFILE_FILE" ]; then
    CURRENT=$(cat "$PROFILE_FILE")
    case "$CURRENT" in
        low-power) NEXT="balanced" ;;
        balanced)  NEXT="performance" ;;
        *)         NEXT="low-power" ;;
    esac
    if [ -w "$PROFILE_FILE" ]; then
        printf "%s\n" "$NEXT" > "$PROFILE_FILE"
    elif sudo -n true 2>/dev/null; then
        printf "%s\n" "$NEXT" | sudo tee "$PROFILE_FILE" >/dev/null
    else
        printf "%s\n" "$NEXT" | pkexec tee "$PROFILE_FILE" >/dev/null
    fi
else
    exit 1
fi

printf "power-mode|%s\n" "$NEXT" > "$CACHE_DIR/event"
