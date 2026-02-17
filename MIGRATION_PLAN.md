# icalBuddy EventKit Migration Plan

## Overview

This document details the migration of icalBuddy from the deprecated CalendarStore framework to the modern EventKit framework. This migration is necessary because CalendarStore was deprecated in macOS 10.8 and does not integrate with modern macOS privacy controls (TCC - Transparency, Consent, and Control).

**Repository:** https://github.com/mgunville/icalBuddy64 (forked from dkaluta/icalBuddy64)
**Branch:** `eventkit-migration`

## Problem Statement

### Current Issues
1. **Privacy Integration Failure**: CalendarStore doesn't trigger macOS privacy prompts, resulting in "No calendars" errors even when calendars exist
2. **Deprecated APIs**: CalendarStore has been deprecated since macOS 10.8 (2012)
3. **No Reminders Support**: Modern Reminders are managed through EventKit, not CalendarStore
4. **Future Compatibility**: CalendarStore may be removed entirely in future macOS versions

### Impact
- Users cannot use icalBuddy with modern macOS (10.14+) without workarounds
- Obsidian Templater plugin integration broken for calendar queries
- CLI automation scripts fail silently

## Solution Architecture

### Framework Migration Map

| CalendarStore | EventKit | Notes |
|--------------|----------|-------|
| `CalCalendarStore` | `EKEventStore` | Singleton with permission handling |
| `CalCalendar` | `EKCalendar` | Property differences (uid → calendarIdentifier) |
| `CalEvent` | `EKEvent` | Mostly compatible |
| `CalTask` | `EKReminder` | Significant API differences |
| `CalCalendarItem` | `EKCalendarItem` | Base class for events/reminders |
| `CalPriority` | `NSUInteger` | Same values (0, 1, 5, 9) |

### Key API Changes

#### Calendar Access
```objc
// OLD (CalendarStore)
[[CalCalendarStore defaultCalendarStore] calendars]

// NEW (EventKit)
[eventStore calendarsForEntityType:EKEntityTypeEvent]
```

#### Event Predicates
```objc
// OLD
[CalCalendarStore eventPredicateWithStartDate:endDate:calendars:]
[[CalCalendarStore defaultCalendarStore] eventsWithPredicate:]

// NEW
[eventStore predicateForEventsWithStartDate:endDate:calendars:]
[eventStore eventsMatchingPredicate:]
```

#### Task/Reminder Predicates
```objc
// OLD
[CalCalendarStore taskPredicateWithUncompletedTasks:]
[[CalCalendarStore defaultCalendarStore] tasksWithPredicate:]

// NEW (async!)
[eventStore predicateForIncompleteRemindersWithDueDateStarting:ending:calendars:]
[eventStore fetchRemindersMatchingPredicate:completion:]
```

#### Property Access
```objc
// Calendar UID
// OLD: [calendar uid]
// NEW: [calendar calendarIdentifier]

// Task Due Date
// OLD: [task dueDate]
// NEW: [[NSCalendar currentCalendar] dateFromComponents:[reminder dueDateComponents]]

// Task Completion
// OLD: [task isCompleted]
// NEW: [reminder isCompleted]
```

### Permission Handling

EventKit requires explicit permission requests. The migration adds:

```objc
// macOS 14+
[eventStore requestFullAccessToEventsWithCompletion:^(BOOL granted, NSError *error) { ... }];

// macOS 10.14-13.x
[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) { ... }];
```

Permissions are requested synchronously using dispatch semaphores to maintain CLI compatibility.

## File-by-File Migration Status

| File | Status | Changes Required |
|------|--------|------------------|
| `calendarStoreImport.h` | **DONE** | Add EventKit import, typedefs, extern declarations |
| `Makefile` | **DONE** | Replace CalendarStore with EventKit framework, fix flags |
| `EventKitStore.m` | **NEW** | Global EKEventStore, permission handling |
| `icalBuddyFunctions.m` | **DONE** | Core calendar/event/task queries |
| `icalBuddy.m` | **DONE** | Type casts in print loop |
| `icalBuddyPrettyPrint.m` | **TODO** | Calendar color access, task properties |
| `icalBuddyPrettyPrint.h` | **TODO** | Function signatures |
| `icalBuddyFormatting.m` | **TODO** | Calendar color for ANSI output |
| `icalBuddyFormatting.h` | **TODO** | Type updates if needed |

## Detailed Changes by File

### 1. calendarStoreImport.h
- Conditionally import EventKit vs CalendarStore based on `USE_MOCKED_CALENDARSTORE`
- Define compatibility typedefs (`CalCalendar` → `EKCalendar`, etc.)
- Declare global `eventStore` and `initEventStore()` function
- Define `CalPriority` enum matching CalendarStore values

### 2. EventKitStore.m (NEW)
- Global `EKEventStore *eventStore` instance
- `initEventStore()` - request calendar access synchronously
- `initReminderAccess()` - request reminders access for tasks
- Version-aware API selection (@available checks)

### 3. icalBuddyFunctions.m
- `getCalendars()` - use `calendarsForEntityType:`
- `getEvents()` - use `predicateForEventsWithStartDate:` and `eventsMatchingPredicate:`
- `getTasks()` - use `predicateForIncompleteRemindersWithDueDateStarting:` and async `fetchRemindersMatchingPredicate:`
- `filterCalendarsByNameOrUID()` - use `calendarIdentifier` instead of `uid`
- `filterCalendarsByType()` - use `EKCalendarType` enum values
- `prioritySort()` - handle `dueDateComponents` instead of `dueDate`
- `putItemsUnderSections()` - update for EKReminder's `dueDateComponents`

### 4. icalBuddy.m
- Update print loop to use `EKEvent`/`EKReminder` types

### 5. icalBuddyPrettyPrint.m (TODO)
- `printCalEvent()` - update for EKEvent properties
- `printCalTask()` - update for EKReminder properties (dueDateComponents, priority)
- Calendar color access via `[calendar CGColor]` instead of `[calendar color]`

### 6. icalBuddyFormatting.m (TODO)
- Update `closestSGRCodeForColor:` calls to use CGColor

## Testing Plan

### Unit Tests
1. Calendar listing with various filter options
2. Event queries (today, date range, now)
3. Task queries (uncompleted, due before, undated)
4. Priority sorting
5. Date-based sectioning

### Integration Tests
1. Basic command: `icalBuddy eventsToday`
2. Calendar filter: `icalBuddy -ic "Work" eventsToday`
3. Date range: `icalBuddy eventsFrom:today to:today+7`
4. Tasks: `icalBuddy uncompletedTasks`
5. Formatting options: `-tf`, `-df`, `-b`, `-nc`, etc.

### Manual Testing
1. First run permission prompt
2. Permission denied handling
3. Multiple calendar sources (iCloud, Exchange, Local)
4. Obsidian Templater integration

## Build Instructions

```bash
cd /tmp/icalBuddy64
git checkout eventkit-migration
make clean
make
./icalBuddy calendars  # Test calendar access
./icalBuddy eventsToday
```

## Installation

```bash
# After successful build
sudo cp icalBuddy /usr/local/bin/
# OR for user-local install
cp icalBuddy ~/bin/
```

## Rollback Strategy

The migration preserves the original CalendarStore code path via `#ifdef USE_MOCKED_CALENDARSTORE`. This allows:
1. Testing with mock calendar store
2. Easy comparison of old vs new behavior
3. Potential rollback if issues discovered

## Timeline

| Phase | Tasks | Status |
|-------|-------|--------|
| 1. Setup | Fork repo, create branch | DONE |
| 2. Core Migration | calendarStoreImport.h, EventKitStore.m, icalBuddyFunctions.m | DONE |
| 3. Main App | icalBuddy.m updates | DONE |
| 4. Pretty Print | icalBuddyPrettyPrint.m, icalBuddyFormatting.m | IN PROGRESS |
| 5. Testing | Build, test all commands | PENDING |
| 6. Documentation | Update README, man pages | PENDING |
| 7. Release | PR, merge, tag release | PENDING |

## References

- [EventKit Framework Reference](https://developer.apple.com/documentation/eventkit)
- [CalendarStore Framework (Deprecated)](https://developer.apple.com/documentation/calendarstore)
- [TCC Privacy Controls](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_calendars)
- [Original icalBuddy](http://hasseg.org/icalBuddy)
