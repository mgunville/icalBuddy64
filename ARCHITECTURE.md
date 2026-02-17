# icalBuddy Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         icalBuddy CLI                            │
├─────────────────────────────────────────────────────────────────┤
│  main()                                                          │
│  ├── Argument Parsing (icalBuddyArgs.m)                         │
│  ├── Config Loading                                              │
│  ├── Localization (icalBuddyL10N.m)                             │
│  └── Command Dispatch                                            │
│       ├── calendars → printAllCalendars()                       │
│       ├── eventsToday/eventsNow/eventsFrom → getEvents()        │
│       ├── uncompletedTasks/tasksDueBefore → getTasks()          │
│       └── editConfig → openConfigFileInEditor()                 │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer (icalBuddyFunctions.m)                              │
│  ├── getCalendars() ─────────┐                                  │
│  ├── getEvents()             │                                  │
│  ├── getTasks()              ├──→ EventKitStore.m               │
│  ├── sortCalItems()          │    ├── EKEventStore (singleton)  │
│  └── putItemsUnderSections() │    ├── initEventStore()          │
│                              │    └── initReminderAccess()      │
├──────────────────────────────┴──────────────────────────────────┤
│  Output Layer                                                    │
│  ├── icalBuddyPrettyPrint.m (formatting, output buffer)         │
│  ├── icalBuddyFormatting.m (ANSI colors, styles)                │
│  └── ANSIEscapeHelper.m (terminal escape codes)                 │
├─────────────────────────────────────────────────────────────────┤
│  Utilities                                                       │
│  ├── HGDateFunctions.m (date manipulation)                      │
│  ├── HGCLIUtils.m (CLI helpers)                                 │
│  └── HGUtils.m (general utilities)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      macOS Frameworks                            │
├─────────────────────────────────────────────────────────────────┤
│  EventKit.framework (NEW)                                        │
│  ├── EKEventStore - calendar database access                    │
│  ├── EKCalendar - calendar containers                           │
│  ├── EKEvent - calendar events                                  │
│  └── EKReminder - tasks/reminders                               │
├─────────────────────────────────────────────────────────────────┤
│  Other Frameworks                                                │
│  ├── Cocoa.framework - Foundation + AppKit                      │
│  ├── AddressBook.framework - contact lookup for attendees       │
│  └── AppKit.framework - NSWorkspace, NSColor                    │
└─────────────────────────────────────────────────────────────────┘
```

## Module Descriptions

### Core Modules

#### icalBuddy.m
**Purpose:** Main entry point and command dispatcher
**Key Functions:**
- `main()` - argument processing, command routing
- `versionNumberStr()` - version string formatting

#### icalBuddyFunctions.m
**Purpose:** Calendar data access and manipulation
**Key Functions:**
- `getCalendars(opts)` - retrieve filtered calendar list
- `getEvents(opts, calendars)` - query events by date range
- `getTasks(opts, calendars)` - query incomplete reminders
- `getCalItems(opts)` - unified entry point for events/tasks
- `sortCalItems(opts, calItems)` - sort by date/priority
- `putItemsUnderSections(opts, calItems)` - group for output
- `filterCalendars(cals, opts)` - apply include/exclude filters

#### EventKitStore.m (NEW)
**Purpose:** EventKit initialization and permission handling
**Key Functions:**
- `initEventStore()` - create EKEventStore, request calendar access
- `initReminderAccess()` - request reminders access
**Global Variables:**
- `EKEventStore *eventStore` - singleton store instance

### Output Modules

#### icalBuddyPrettyPrint.m
**Purpose:** Format and buffer output for display
**Key Functions:**
- `initPrettyPrint(buffer, opts)` - initialize output system
- `printCalEvent(event, opts, now)` - format single event
- `printCalTask(task, opts)` - format single task
- `printItemSections(sections, opts)` - format grouped items
- `dateStr(date, printOption)` - format dates with relative names

#### icalBuddyFormatting.m
**Purpose:** ANSI terminal formatting and colors
**Key Functions:**
- `initFormatting(configDict, separators)` - load formatting config
- `ansiEscapedStringWithAttributedString(str)` - convert to ANSI
- Color and style application functions

### Configuration Modules

#### icalBuddyArgs.m
**Purpose:** Command-line argument parsing
**Key Functions:**
- `readProgramArgs(opts, prettyPrintOpts, argc, argv)`
- `readArgsFromConfigFile(opts, prettyPrintOpts, path, configDict)`
- `processAppOptions(opts, prettyPrintOpts, separators)`

#### icalBuddyL10N.m
**Purpose:** Localization support
**Key Functions:**
- `initL10N(filePath)` - load localization file
- `localizedStr(key)` - get localized string
- `localizedPriorityTitle(priority)` - priority names

### Utility Modules

#### HGDateFunctions.m
- `dateForStartOfDay(date)`, `dateForEndOfDay(date)`
- `dateByAddingDays(date, days)`
- `getDayDiff(date1, date2)`
- `datesRepresentSameDay(date1, date2)`
- `dateFromUserInput(str, description, isEndDate)`

#### HGCLIUtils.m
- `Printf(format, ...)`, `PrintfErr(format, ...)`
- `DebugPrintf(format, ...)`
- `flushOutputBuffer(buffer, opts, keywords)`

## Data Structures

### AppOptions
```objc
typedef struct {
    // Output type flags
    BOOL output_is_eventsToday;
    BOOL output_is_eventsNow;
    BOOL output_is_eventsFromTo;
    BOOL output_is_uncompletedTasks;
    BOOL output_is_undatedUncompletedTasks;
    BOOL output_is_tasksDueBefore;

    // Filter options
    NSArray *includeCals;
    NSArray *excludeCals;
    NSArray *includeCalTypes;
    NSArray *excludeCalTypes;

    // Display options
    BOOL noCalendarNames;
    BOOL noPropNames;
    BOOL separateByCalendar;
    BOOL separateByDate;
    BOOL separateByPriority;
    BOOL excludeAllDayEvents;

    // Date range (computed)
    NSDate *startDate;
    NSDate *endDate;
    NSDate *dueBeforeDate;

    // ... more options
} AppOptions;
```

### PrettyPrintOptions
```objc
typedef struct {
    NSString *prefixStrBullet;
    NSString *prefixStrBulletAlert;
    NSString *sectionSeparatorStr;
    NSString *timeFormatStr;
    NSString *dateFormatStr;

    BOOL displayRelativeDates;
    BOOL excludeEndDates;
    BOOL useCalendarColorsForTitles;
    BOOL showUIDs;

    NSUInteger maxNumPrintedItems;
    NSArray *propertyOrder;
    // ... more options
} PrettyPrintOptions;
```

### CalItemPrintOption
```objc
typedef struct {
    BOOL singleDay;
    BOOL calendarAgnostic;
    BOOL priorityAgnostic;
    BOOL withoutPropNames;
    BOOL calendarColorsForSectionTitles;
    NSUInteger maxNumPrintedAttendees;
    NSUInteger maxNumNoteCharacters;
} CalItemPrintOption;
```

### PrintSection
```objc
typedef struct {
    NSString *title;
    NSArray *items;
    NSDate *contextDay;  // For date-based sections
} PrintSection;
```

## EventKit Migration Details

### Permission Flow

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
│ User runs    │────▶│ initEventStore()│────▶│ Check macOS      │
│ icalBuddy    │     │                 │     │ version          │
└──────────────┘     └─────────────────┘     └────────┬─────────┘
                                                      │
                     ┌────────────────────────────────┼────────────────────────────────┐
                     │                                │                                │
                     ▼                                ▼                                ▼
            ┌────────────────┐             ┌────────────────┐             ┌────────────────┐
            │ macOS 14+      │             │ macOS 10.14-13 │             │ macOS < 10.14  │
            │ requestFull    │             │ requestAccess  │             │ (implicit      │
            │ AccessToEvents │             │ ToEntityType   │             │  access)       │
            └───────┬────────┘             └───────┬────────┘             └───────┬────────┘
                    │                              │                              │
                    ▼                              ▼                              ▼
            ┌────────────────────────────────────────────────────────────────────────────┐
            │                    Wait on semaphore (sync)                                 │
            └────────────────────────────────────────────────────────────────────────────┘
                                                   │
                         ┌─────────────────────────┴─────────────────────────┐
                         │                                                   │
                         ▼                                                   ▼
                ┌────────────────┐                                  ┌────────────────┐
                │ Access Granted │                                  │ Access Denied  │
                │ Continue...    │                                  │ Print error    │
                └────────────────┘                                  │ Exit           │
                                                                    └────────────────┘
```

### Calendar Query Flow

```
getCalendars(opts)
       │
       ▼
initEventStore() ──────▶ EKEventStore created
       │
       ▼
calendarsForEntityType:EKEntityTypeEvent
       │
       ▼
filterCalendars()
  ├── filterCalendarsByType()      [by EKCalendarType]
  └── filterCalendarsByNameOrUID() [by title or calendarIdentifier]
       │
       ▼
Return filtered NSArray<EKCalendar>
```

### Event Query Flow

```
getEvents(opts, calendars)
       │
       ▼
Calculate date range (startDate, endDate)
       │
       ▼
predicateForEventsWithStartDate:endDate:calendars:
       │
       ▼
eventsMatchingPredicate:
       │
       ▼
Filter all-day events (if excludeAllDayEvents)
       │
       ▼
Return NSArray<EKEvent>
```

### Reminder Query Flow

```
getTasks(opts, calendars)
       │
       ▼
initReminderAccess() ──────▶ Request reminders permission
       │
       ▼
calendarsForEntityType:EKEntityTypeReminder
       │
       ▼
Filter to match requested calendar titles
       │
       ▼
predicateForIncompleteRemindersWithDueDateStarting:ending:calendars:
       │
       ▼
fetchRemindersMatchingPredicate:completion: (async)
       │
       ▼
Wait on semaphore (sync)
       │
       ▼
Filter undated (if output_is_undatedUncompletedTasks)
       │
       ▼
Return NSArray<EKReminder>
```

## Build System

### Makefile Targets

| Target | Description |
|--------|-------------|
| `all` / `icalBuddy` | Build main binary |
| `testIcalBuddy` | Build with mock calendar store |
| `testRunner` | Build unit test runner |
| `clean` | Remove build artifacts |
| `docs` | Generate man pages |
| `package` | Create release zip |

### Compiler Flags

```makefile
COMPILER=clang
CC_WARN_OPTS=-Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations
FRAMEWORKS=-framework Cocoa -framework EventKit -framework AppKit -framework AddressBook
MIN_VERSION=-mmacosx-version-min=10.13
```

## Configuration

### Config File Location
`~/.icalBuddyConfig.plist`

### Config Structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>formatting</key>
    <dict>
        <key>titleValue</key>
        <string>bold</string>
        <key>datetimeValue</key>
        <string>yellow</string>
    </dict>
    <key>formattedKeywords</key>
    <dict>
        <key>today</key>
        <string>green,bold</string>
    </dict>
</dict>
</plist>
```

## Error Handling

| Error | Cause | User Message |
|-------|-------|--------------|
| No calendars | Permission denied or no calendars configured | "error: No calendars." |
| Calendar access denied | User denied permission in System Settings | "error: Calendar access denied. Please grant calendar access in System Settings > Privacy & Security > Calendars." |
| Reminders access denied | User denied reminders permission | "error: Reminders access denied." |
| Invalid date format | User provided unparseable date string | Date format help printed |
