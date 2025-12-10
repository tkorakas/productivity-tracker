# 📊 Productivity Tracker

A macOS menu bar application that tracks real vs. planned productivity using a mathematical model from "The Math of Why You Can't Focus at Work".

## Features

- 🎯 **Focus Session Tracking** — Start/stop work sessions with one click or keyboard shortcut
- ⚡ **Global Shortcut** — Toggle sessions with `⌥⌃Space` (customizable)
- 📈 **Productivity Formula** — Automatic calculation based on focused time and interruptions
- 📅 **Task Management** — Create planned tasks or track ad-hoc sessions
- 📊 **Dashboard** — View daily metrics, weekly trends, and historical data
- 🎨 **Clean UI** — Minimal menu bar interface with optional full dashboard

## Tech Stack

- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Persistence:** SwiftData
- **Shortcuts:** KeyboardShortcuts library
- **Platform:** macOS 13.0+ (Ventura or later)

## Project Structure

```
ProductivityTracker/
├── App/
│   ├── ProductivityTrackerApp.swift    # Main app entry point
│   └── AppDelegate.swift                # Menu bar setup
├── Models/
│   ├── Task.swift                       # Task model with SwiftData
│   ├── WorkSession.swift                # Session tracking model
│   ├── Settings.swift                   # App settings
│   └── DayPlan.swift                    # Daily planning
├── Services/
│   ├── TrackingManager.swift            # Core tracking logic
│   ├── ProductivityCalculator.swift     # Productivity formula
│   └── ShortcutManager.swift            # Keyboard shortcuts
├── Views/
│   ├── MenuBarView.swift                # Menu bar popover
│   ├── DashboardView.swift              # Main dashboard
│   └── Components/                      # Reusable UI components
└── Resources/
    └── Assets.xcassets                  # Icons and images
```

## Installation

### Option 1: Build from Source (Xcode)

1. **Open in Xcode:**
   ```bash
   cd productivity-tracker
   open Package.swift
   ```

2. **Wait for Swift Package Manager** to resolve dependencies (KeyboardShortcuts)

3. **Build and Run:**
   - Press `⌘R` or click the Run button
   - The app will appear in your menu bar

### Option 2: Build with Swift Package Manager

```bash
swift build -c release
./.build/release/ProductivityTracker
```

## Usage

### Starting a Session

1. Click the menu bar icon
2. Click "Start Session"
3. Or press `⌥⌃Space` anywhere

### Stopping a Session

1. Click "Stop Session" in the menu bar
2. Optionally provide an interruption reason
3. Or press `⌥⌃Space` again

### Viewing Dashboard

Click the chart icon in the menu bar popover to open the full dashboard with:
- Daily productivity metrics
- Weekly performance chart
- Task list
- Session history

## Productivity Formula

The app calculates productivity using this formula:

```
FocusedTime = sum of all session durations
Interruptions = number of interrupted sessions
Penalty = Interruptions × 15 minutes

Productivity = FocusedTime / (FocusedTime + Penalty)
Productivity % = Productivity × 100
```

This formula emphasizes that interruptions are costly — each one adds a 15-minute penalty to your effective time.

## Configuration

### Keyboard Shortcut

The default shortcut is `⌥⌃Space`. To customize:
1. Open System Settings → Keyboard → Keyboard Shortcuts
2. Find "ProductivityTracker" under App Shortcuts
3. Set your preferred key combination

### Settings

Access app settings through the Settings model:
- Penalty per interruption (default: 15 minutes)
- Enable/disable notifications
- Show time in menu bar

## Distribution

### Development (Unsigned)

```bash
swift build -c release
# App is ready at ./.build/release/ProductivityTracker
```

Users will need to right-click → Open to bypass Gatekeeper.

### Production (Notarized)

Requires Apple Developer Program ($99/year):

1. Sign with Developer ID certificate
2. Notarize with `notarytool`
3. Distribute as .dmg or .zip

### Mac App Store

Requires sandboxing and additional entitlements. See Apple's [App Store submission guidelines](https://developer.apple.com/app-store/submissions/).

## Development

### Running Tests

```bash
swift test
```

### Adding Dependencies

Edit `Package.swift` and add to the `dependencies` array:

```swift
dependencies: [
    .package(url: "https://github.com/username/package", from: "1.0.0")
]
```

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for development)
- Swift 5.9+

## Credits

Productivity formula based on the article: **"The Math of Why You Can't Focus at Work"**

## License

Copyright © 2025. All rights reserved.

## Support

For issues, questions, or contributions, please refer to the specification document at `PRODUCTIVITY_SPEC.md`.
