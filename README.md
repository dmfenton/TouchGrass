# PosturePal

A native macOS menu bar app that helps you maintain good posture with gentle, periodic reminders.

<img width="286" alt="PosturePal Menu" src="https://github.com/user-attachments/assets/placeholder-menu.png">
<img width="380" alt="PosturePal Reminder" src="https://github.com/user-attachments/assets/placeholder-reminder.png">

## Features

- 🕐 **Smart Scheduling** - Fixed-interval reminders synced to clock time (e.g., every 45 minutes at :00, :45)
- ⏱️ **Live Countdown** - See exactly when your next reminder will appear
- 🪑 **Posture Reset Steps** - Three core steps for proper posture alignment
- 💡 **Bonus Tips** - Random ergonomic tips with each reminder
- ⏸️ **Flexible Control** - Pause, resume, or snooze reminders as needed
- 🎨 **Native Design** - Clean UI that matches macOS aesthetics
- 🔕 **Non-Intrusive** - Gentle reminders that don't interrupt your flow

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (to build from source)

## Installation

### Option 1: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/posture.git
cd posture
```

2. Open in Xcode:
```bash
open PosturePal.xcodeproj
```

3. Build and run (⌘R)

### Option 2: Command Line Build

```bash
xcodebuild -project PosturePal.xcodeproj -scheme PosturePal -configuration Release build SYMROOT=build
open build/Release/PosturePal.app
```

### Option 3: Download Release

Download the latest `.app` from the [Releases](https://github.com/yourusername/posture/releases) page.

## Usage

1. **Launch** - PosturePal appears as a walking figure icon in your menu bar
2. **Check Timer** - Click the icon to see countdown to next reminder
3. **Adjust Interval** - Use the slider to set reminder frequency (15-120 minutes)
4. **Respond to Reminders** - When reminded:
   - ✅ **Done** - Complete the posture reset
   - ⏰ **Snooze** - Delay 10 or 20 minutes
   - ⏭️ **Skip** - Skip this reminder

## Start at Login

To have PosturePal start automatically:

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** under "Open at Login"
3. Navigate to and select `PosturePal.app`

## Posture Reset Steps

Every reminder includes three core steps:

1. 🪑 **Sit back in your chair, hips all the way back**
2. 🧍 **Ears over shoulders, gentle chin tuck**
3. 🎈 **Drop your shoulders, let the base of your skull soften**

Plus a rotating selection of bonus tips for stretching and eye care.

## Customization

- **Interval**: Adjustable from 15 to 120 minutes
- **Messages**: Edit `Messages.swift` to customize reminder text
- **Timing**: Reminders align to clock intervals for predictability

## Development

Built with:
- SwiftUI for modern macOS UI
- Combine for reactive state management
- No external dependencies

### Project Structure

```
├── PosturePalApp.swift          # Main app and menu bar UI
├── ReminderManager.swift        # Timer and scheduling logic
├── ReminderWindow.swift         # Reminder popup view
├── ReminderWindowController.swift # Window management
├── Messages.swift               # Reminder messages and tips
└── Info.plist                   # App configuration
```

## Privacy

PosturePal is completely offline and private:
- No network connections
- No data collection
- No analytics
- All preferences stored locally

## Contributing

Pull requests welcome! Please:
1. Keep the UI clean and native
2. Test on multiple macOS versions
3. Follow existing code style

## License

MIT License - see LICENSE file for details

## Acknowledgments

Created to combat the "tech neck" epidemic, one gentle reminder at a time.

---

*Built with Swift and SwiftUI for macOS*