#!/bin/bash

pkill -x swaync 2>/dev/null
sleep 0.5

swaync &
SWAYNC_PID=$!

sleep 2

swaync-client --change-cc-monitor DP-1
swaync-client --change-noti-monitor DP-1