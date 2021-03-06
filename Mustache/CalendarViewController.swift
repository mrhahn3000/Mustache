//
//  CalendarViewController.swift
//  Mustache
//
//  Created by Alex Berger on 6/19/15.
//  Copyright (c) 2015 aberger.me. All rights reserved.
//

import Cocoa
import EventKit


class CalendarViewController: NSViewController {
    
    @IBOutlet weak var sourceCalendarLabel: NSTextField!
    @IBOutlet weak var destinationCalendarLabel: NSTextField!
    @IBOutlet weak var sourceCalendarPopUp: NSPopUpButton!
    @IBOutlet weak var destinationCalendarPopUp: NSPopUpButton!
    @IBOutlet weak var deleteEventsButton: NSButton!
    @IBOutlet weak var copyEventsButton: NSButton!
    
    
    let startDate = NSDate()
    let endDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.CalendarUnitYear, value: 1, toDate: NSDate(), options: NSCalendarOptions(0))
    var calendarDictionary = [String : String]()
    let eventStore = EKEventStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: { (granted: Bool, error: NSError!) -> Void in
            if granted {
                var calendars = self.readAllLocalCalendars()
                for calendar in calendars {
                    self.calendarDictionary[calendar.title] = calendar.calendarIdentifier
                }
                self.sourceCalendarPopUp.removeAllItems()
                self.sourceCalendarPopUp.addItemsWithTitles(self.calendarDictionary.keys.array)
                self.destinationCalendarPopUp.removeAllItems()
                self.destinationCalendarPopUp.addItemsWithTitles(self.calendarDictionary.keys.array)
                if self.destinationCalendarPopUp.itemArray.count > 0 {
                    self.destinationCalendarPopUp.selectItemAtIndex(1)
                }
            }
        })
    }
    
    private func readAllLocalCalendars() -> [EKCalendar] {
        if let calendars = eventStore.calendarsForEntityType(EKEntityTypeEvent) as? [EKCalendar] {
            return calendars
        }
        
        return []
    }
    
    private func deleteAllFutureEvents(calendarIdentifier: String) {
        let calendar = eventStore.calendarWithIdentifier(calendarIdentifier)
        
        let eventsPredicate = eventStore.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: [calendar])
        let eventList = eventStore.eventsMatchingPredicate(eventsPredicate)
        
        for event in eventList {
            if let event = event as? EKEvent {
                var error: NSError?
                eventStore.removeEvent(event, span: EKSpanThisEvent, commit: true, error: &error)
                if error != nil {
                    println(error?.description)
                }
            }
        }
    }
    
    private func copyAllFutureEvents(fromCalendar: String, toCalendar: String) {
        let sourceCalendar = eventStore.calendarWithIdentifier(fromCalendar)
        let destinationCalendar = eventStore.calendarWithIdentifier(toCalendar)
        
        let eventsPredicate = eventStore.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: [sourceCalendar])
        let eventList = eventStore.eventsMatchingPredicate(eventsPredicate)
        
        for event in eventList {
            if let event = event as? EKEvent {
                var newEvent = EKEvent(eventStore: eventStore)
                newEvent.title = event.title
                newEvent.startDate = event.startDate
                newEvent.endDate = event.endDate
                newEvent.allDay = event.allDay
                newEvent.recurrenceRules = event.recurrenceRules
                newEvent.availability = event.availability
                newEvent.timeZone = event.timeZone
                newEvent.notes = event.notes
                newEvent.location = event.location
                // read-only properties:
                //                newEvent.occurrenceDate = event.occurrenceDate
                //                newEvent.status = event.status
                //                newEvent.organizer = event.organizer
                //                newEvent.attendees = event.attendees
                
                newEvent.calendar = destinationCalendar
                
                var error: NSError?
                eventStore.saveEvent(newEvent, span: EKSpanThisEvent, commit: true, error: &error)
            }
        }
    }
    
    @IBAction func deleteDestinationCalendarEvents(sender: AnyObject) {
        var alert = NSAlert()
        alert.delegate = self
        alert.informativeText = "Are you sure you want to delete all events from the destination calendars?"
        alert.messageText = "This action can not be reverted."
        alert.showsHelp = false
        alert.addButtonWithTitle("I understand")
        alert.addButtonWithTitle("Cancel")
        let button = alert.runModal()
        if button == NSAlertFirstButtonReturn {
            if let selectedCalendar = destinationCalendarPopUp.selectedItem?.title,
                let calendarIdentifier = self.calendarDictionary[selectedCalendar] {
                    deleteAllFutureEvents(calendarIdentifier)
            }
        }
//        else if button == NSAlertSecondButtonReturn {
//            println("cancel, do nothing")
//        }
    }
    
    @IBAction func copyEventsToSourceCalendar(sender: AnyObject) {
        if let selectedSourceCalendar = sourceCalendarPopUp.selectedItem?.title,
            let sourceCalendarIdentifier = self.calendarDictionary[selectedSourceCalendar],
            let selectedDestinationCalendar = destinationCalendarPopUp.selectedItem?.title,
            let destinationCalendarIdentifier = self.calendarDictionary[selectedDestinationCalendar] {
                copyAllFutureEvents(sourceCalendarIdentifier, toCalendar: destinationCalendarIdentifier)
        }
    }
}

extension CalendarViewController: NSAlertDelegate {
    
}
