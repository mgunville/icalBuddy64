# icalBuddy64 - EventKit Migration

A modernized fork of icalBuddy that uses Apple's EventKit framework instead of the deprecated CalendarStore framework.

## Why This Fork?

The original icalBuddy uses CalendarStore, which was deprecated in macOS 10.8 (2012). On modern macOS (10.14+), CalendarStore doesn't integrate with the privacy system (TCC), causing icalBuddy to report "No calendars" even when calendars exist and permissions are granted.

This fork migrates to EventKit, which:
- Works with modern macOS privacy controls
- Triggers proper permission prompts
- Supports both Calendar and Reminders access
- Is actively maintained by Apple

## Repository

- **Fork:** https://github.com/mgunville/icalBuddy64
- **Upstream:** https://github.com/dkaluta/icalBuddy64
- **Branch:** `eventkit-migration`

## Quick Start

```bash
# Clone the fork
git clone https://github.com/mgunville/icalBuddy64.git
cd icalBuddy64
git checkout eventkit-migration

# Build
make clean && make

# Test (will prompt for calendar access on first run)
./icalBuddy calendars
./icalBuddy eventsToday

# Install
sudo cp icalBuddy /usr/local/bin/
# OR
cp icalBuddy ~/bin/
```

## Migration Status

| Component | Status |
|-----------|--------|
| Core framework switch | Done |
| Calendar queries | Done |
| Event queries | Done |
| Task/Reminder queries | Done |
| Permission handling | Done |
| Pretty print output | In Progress |
| Calendar colors | In Progress |
| Testing | Pending |
| Documentation | Pending |

## Documentation

- [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) - Detailed migration plan and timeline
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture and module descriptions

## Key Changes from Upstream

### 1. Framework Change
```diff
- #import <CalendarStore/CalendarStore.h>
+ #import <EventKit/EventKit.h>
```

### 2. Permission Handling
New `EventKitStore.m` handles permission requests synchronously:
```objc
BOOL initEventStore(void);      // Request calendar access
BOOL initReminderAccess(void);  // Request reminders access
```

### 3. API Updates
| Old (CalendarStore) | New (EventKit) |
|---------------------|----------------|
| `[CalCalendarStore defaultCalendarStore]` | `eventStore` (global) |
| `[cal uid]` | `[cal calendarIdentifier]` |
| `[task dueDate]` | `[reminder dueDateComponents]` |
| Sync task queries | Async with semaphore |

## Usage Examples

```bash
# List all calendars
icalBuddy calendars

# Today's events
icalBuddy eventsToday

# Events for next 7 days
icalBuddy eventsToday+7

# Events from specific calendar
icalBuddy -ic "Work" eventsToday

# Formatted output (for Obsidian Templater)
icalBuddy -npn -nc -ps "/ - /" -iep "datetime,title" \
          -po "datetime,title" -b "###### " -tf "%H%M" \
          -ic "Work" eventsToday

# Uncompleted tasks
icalBuddy uncompletedTasks

# Tasks due before a date
icalBuddy tasksDueBefore:today+7
```

## Troubleshooting

### "No calendars" Error

1. **Check System Settings:**
   - System Settings → Privacy & Security → Calendars
   - Ensure Terminal (or your app) has access

2. **Reset permissions and retry:**
   ```bash
   tccutil reset Calendar
   ./icalBuddy calendars  # Will prompt again
   ```

3. **Check calendar exists:**
   ```bash
   # Via AppleScript (bypasses TCC issues)
   osascript -e 'tell application "Calendar" to get name of calendars'
   ```

### Permission Not Prompting

The permission prompt only appears once. If denied:
1. Open System Settings → Privacy & Security → Calendars
2. Manually add Terminal/iTerm/your app
3. Toggle access on

## Contributing

1. Fork the repository
2. Create a feature branch from `eventkit-migration`
3. Make changes with appropriate `#ifdef USE_MOCKED_CALENDARSTORE` guards
4. Test with `make && ./icalBuddy eventsToday`
5. Submit a pull request

## License

MIT License - see original icalBuddy license.

## Credits

- **Original Author:** Ali Rantakari (http://hasseg.org/icalBuddy)
- **64-bit Fork:** dkaluta
- **EventKit Migration:** mgunville
