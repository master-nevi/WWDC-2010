/*
     File: LoanEventScheduler.m
 Abstract: Serves as the funnel point for most of our calls to the EventKit API.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "LoanEventScheduler.h"
#import "Loan.h"
#import "Payment.h"

#import <EventKit/EventKit.h>

//a constant for the NSTimeInterval representing one day in seconds
static NSTimeInterval const oneDay = 86400;

@interface LoanEventScheduler (Internal)

//utilities for individual payments
- (NSString *)titleForPayment:(Payment *)payment;

//utilities for recurring payments
- (NSString *)titleForRecurringPaymentInLoan:(Loan *) loan;
- (EKRecurrenceFrequency)eventKitFrequencyForLoan:(Loan *)loan;
- (int)eventKitIntervalForLoan:(Loan *)loan;
@end

#pragma mark -
@implementation LoanEventScheduler
#pragma mark Initialization
- (id)init {
    if ((self = [super init])) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        addressBook = ABAddressBookCreate();
		eventStore = [[EKEventStore alloc] init];
    }
    return self;
}

-(void)dealloc {
	[eventStore release];
    CFRelease(addressBook);
    [numberFormatter release];
    [super dealloc];
}
#pragma mark -
#pragma mark EventKit Methods

- (void)scheduleAllEventsForPayments:(NSArray *)payments {    
    for (Payment * payment in payments) {
		EKEvent * newPaymentEvent = [EKEvent eventWithEventStore:eventStore];
		newPaymentEvent.calendar = eventStore.defaultCalendarForNewEvents;
        newPaymentEvent.title = [self titleForPayment:payment];
        newPaymentEvent.allDay = YES;
        newPaymentEvent.startDate = payment.date;
        newPaymentEvent.endDate = payment.date;
		
		EKAlarm * alarm = [EKAlarm alarmWithRelativeOffset:0];
		newPaymentEvent.alarms = [NSArray arrayWithObject:alarm];
		
		NSError * error = nil;
        BOOL saved = [eventStore saveEvent:newPaymentEvent span:EKSpanThisEvent error:&error];
		if (!saved && error) {
            NSLog(@"%@", [error localizedDescription]);
		} else {
            payment.eventID = newPaymentEvent.eventIdentifier;
        }
    }
}

- (void)deleteAllEventsForPayments:(NSArray *)payments {
    NSArray * eventIDs = [payments valueForKey:@"eventID"];
    NSSet * uniqueIdentifiers = [NSSet setWithArray:eventIDs];
    
    for (NSString * eventIdentifier in uniqueIdentifiers) {
        EKEvent * paymentEvent = [eventStore eventWithIdentifier:eventIdentifier];
        NSError * error = nil;
        BOOL saved = [eventStore removeEvent:paymentEvent span:EKSpanFutureEvents error:&error];
        if (!saved && error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

- (NSArray *)scheduledPaymentEventsUsingRecurrenceForLoan:(Loan *)loan {
    NSMutableArray * scheduledEvents = nil;

    EKEvent * newPaymentEvent = [EKEvent eventWithEventStore:eventStore];
	//set event attributes
    newPaymentEvent.calendar = eventStore.defaultCalendarForNewEvents;
    newPaymentEvent.title = [self titleForRecurringPaymentInLoan:loan];
    newPaymentEvent.allDay = YES;
    newPaymentEvent.startDate = [loan expectedDateForPaymentNumber:1];
    newPaymentEvent.endDate = newPaymentEvent.startDate;
	
	//use a relative alarm
	EKAlarm * alarm = [EKAlarm alarmWithRelativeOffset:0];
	newPaymentEvent.alarms = [NSArray arrayWithObject:alarm];
	
	//create the recurrence rule
    EKRecurrenceRule * recurrenceRule = [[EKRecurrenceRule alloc] 
										 initRecurrenceWithFrequency:[self eventKitFrequencyForLoan:loan]
										 interval:[self eventKitIntervalForLoan:loan]
										 end:nil];
	EKRecurrenceEnd * end = [EKRecurrenceEnd recurrenceEndWithEndDate:loan.endDate];
    recurrenceRule.recurrenceEnd = end;
    
    newPaymentEvent.recurrenceRule = recurrenceRule;
    [recurrenceRule release];
	
	//save the payment event
    NSError * error = nil;
    BOOL saved = [eventStore saveEvent:newPaymentEvent span:EKSpanThisEvent error:&error];
    if (!saved && error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        
        //find the recurrences and create the payment objects:
        
        //get events between start and end dates
        NSPredicate *searchPredicate = [eventStore predicateForEventsWithStartDate:loan.startDate 
																		   endDate:loan.endDate 
																		 calendars:[NSArray arrayWithObject:
																					eventStore.defaultCalendarForNewEvents]];
        scheduledEvents = [[[eventStore eventsMatchingPredicate:searchPredicate] mutableCopy] autorelease];
		
		//post filter to yield just our events
        NSPredicate *paymentEventPredicate = [NSPredicate predicateWithFormat:@"eventIdentifier == %@", newPaymentEvent.eventIdentifier];
        [scheduledEvents filterUsingPredicate:paymentEventPredicate];
        [scheduledEvents sortUsingSelector:@selector(compareStartDateWithEvent:)];
    }
    return scheduledEvents;
}

- (void)updateEvent:(EKEvent *)event withPayment:(Payment *)payment {
    NSString * title = [self titleForPayment:payment];
    
    event.title = title;
    event.startDate = payment.date;
    event.endDate = payment.date;
    
    NSError * error = nil;
    BOOL saved = [eventStore saveEvent:event span:EKSpanThisEvent error:&error];
    
    if (!saved && error) {
        NSLog(@"%@", [error localizedDescription]);
    } 
    else {
        //update the eventID in our Payment object.
        payment.eventID = event.eventIdentifier;
    }
}

- (EKEvent *)eventRecurrenceForPayment:(Payment *)payment {
    EKEvent * paymentEvent = nil;
    
    NSPredicate * searchPredicate = [eventStore predicateForEventsWithStartDate:payment.date 
																		endDate:[payment.date dateByAddingTimeInterval:oneDay] 
																	  calendars:[NSArray arrayWithObject:
																				 eventStore.defaultCalendarForNewEvents]];
	
    NSMutableArray *events = [[eventStore eventsMatchingPredicate:searchPredicate] mutableCopy];
    NSPredicate * paymentEventPredicate = [NSPredicate predicateWithFormat:@"eventIdentifier == %@", payment.eventID];
    [events filterUsingPredicate:paymentEventPredicate];
    
    if ([events count]) {
        paymentEvent = [events objectAtIndex:0];
    }
    [events release];
    
    return paymentEvent;
}

	
@end

#pragma mark -
@implementation  LoanEventScheduler (Internal) 

- (NSString *)titleForPayment:(Payment *)payment {
    NSString * format = @"Payment: %@ from %@";
    NSString * name = nil;
    NSString * amount = nil;
    
    //get the name from AddressBook
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [payment.loan.personID intValue]);
    if(person) {
        name = (NSString *)ABRecordCopyCompositeName(person);
    }
    
    //amount
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    amount = [numberFormatter stringFromNumber:payment.amount];
    
    NSString * title = [NSString stringWithFormat:format, amount, name];
    [name release];
    
    return title;
}

- (NSString *)titleForRecurringPaymentInLoan:(Loan *)loan {
    NSString * format = @"Payment: %@ from %@";
    NSString * name = nil;
    NSString * amount = nil;
    
    //get the name from AddressBook
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [loan.personID intValue]);
    if(person) {
        name = (NSString *)ABRecordCopyCompositeName(person);
    }
    
    //amount
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    amount = [loan paymentAmountForNumberOfPayments:[loan expectedNumberOfPayments]];
    
    NSString * title = [NSString stringWithFormat:format, amount, name];
    [name release];
    
    return title;
    
}

- (EKRecurrenceFrequency)eventKitFrequencyForLoan:(Loan *)loan {
    EKRecurrenceFrequency freq;
    switch ([loan.paymentFrequency intValue]) {
        case LoanPaymentFrequencyDaily:
            freq = EKRecurrenceFrequencyDaily;
            break;
        case LoanPaymentFrequency3Days:
            freq = EKRecurrenceFrequencyDaily;
            break;
        case LoanPaymentFrequencyWeekly:
            freq = EKRecurrenceFrequencyWeekly;
            break;
        case LoanPaymentFrequencyBiweekly:
            freq = EKRecurrenceFrequencyWeekly;
            break;
        case LoanPaymentFrequencyMonthly:
            freq = EKRecurrenceFrequencyMonthly;
            break;
        case LoanPaymentFrequency3Months:
            freq = EKRecurrenceFrequencyMonthly;
            break;
        case LoanPaymentFrequency6Months:
            freq = EKRecurrenceFrequencyMonthly;
            break;
        case LoanPaymentFrequencyYearly:
            freq = EKRecurrenceFrequencyYearly;
            break;
        default:
            freq = EKRecurrenceFrequencyYearly;
            break;
    }
    return freq;
}

- (int)eventKitIntervalForLoan:(Loan *)loan {
    int interval;
    switch ([loan.paymentFrequency intValue]) {
        case LoanPaymentFrequencyDaily:
            interval = 1;
            break;
        case LoanPaymentFrequency3Days:
            interval = 3;
            break;
        case LoanPaymentFrequencyWeekly:
            interval = 1;
            break;
        case LoanPaymentFrequencyBiweekly:
            interval = 2;
            break;
        case LoanPaymentFrequencyMonthly:
            interval = 1;
            break;
        case LoanPaymentFrequency3Months:
            interval = 3;
            break;
        case LoanPaymentFrequency6Months:
            interval = 6;
            break;
        case LoanPaymentFrequencyYearly:
            interval = 1;
            break;
        default:
            interval = 1;
            break;
    }
    return interval;
}

@end

