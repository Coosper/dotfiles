#!/bin/bash

# Device names
HEADPHONES="alsa_output.usb-Logitech_PRO_X_000000000000-00.analog-stereo"
SPEAKERS="alsa_output.pci-0000_2d_00.1.hdmi-stereo-extra1"

# Get current default sink
CURRENT=$(pactl get-default-sink)

# Status output for Waybar
if [ "$1" = "--status" ]; then
    if [ "$CURRENT" = "$HEADPHONES" ]; then
        printf '{"text":"󰋋 Headphones","tooltip":"Headphones"}\n'
    else
        printf '{"text":"󰓃 Speakers","tooltip":"Speakers"}\n'
    fi
    exit 0
fi

# Toggle between devices
if [ "$CURRENT" = "$HEADPHONES" ]; then
    pactl set-default-sink "$SPEAKERS"
    notify-send -u low -t 2000 "Audio Output" "Switched to Speakers 󰓃" -h string:x-canonical-private-synchronous:audio
else
    pactl set-default-sink "$HEADPHONES"
    notify-send -u low -t 2000 "Audio Output" "Switched to Headphones 󰋋" -h string:x-canonical-private-synchronous:audio
fi

# Move all currently playing streams to the new sink
NEW_SINK=$(pactl get-default-sink)
pactl list short sink-inputs | while read -r stream; do
    stream_id=$(echo "$stream" | cut -f1)
    pactl move-sink-input "$stream_id" "$NEW_SINK" 2>/dev/null
done