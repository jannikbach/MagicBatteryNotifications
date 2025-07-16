# macOS Bluetooth Device Battery Monitor

This project provides a simple yet effective way to monitor the battery levels of your Bluetooth keyboard and mouse on macOS. It leverages `launchd` to run a script in the background, notifying you when your devices have low battery, both when your screen locks and at scheduled times. This is a more robust solution than `cron` for persistent background tasks and event-driven triggers.

## Features

- **Low Battery Notifications:** Get notified when your Bluetooth keyboard or mouse battery drops below a configurable threshold.
- **Screen Lock Monitoring:** Receive instant notifications when your screen locks and a device has low battery.
- **Scheduled Checks:** Configure daily scheduled checks (e.g., morning and evening) to ensure you're always aware of your battery levels.
- **Robust `launchd` Integration:** Utilizes `launchd` for persistent and reliable background operation, superior to `cron` for event-driven tasks on macOS.

## How it Works

The system consists of a shell script (`check_batteries.sh`) that queries your Bluetooth device battery levels and sends macOS notifications. Two `launchd` agents are set up:

1.  One agent runs continuously in the background, monitoring for screen lock events.
2.  Another agent runs the script at specified intervals (e.g., twice a day).

## Table of Contents

- [Getting Started](#getting-started)
  - [1. Prepare the `check_batteries.sh` Script](#1-prepare-the-check_batteries.sh-script)
  - [2. Test Notifications](#2-test-notifications)
  - [3. Create Launch Agent for Screen Lock Monitoring](#3-create-launch-agent-for-screen-lock-monitoring)
  - [4. Create Launch Agent for Scheduled Checks](#4-create-launch-agent-for-scheduled-checks)
  - [5. Load the Launch Agents](#5-load-the-launch-agents)
  - [6. Verify Setup](#6-verify-setup)
- [Usage](#usage)
- [Updating the Script](#updating-the-script)
- [Credits](#credits)
- [License](#license)


## Getting Started

### 1. Clone the repository using: 
``` bash 
git clone https://github.com/jannikbach/MagicBatteryNotifications.git
cd MagicBatteryNotifications
chmod +x ~/check_batteries.sh```
```

**Configure the script:**
    Open `~/check_batteries.sh` again and modify the `KEYBOARD_NAME`, `MOUSE_NAME`, and `LOW_BATTERY_THRESHOLD` variables to match your devices and preferences.

```bash
    #  Configuration 
    KEYBOARD_NAME="Your Keyboard Name" # IMPORTANT: Replace with the exact name of your keyboard as it appears in System Settings -> Bluetooth
    MOUSE_NAME="Your Mouse Name"     # IMPORTANT: Replace with the exact name of your mouse as it appears in System Settings -> Bluetooth
    LOW_BATTERY_THRESHOLD=20         # Set your desired low battery percentage threshold
    DEBOUNCE_TIME=10                  # Prevent duplicate notifications within 10 seconds
    ```

    To find the exact names of your Bluetooth devices:
    *   Go to **System Settings** > **Bluetooth**.
    *   Note the names of your connected keyboard and mouse exactly as they appear there.

    Save and exit the script after making your changes.
```


### 2. Test Notifications

Before proceeding, it's crucial to ensure that macOS notifications are working correctly for scripts.

1.  **Test a manual notification:**
    Open your Terminal and run the following command:
    ```bash
    osascript -e 'display notification "This is a test notification." with title "Test Notification"'
    ```
    You should see a notification appear on your screen.

### Troubleshooting Notifications

If you *do not* see the test notification, here are the most common reasons and solutions:

*   **"Do Not Disturb" or Focus Mode is active:**
    *   **Reason:** These modes suppress all notifications.
    *   **Solution:** Disable "Do Not Disturb" or any active Focus mode in your macOS Control Center or System Settings > Focus.

*   **Terminal application lacks notification permissions:**
    *   **Reason:** Sometimes, the Terminal application (or whichever app you're using to run `osascript`) hasn't been granted permission to display notifications, or the permission prompt was missed.
    *   **Solution:**
        1.  Go to **System Settings** > **Notifications**.
        2.  Look for your Terminal application (e.g., "Terminal", "iTerm2").
        3.  Ensure that **"Allow Notifications"** is turned on.
        4.  If your Terminal app is *not* listed, you might need to force macOS to prompt for permission. The most reliable way is to create a temporary application that sends a notification.
            *   Open **Script Editor** (found via Spotlight Search).
            *   Paste: `display notification "This is a test." with title "Permission Test"`
            *   Go to `File` > `Save...`.
            *   Name it `NotificationTester`, choose `Desktop` as location.
            *   **Crucially**, change "File Format" to **`Application`**.
            *   Click `Save`.
            *   Double-click the `NotificationTester` app on your Desktop. When prompted, **click "Allow"** to grant notification permissions. You can then delete the `NotificationTester` app. After this, try the `osascript` command in Terminal again.


### 3. Create Launch Agent for Screen Lock Monitoring

This `launchd` agent will keep your script running in the background, specifically listening for screen lock events.

1.  **Create the `LaunchAgents` directory if it doesn't exist:**
    ```bash
    mkdir -p ~/Library/LaunchAgents
    ```

2.  **Open a text editor to create the file:**
    ```bash
    nano ~/Library/LaunchAgents/com.user.battery_monitor.lock.plist
    ```

3.  **Paste the following content into the editor:**

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.user.battery_monitor.lock</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/bash</string>
            <string>$PATH_TO_YOUR_MagicBatteryNotifications_REPOSITORY$/check_batteries.sh</string>
            <string>--mode=lock</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/tmp/battery_monitor_lock.out</string>
        <key>StandardErrorPath</key>
        <string>/tmp/battery_monitor_lock.err</string>
    </dict>
    </plist>
    ```
    *   **Important:** Ensure the path to `check_batteries.sh` is correct: Therefore replace the `$PATH_TO_YOUR_MagicBatteryNotifications_REPOSITORY$` placeholder in `check_batteries.sh` with the actual path to this directory on your system.

4.  **Save and exit** the editor (Ctrl+O, Enter, Ctrl+X if using `nano`).



    

This `launchd` agent will run your script twice a day (e.g., 8 AM and 8 PM).

1.  **Open a text editor to create the file:**
    ```bash
    nano ~/Library/LaunchAgents/com.user.battery_monitor.scheduled.plist
    ```

2.  **Paste the following content into the editor:**

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.user.battery_monitor.scheduled</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/bash</string>
            <string>$PATH_TO_YOUR_MagicBatteryNotifications_REPOSITORY$/check_batteries.sh</string>
            <string>--mode=scheduled</string>
        </array>
        <key>StartCalendarInterval</key>
        <array>
            <dict>
                <key>Hour</key>
                <integer>8</integer>
                <key>Minute</key>
                <integer>0</integer>
            </dict>
            <dict>
                <key>Hour</key>
                <integer>20</integer>
                <key>Minute</key>
                <integer>0</integer>
            </dict>
        </array>
        <key>StandardOutPath</key>
        <string>/tmp/battery_monitor_scheduled.out</string>
        <key>StandardErrorPath</key>
        <string>/tmp/battery_monitor_scheduled.err</string>
    </dict>
    </plist>
    ```
    *   **Important:** Ensure the path to `check_batteries.sh` is correct: Therefore replace the `$PATH_TO_YOUR_MagicBatteryNotifications_REPOSITORY$` placeholder in `check_batteries.sh` with the actual path to this directory on your system.
    *   You can change `Hour` values (e.g., `9` for 9 AM, `17` for 5 PM) if you want different times.

3.  **Save and exit** the editor (Ctrl+O, Enter, Ctrl+X if using `nano`).



### 5. Load the Launch Agents

Now, load the newly created `launchd` agents.

1.  **Load the screen lock monitor:**
    ```bash
    launchctl load ~/Library/LaunchAgents/com.user.battery_monitor.lock.plist
    ```

2.  **Load the scheduled checks:**
    ```bash
    launchctl load ~/Library/LaunchAgents/com.user.battery_monitor.scheduled.plist
    ```



### 6. Verify Setup

You can verify that both `launchd` agents are loaded and running:

```bash
launchctl list | grep battery_monitor
```
You should see output similar to this (PIDs might vary):
```
21536   0   com.user.battery_monitor.lock
-   0   com.user.battery_monitor.scheduled
```



## Usage

Once you have completed the setup steps, your macOS system will automatically monitor your Bluetooth device battery levels and notify you according to your configuration.

*   **Screen Lock Notifications:** When your screen locks, the system will check battery levels and send notifications if any configured device is below the `LOW_BATTERY_THRESHOLD`.
*   **Scheduled Notifications:** At the hours you specified in the `com.user.battery_monitor.scheduled.plist` file (e.g., 8 AM and 8 PM), the system will perform a battery check and send notifications for low battery devices.

To manually trigger a battery check at any time, you can run the script directly from your Terminal:

Navigate to the directory where `check_batteries.sh` is located and run:
```bash
./check_batteries.sh --mode=scheduled
```

You are now fully set up with a robust battery monitoring system using `launchd`!


## Updating the Script

If you make changes to your `check_batteries.sh` script in the future:

*   **For scheduled checks:** Changes will be picked up automatically the next time the scheduled job runs. No action needed.
*   **For screen lock monitoring:** Since this agent runs continuously, you need to restart it for changes to take effect.
    ```bash
    launchctl unload ~/Library/LaunchAgents/com.user.battery_monitor.lock.plist
    launchctl load ~/Library/LaunchAgents/com.user.battery_monitor.lock.plist
    ```
## Credits

This project was inspired by a post by [samselfridge](https://dev.to/samselfridge) on [DEV](https://dev.to/samselfridge/magic-mouse-low-battery-alert-4mdo) and the reddit user [u/victorpetraitis](https://www.reddit.com/user/victorpetraitis/) with his [tutorial](https://jumpshare.com/v/vXQ9XbpqnDL1BEew6xBD).



## License

This project is licensed under the MIT License - see the LICENSE.md file for details.