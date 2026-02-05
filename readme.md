# icalBuddy (EventKit Fork)

A command-line utility for macOS that displays events and tasks from Calendar and Reminders apps.

**This fork migrates from the deprecated CalendarStore framework to EventKit**, fixing the "No calendars" issue on modern macOS (10.14+).

## Why This Fork?

The original icalBuddy uses Apple's CalendarStore framework, which was deprecated in macOS 10.8 (2012). On modern macOS, CalendarStore doesn't integrate with the privacy system (TCC - Transparency, Consent, and Control), causing icalBuddy to report "No calendars" even when calendars exist.

This fork uses EventKit, which:
- Works with modern macOS privacy controls (10.14+)
- Triggers proper permission prompts
- Supports both Calendar and Reminders access
- Is actively maintained by Apple

## Installation

### From Source

```bash
git clone https://github.com/mgunville/icalBuddy64.git
cd icalBuddy64
make clean && make
sudo cp icalBuddy /usr/local/bin/
# Or for user-local install:
cp icalBuddy ~/bin/
```

### First Run

On first run, icalBuddy will request calendar access. Click "OK" when prompted, or grant access manually in:
**System Settings → Privacy & Security → Calendars**

For tasks/reminders, also grant access in:
**System Settings → Privacy & Security → Reminders**

## Usage

```bash
# List all calendars
icalBuddy calendars

# Today's events
icalBuddy eventsToday

# Events for next 7 days
icalBuddy eventsToday+7

# Events from a specific calendar
icalBuddy -ic "Work" eventsToday

# Uncompleted tasks
icalBuddy uncompletedTasks

# Formatted output (e.g., for Obsidian Templater)
icalBuddy -npn -nc -ps "/ - /" -iep "datetime,title" \
          -po "datetime,title" -b "###### " -tf "%H%M" \
          -ic "Work" eventsToday
```

See the [man page](http://hasseg.org/icalBuddy/man.html) for full documentation.

## Troubleshooting

### "No calendars" Error

1. Check System Settings → Privacy & Security → Calendars
2. Ensure Terminal (or your app) has access enabled
3. If needed, reset and retry:
   ```bash
   tccutil reset Calendar
   ./icalBuddy calendars  # Will prompt again
   ```

### "Reminders access denied"

Grant access in System Settings → Privacy & Security → Reminders

## Fork Lineage

This project has the following history:

| Version | Author | Repository |
|---------|--------|------------|
| Original | Ali Rantakari | [hasseg.org/icalBuddy](http://hasseg.org/icalBuddy) |
| 64-bit fork | dkaluta | [github.com/dkaluta/icalBuddy64](https://github.com/dkaluta/icalBuddy64) |
| EventKit fork | mgunville | [github.com/mgunville/icalBuddy64](https://github.com/mgunville/icalBuddy64) |

## Changes from Upstream

- **Framework**: CalendarStore → EventKit
- **Permissions**: Proper TCC integration with permission prompts
- **Compatibility**: macOS 10.13+ (colors require 10.15+)
- **New file**: `EventKitStore.m` for permission handling

All original functionality is preserved. The codebase maintains `#ifdef USE_MOCKED_CALENDARSTORE` guards for test compatibility.

## Building

Requirements:
- macOS 10.13+
- Xcode Command Line Tools

```bash
make clean && make
```

## License

The MIT License

Copyright (c) 2008-2012 Ali Rantakari
64-bit updates (c) dkaluta
EventKit migration (c) 2025 mgunville

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
