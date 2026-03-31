#!/bin/bash

chosen=$(printf "⏻  Shutdown\n󰜉  Restart\n⏾  Suspend\n󰍃  Logout" \
  | wofi --dmenu \
         --prompt "Power" \
         --width 300 \
         --height 150 \
         --hide-scroll \
         --hide-search \
         --no-actions \
         --insensitive)

case "$chosen" in
  "⏻  Shutdown")  systemctl poweroff ;;
  "󰜉  Restart")   systemctl reboot ;;
  "⏾  Suspend")   systemctl suspend ;;
  "󰍃 Logout")    hyprctl dispatch exit ;;
esac