#!/bin/bash

# --- Configuration ---
KEYBOARD_NAME="Your Keyboard Name" # IMPORTANT: Replace with the exact name of your keyboard as it appears in System Settings -> Bluetooth
MOUSE_NAME="Your Mouse Name"     # IMPORTANT: Replace with the exact name of your mouse as it appears in System Settings -> Bluetooth
LOW_BATTERY_THRESHOLD=20
DEBOUNCE_TIME=10                  # Prevent duplicate notifications within 10 seconds
TEMP_LOCK="/tmp/screen_lock_temp.lock" # Lock file to debounce notifications

# --- Functions ---

# Function to get battery percentage for a given device name
get_battery_level() {
    local device_name="$1"
    /usr/sbin/ioreg -l | grep -A 20 "$device_name" | grep "BatteryPercent" | tail -n 1 | awk -F'=' '{print $2}' | tr -d ' '
}

# Function to display a notification
show_notification() {
    local title="$1"
    local message="$2"
    /usr/bin/osascript -e "display notification \"$message\" with title \"$title\""
}

# Function to check battery and send notification for both devices
check_all_batteries() {
    local keyboard_battery=$(get_battery_level "$KEYBOARD_NAME")
    local mouse_battery=$(get_battery_level "$MOUSE_NAME")

    if [[ -n "$keyboard_battery" && "$keyboard_battery" -lt "$LOW_BATTERY_THRESHOLD" ]]; then
        show_notification "Keyboard Battery Low" "Your keyboard battery is at $keyboard_battery%."
    fi

    if [[ -n "$mouse_battery" && "$mouse_battery" -lt "$LOW_BATTERY_THRESHOLD" ]]; then
        show_notification "Mouse Battery Low" "Your mouse battery is at $mouse_battery%."
    fi
}

# Function to debounce notifications for screen lock
debounce_lock_event() {
    local current_time=$(date +%s)
    local last_lock=$(cat "$TEMP_LOCK" 2>/dev/null || echo 0)
    if [[ $((current_time - last_lock)) -ge $DEBOUNCE_TIME ]]; then
        echo $current_time > "$TEMP_LOCK"
        # echo "Screen lock detected. Checking battery..." # For debugging
        check_all_batteries
    else
        # echo "Debounced: Notification suppressed to prevent duplicates." # For debugging
        : # Do nothing, just suppress
    fi
}

# Method 1: Monitor screen lock events via pmset
monitor_pmset() {
    while true; do
        display_state=$(/usr/bin/pmset -g powerstate IODisplayWrangler 2>/dev/null | \
            awk '/IODisplayWrangler/ {print $3}' | grep -Eo '[0-9]+')
        if [[ "$display_state" == "3" ]]; then # 3 means display is off/locked
            debounce_lock_event
        fi
        sleep 1
    done
}

# Method 2: Monitor screen lock events via log stream
monitor_log_stream() {
    /usr/bin/log stream --style syslog --predicate 'eventMessage contains "com.apple.screenIsLocked"' | while read -r line; do
        debounce_lock_event
    done
}

# Main function to handle different modes
main() {
    case "$1" in
        --mode=lock)
            echo "Starting battery monitor for screen lock events..."
            > "$TEMP_LOCK"  # Clear old lock file
            # Run both detection methods in parallel
            monitor_pmset &
            monitor_log_stream &
            wait # Wait for background jobs to finish (which they won't, as they are infinite loops)
            ;;
        --mode=scheduled)
            echo "Performing scheduled battery check..."
            check_all_batteries
            ;;
        *)
            echo "Usage: $0 --mode=[lock|scheduled]"
            exit 1
            ;;
    esac
}

# Call the main function with arguments
main "$@"
