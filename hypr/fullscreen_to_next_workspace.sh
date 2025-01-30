#!/bin/bash

STATE_FILE="$HOME/.cache/hyprland-fullscreen-state"

current_window_info=$(hyprctl activewindow -j)
if [ -z "$current_window_info" ]; then
    exit 0 # No active window, do nothing
fi
current_workspace=$(echo "$current_window_info" | jq '.workspace.id')
current_fullscreen_state=$(echo "$current_window_info" | jq '.fullscreen')
current_window_address=$(echo "$current_window_info" | jq '.address')

if [ -f "$STATE_FILE" ]; then
    stored_data=$(cat "$STATE_FILE")
    IFS=" " read -r stored_workspace stored_fullscreen_state stored_window_address <<< "$stored_data"

    if [ "$current_window_address" == "$stored_window_address" ]; then
        # Reversible action: Move back and restore fullscreen state
        hyprctl dispatch movetoworkspace "$stored_workspace"
        hyprctl dispatch workspace "$stored_workspace"
        if [ "$stored_fullscreen_state" == "1" ]; then
            if [ "$(echo "$current_window_info" | jq '.fullscreen')" == "0" ]; then
                hyprctl dispatch fullscreen 1 # Force fullscreen type 1
            fi
        elif [ "$stored_fullscreen_state" == "0" ]; then
            if [ "$(echo "$current_window_info" | jq '.fullscreen')" == "1" ]; then
                hyprctl dispatch fullscreen 0 # Revert to not fullscreen (type 0) in reverse
            fi
        fi
        rm "$STATE_FILE"
    else
        # State file exists for a different window, overwrite for current window
        next_workspace=$((current_workspace + 1))
        echo "$current_workspace $current_fullscreen_state $current_window_address" > "$STATE_FILE"
        hyprctl dispatch movetoworkspace "$next_workspace"
        hyprctl dispatch workspace "$next_workspace"
        hyprctl dispatch fullscreen 1 # Force fullscreen type 1
    fi
else
    # Forward action: Move to next workspace and fullscreen
    next_workspace=$((current_workspace + 1))
    echo "$current_workspace $current_fullscreen_state $current_window_address" > "$STATE_FILE"
    hyprctl dispatch movetoworkspace "$next_workspace"
    hyprctl dispatch workspace "$next_workspace"
    hyprctl dispatch fullscreen 1 # Force fullscreen type 1
fi

exit 0
