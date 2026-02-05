// icalBuddy EventKit Store
//
// http://hasseg.org/icalBuddy
//

/*
The MIT License

Copyright (c) 2008-2012 Ali Rantakari
Copyright (c) 2024 Community Contributors

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
*/

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

// Global event store instance
EKEventStore *eventStore = nil;

BOOL initEventStore(void)
{
    if (eventStore != nil)
        return YES;

    eventStore = [[EKEventStore alloc] init];

    // Request access synchronously using a semaphore
    __block BOOL accessGranted = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    // Check macOS version for appropriate API
    if (@available(macOS 14.0, *)) {
        // macOS 14+ uses requestFullAccessToEventsWithCompletion
        [eventStore requestFullAccessToEventsWithCompletion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            if (error) {
                NSLog(@"Calendar access error: %@", error.localizedDescription);
            }
            dispatch_semaphore_signal(semaphore);
        }];
    } else if (@available(macOS 10.14, *)) {
        // macOS 10.14-13.x uses requestAccessToEntityType
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            if (error) {
                NSLog(@"Calendar access error: %@", error.localizedDescription);
            }
            dispatch_semaphore_signal(semaphore);
        }];
    } else {
        // Older macOS - access is implicit
        accessGranted = YES;
        dispatch_semaphore_signal(semaphore);
    }

    // Wait for completion (with timeout)
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

    if (!accessGranted) {
        fprintf(stderr, "error: Calendar access denied. Please grant calendar access in System Settings > Privacy & Security > Calendars.\n");
        return NO;
    }

    return YES;
}

// Request access to reminders (for tasks)
BOOL initReminderAccess(void)
{
    if (eventStore == nil) {
        if (!initEventStore())
            return NO;
    }

    __block BOOL accessGranted = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    if (@available(macOS 14.0, *)) {
        [eventStore requestFullAccessToRemindersWithCompletion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            if (error) {
                NSLog(@"Reminders access error: %@", error.localizedDescription);
            }
            dispatch_semaphore_signal(semaphore);
        }];
    } else if (@available(macOS 10.14, *)) {
        [eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            if (error) {
                NSLog(@"Reminders access error: %@", error.localizedDescription);
            }
            dispatch_semaphore_signal(semaphore);
        }];
    } else {
        accessGranted = YES;
        dispatch_semaphore_signal(semaphore);
    }

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

    return accessGranted;
}
