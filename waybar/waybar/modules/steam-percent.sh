#!/bin/bash

LOG="$HOME/.local/share/Steam/logs/content_log.txt"
LIBRARY_ROOTS=(
    "$HOME/.local/share/Steam/steamapps"
    "$HOME/SSD_Data/SteamLibrary/steamapps"
)

SKIP_IDS=("228980" "228987" "228990" "1070560")

if ! pgrep -x "steam" > /dev/null; then
    echo '{"text": "", "tooltip": "Steam not running"}'
    exit 0
fi

# Scan manifests for active download
MANIFEST=""
APPID=""
for ROOT in "${LIBRARY_ROOTS[@]}"; do
    for ACF in "$ROOT"/appmanifest_*.acf; do
        [ -f "$ACF" ] || continue
        ACF_ID=$(grep -oP '"appid"\s+"\K[0-9]+' "$ACF" | head -1)
        SKIP=0
        for ID in "${SKIP_IDS[@]}"; do
            [ "$ACF_ID" = "$ID" ] && SKIP=1 && break
        done
        [ "$SKIP" = "1" ] && continue
        FLAGS=$(grep -oP '"StateFlags"\s+"\K[0-9]+' "$ACF")
        if [ "$FLAGS" = "1026" ] || [ "$FLAGS" = "1028" ] || [ "$FLAGS" = "1030" ]; then
            MANIFEST="$ACF"
            APPID="$ACF_ID"
            LIBRARY_ROOT="$ROOT"
            break 2
        fi
    done
done

if [ -z "$MANIFEST" ]; then
    echo '{"text": "", "tooltip": "No active downloads"}'
    exit 0
fi

GAME_NAME=$(grep -oP '"name"\s+"\K[^"]+' "$MANIFEST" | head -1)
INSTALL_DIR=$(grep -oP '"installdir"\s+"\K[^"]+' "$MANIFEST" | head -1)
BYTES_TO_STAGE=$(grep -oP '"BytesToStage"\s+"\K[0-9]+' "$MANIFEST")

if [ -z "$BYTES_TO_STAGE" ] || [ "$BYTES_TO_STAGE" -eq 0 ]; then
    echo '{"text": " Starting...", "tooltip": "'"$GAME_NAME"'"}'
    exit 0
fi

# Measure bytes in downloading folder + staged files in common
DOWNLOADING_SIZE=$(du -sb "$LIBRARY_ROOT/downloading/$APPID" 2>/dev/null | awk '{print $1}')
STAGED_SIZE=$(du -sb "$LIBRARY_ROOT/common/$INSTALL_DIR" 2>/dev/null | awk '{print $1}')
DOWNLOADING_SIZE=${DOWNLOADING_SIZE:-0}
STAGED_SIZE=${STAGED_SIZE:-0}
DONE=$(( DOWNLOADING_SIZE + STAGED_SIZE ))

PERCENT=$(awk "BEGIN {p=($DONE/$BYTES_TO_STAGE)*100; if(p>100)p=100; printf \"%.1f\", p}")
PERCENT_INT=$(awk "BEGIN {p=int(($DONE/$BYTES_TO_STAGE)*100); if(p>100)p=100; print p}")

RATE=$(grep -oP "Current download rate: \K[0-9.]+ Mbps" "$LOG" | tail -1)

DONE_GB=$(awk "BEGIN {printf \"%.2f\", $DONE / 1073741824}")
TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $BYTES_TO_STAGE / 1073741824}")

TOOLTIP="$GAME_NAME\n${DONE_GB} GB / ${TOTAL_GB} GB\nRate: ${RATE:-N/A}"

echo "{\"text\": \"${GAME_NAME} - ${PERCENT}%\", \"tooltip\": \"${DONE_GB} GB / ${TOTAL_GB} GB\nRate: ${RATE:-N/A}\", \"percentage\": ${PERCENT_INT}}"