# icalBuddy EventKit Migration - TODO

## Remaining Work

### High Priority (Required for MVP)

- [x] **icalBuddyPrettyPrint.m** - Update for EventKit types
  - [x] `printCalEvent()` - EKEvent property access
  - [x] `printCalTask()` - EKReminder property access (dueDateComponents → NSDate)
  - [x] Calendar color access via CGColor instead of NSColor

- [x] **icalBuddyFormatting.m** - Update color handling
  - [x] Convert CGColorRef to NSColor for ANSI color mapping
  - [x] Update `closestSGRCodeForColor:` calls

- [x] **Build & Test**
  - [x] Successful compilation with no errors
  - [x] Test `calendars` command
  - [x] Test `eventsToday` command
  - [ ] Test `uncompletedTasks` command (requires Reminders permission)
  - [x] Test with calendar filters (-ic, -ec)

### Medium Priority (Full Compatibility)

- [x] **icalBuddyPrettyPrint.h** - No changes needed (uses typedefs)

- [ ] **Testing**
  - [x] Test `eventsToday+N` (multi-day) - works
  - [ ] Test `eventsFrom:X to:Y` (date range)
  - [ ] Test `eventsNow` (current events)
  - [ ] Test `tasksDueBefore:DATE`
  - [ ] Test `undatedUncompletedTasks`
  - [x] Test `-sc` (separate by calendar) - works
  - [ ] Test `-sd` (separate by date)
  - [ ] Test `-sp` (separate by priority)
  - [x] Test formatting options (-tf, -df, -b, -ps, etc.) - works

- [ ] **Edge Cases**
  - [x] All-day events
  - [ ] Multi-day events
  - [ ] Recurring events
  - [ ] Events with no end time
  - [ ] Tasks with no due date
  - [ ] Tasks with priority

### Low Priority (Polish)

- [ ] **Documentation**
  - [ ] Update man page (icalBuddy.pod)
  - [ ] Update FAQ
  - [ ] Add EventKit-specific notes

- [ ] **Code Quality**
  - [ ] Remove debug logging
  - [ ] Clean up #ifdef blocks where possible
  - [ ] Add comments for EventKit-specific code

- [ ] **Release**
  - [ ] Bump version number
  - [ ] Create GitHub release
  - [ ] Update upstream README with fork info

## Files Changed Summary

```
Modified:
  calendarStoreImport.h     - EventKit imports and typedefs
  Makefile                  - EventKit framework, compiler flags
  icalBuddyFunctions.m      - Core calendar/event/task queries
  icalBuddy.m               - Type casts in print loop
  icalBuddyPrettyPrint.m    - Output formatting (EventKit types)
  icalBuddyFormatting.m     - ANSI colors (CGColor handling)
  icalBuddyFormatting.h     - Import header update

New:
  EventKitStore.m           - EKEventStore singleton, permissions
```

## Current Status

**BUILD: PASSING** ✓
**CALENDARS: WORKING** ✓
**EVENTS: WORKING** ✓
**REMINDERS: Requires permission grant**

## Notes

- Keep `#ifdef USE_MOCKED_CALENDARSTORE` guards for test compatibility
- EventKit reminders API is async - using semaphores for sync behavior
- Permission requests happen on first access, not app launch
- CGColor API requires macOS 10.15+ (fallback to nil for older versions)
- EventKit uses `URL` property (capitalized), not `url`
- EventKit uses `calendarItemIdentifier` instead of `uid`

## Installation

Binary installed to: `~/bin/icalBuddy`
Symlink at: `/usr/local/bin/icalBuddy` → `~/bin/icalBuddy`

## Repository

- Fork: https://github.com/mgunville/icalBuddy64
- Branch: `eventkit-migration`
- Commit: 7d44235
