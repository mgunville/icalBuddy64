// icalBuddy calendar store import
//
// http://hasseg.org/icalBuddy
//

/*
The MIT License

Copyright (c) 2008-2012 Ali Rantakari

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

#ifdef USE_MOCKED_CALENDARSTORE
    #import "calendarStoreMock/MockCalCalendarStore.h"
    #define CALENDAR_STORE  MockCalCalendarStore
    // Keep original CalendarStore types for mock
#else
    // Use modern EventKit framework instead of deprecated CalendarStore
    #import <EventKit/EventKit.h>

    // Global event store - initialized once with permission request
    extern EKEventStore *eventStore;

    // Initialize the event store and request calendar access
    // Returns YES if access granted, NO otherwise
    BOOL initEventStore(void);

    // Compatibility typedefs for easier migration
    typedef EKCalendar CalCalendar;
    typedef EKEvent CalEvent;
    typedef EKReminder CalTask;
    typedef EKCalendarItem CalCalendarItem;

    // Priority constants - map CalendarStore priorities to EventKit
    // CalendarStore: CalPriorityNone=0, CalPriorityHigh=1, CalPriorityMedium=5, CalPriorityLow=9
    // EventKit uses same values for EKReminder priority property
    typedef NS_ENUM(NSUInteger, CalPriority) {
        CalPriorityNone = 0,
        CalPriorityHigh = 1,
        CalPriorityMedium = 5,
        CalPriorityLow = 9
    };

    // Calendar type constants for filtering
    #define CalCalendarTypeBirthday     @"Birthday"
    #define CalCalendarTypeCalDAV       @"CalDAV"
    #define CalCalendarTypeExchange     @"Exchange"
    #define CalCalendarTypeIMAP         @"IMAP"
    #define CalCalendarTypeLocal        @"Local"
    #define CalCalendarTypeSubscription @"Subscription"
#endif


