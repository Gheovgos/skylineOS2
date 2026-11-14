#!/bin/sh

SETTINGS_DIR="$HOME/.config/pegasus-frontend/theme_settings"
SETTINGS_FILE="$SETTINGS_DIR/skylineOS2.json"
OUT_FILE="$HOME/.config/pegasus-frontend/launcher_user.txt"

if [ ! -f "$SETTINGS_FILE" ]; then
    exit 0
fi

USER_NAME=$(sed -n 's/.*"Launcher User"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$SETTINGS_FILE" | head -n 1)

printf '%s\n' "$USER_NAME" > "$OUT_FILE"
