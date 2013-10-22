/*
     File: LoanViewController.m
 Abstract: Manages the UI for creating a new loan or viewing an existing one.
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

#import "LoanViewController.h"
#import "Loan.h"
#import "Payment.h"
#import "LoanLengthViewController.h"
#import "PaymentPickerViewController.h"
#import "PaymentScheduleViewController.h"
#import "LoanEventScheduler.h"
#import <AddressBookUI/AddressBookUI.h>
#import <EventKit/EventKit.h>

@implementation LoanViewController
@synthesize loan;
@synthesize delegate;
@synthesize newLoan;
@synthesize useRecurrence;
@synthesize managedObjectContext=managedObjectContext_;

#pragma mark -
#pragma mark View lifecycle

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDoesRelativeDateFormatting:YES];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        
        useRecurrence = NO;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.isNewLoan) {
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        
        self.navigationItem.rightBarButtonItem = saveButton;
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        [saveButton release];
        [cancelButton release];
    }

    addressBook = ABAddressBookCreate();
    self.loan.startDate = [NSDate date];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return (self.isNewLoan) ? 2 : 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section  {
    // Return the number of rows in the section.
    
    int rowCount = 0;
    
    switch (section) {
        case 0:
            rowCount = 2;
            break;
        case 1:
            rowCount = 4;
            break;
        case 2:
            rowCount = 1;
            break;
        case 3:
            rowCount = 1;
            break;
        default:
            break;
    }
    
    return rowCount;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    UITableViewCellAccessoryType editableCellAccessoryType = (self.isNewLoan) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    // Configure the cell...
    
    if (0 == indexPath.section) {
        NSString *CellIdentifier = @"Cell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // contact
        if (0 == indexPath.row) {
            ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [self.loan.personID intValue]);
            cell.accessoryType = editableCellAccessoryType;
            cell.textLabel.text = @"contact";
            if (person) {
                CFStringRef name = ABRecordCopyCompositeName(person);
                cell.detailTextLabel.text = (NSString *)name;
                CFRelease(name);
            } else {
                cell.detailTextLabel.text = nil;
            }
        }
        // loan date
        if (1 == indexPath.row) {
            cell.textLabel.text = @"start date";
            cell.accessoryType = editableCellAccessoryType;
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeZone:NSDateFormatterNoStyle];
            
            cell.detailTextLabel.text = [dateFormatter stringFromDate:self.loan.startDate];
            [formatter release];
        }
        
        cell.selectionStyle = (self.isNewLoan) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    }
    
    if (1 == indexPath.section) {
        
        NSString *CellIdentifier = @"Cell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // amount
        if (0 == indexPath.row) {
            cell.textLabel.text = @"amount";
            cell.accessoryType = editableCellAccessoryType;
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            cell.detailTextLabel.text = [formatter stringFromNumber:self.loan.principal];
            [formatter release];
            
        }
        
        // interest
        if (1 == indexPath.row) {
            cell.textLabel.text = @"interest";
            cell.accessoryType = editableCellAccessoryType;
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterPercentStyle];
            NSString * percent = [formatter stringFromNumber:self.loan.interestRate];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            NSString * amount = [formatter stringFromNumber:self.loan.interest];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", amount, percent];
            
            [formatter release];
        }
        
        // length
        if (2 == indexPath.row) {
            cell.textLabel.text = @"length";
            cell.accessoryType = editableCellAccessoryType;
            cell.detailTextLabel.text = [[LoanLengthViewController loanLengths] objectAtIndex:[self.loan.length intValue]];
        
            
        }
        
        // payments
        if (3 == indexPath.row) {
            cell.textLabel.text = @"payments";
            cell.accessoryType = editableCellAccessoryType;
            cell.detailTextLabel.text = [[PaymentPickerViewController paymentFrequencies] objectAtIndex:[self.loan.paymentFrequency intValue]];
        }
        
        cell.selectionStyle = (self.isNewLoan) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    }
    
    if (2 == indexPath.section) {
        NSString *CellIdentifier = @"Cell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // amount
        if (0 == indexPath.row) {
            cell.textLabel.text = @"payment schedule";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [[NSNumber numberWithInt:[self.loan.payments count]] stringValue];
        }
    }
    
    if (3 == indexPath.section) {
        NSString *CellIdentifier = @"ButtonCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // amount
        if (0 == indexPath.row) {
            Payment *nextPayment = self.loan.nextPayment;
            if (nextPayment) {
                cell.textLabel.text = @"push next payment";
            }
            else {
                cell.textLabel.text = @"push last payment";
            }

            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString * returnString = nil;
    
    NSString * format = @"Next payment: %@ due %@";
    
    if (!self.isNewLoan && 3 == section) {
        Payment *payment = self.loan.nextPayment;
        if (!payment) {
            payment = [self.loan.paymentsSortedByDate lastObject];
            format = @"Last payment: %@ due %@";
        }
        
        returnString = [NSString stringWithFormat:format, 
                        [numberFormatter stringFromNumber:payment.amount], 
                        [dateFormatter stringFromDate:payment.date]];
    }
    
    return returnString;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.

    // only push controllers for new loans, since existing ones aren't editable
    if (self.newLoan) {
        
        if (0 == indexPath.section) {
            // contact
            if (0 == indexPath.row) {
                ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
                peoplePicker.peoplePickerDelegate = (id <ABPeoplePickerNavigationControllerDelegate>)self;
                [self.navigationController presentModalViewController:peoplePicker animated:YES];
                [peoplePicker release];
            }
            
            // date
            if (1 == indexPath.row) {
                DatePickerViewController * pickerController = [[DatePickerViewController alloc] initWithNibName:@"DatePickerViewController" bundle:[NSBundle mainBundle]];
                pickerController.title = @"Start Date";
                pickerController.date = self.loan.startDate;
                pickerController.propertyKey = @"startDate";
                pickerController.delegate = self;
                [self.navigationController pushViewController:pickerController animated:YES];
                [pickerController release];
            }
        }
        
        if (1 == indexPath.section) {
            // amount
            if (0 == indexPath.row) {
                NumberViewController * pickerController = [[NumberViewController alloc] initWithNibName:@"NumberViewController" bundle:[NSBundle mainBundle]];
                pickerController.title = @"Loan Amount";
                [pickerController.formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                pickerController.startNumber = self.loan.principal;
                pickerController.propertyKey = @"principal";
                pickerController.delegate = self;
                [self.navigationController pushViewController:pickerController animated:YES];
                [pickerController release];
            }
            
            // interest
            if (1 == indexPath.row) {
                NumberViewController * pickerController = [[NumberViewController alloc] initWithNibName:@"NumberViewController" bundle:[NSBundle mainBundle]];
                pickerController.title = @"Interest Rate";
                [pickerController.formatter setNumberStyle:NSNumberFormatterPercentStyle];
                pickerController.startNumber = self.loan.interestRate;
                pickerController.propertyKey = @"interestRate";
                pickerController.delegate = self;
                [self.navigationController pushViewController:pickerController animated:YES];
                [pickerController release];
            }
            
            // length
            if (2 == indexPath.row) {
                LoanLengthViewController * pickerController = [[LoanLengthViewController alloc] initWithStyle:UITableViewStyleGrouped];
                pickerController.title = @"Loan Length";
                pickerController.loan = self.loan;
                [self.navigationController pushViewController:pickerController animated:YES];
                [pickerController release];
            }
            
            // payments
            if (3 == indexPath.row) {
                PaymentPickerViewController * pickerController = [[PaymentPickerViewController alloc] initWithNibName:@"PaymentPickerViewController" bundle:[NSBundle mainBundle]];
                pickerController.title = @"Payments";
                pickerController.loan = self.loan;
                [self.navigationController pushViewController:pickerController animated:YES];
                [pickerController release];
            }
        }
    }
    
    if (2 == indexPath.section) {
        // payment schedule
        if (0 == indexPath.row) {
            PaymentScheduleViewController * scheduleController = [[PaymentScheduleViewController alloc] initWithStyle:UITableViewStylePlain];
            scheduleController.managedObjectContext = self.managedObjectContext;
            scheduleController.loan = self.loan;
            scheduleController.title = @"Payments";
            [self.navigationController pushViewController:scheduleController animated:YES];
            [scheduleController release];
        }
    }
    
    if (3 == indexPath.section) {
        // push payment
        if (0 == indexPath.row) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            Payment * payment = self.loan.nextPayment;
            NSString * title = @"Push Next Payment";
            if (!payment) {
                payment = [self.loan.paymentsSortedByDate lastObject];
                title = @"Push Last Payment";
            }
            NSString * amount = [numberFormatter stringFromNumber:payment.amount];
            NSString * date = [dateFormatter stringFromDate:payment.date];
            NSString * message = [NSString stringWithFormat:@"How far into the future would you like to move the payment for %@ due %@?", amount, date];
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"One Day", @"Three Days", @"One Week", nil];
            alertView.delegate = self;
            [alertView show];
            [alertView release];
        }
    }
}

#pragma mark -
#pragma mark PeoplePicker delegate
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    ABRecordID recordID = ABRecordGetRecordID(person);
    self.loan.personID = [NSNumber numberWithInt:recordID];
    [self.navigationController dismissModalViewControllerAnimated:YES];
    [self.tableView reloadData];
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Payments generator

// generates payments using calculations based on loan data
- (void)generatePayments {
    int expectedNumberOfPayments = [self.loan expectedNumberOfPayments];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSNumber * paymentAmount = [formatter numberFromString:[self.loan paymentAmountForNumberOfPayments:expectedNumberOfPayments]];
    NSString * lastPaymentAmount = [self.loan lastPaymentAmountForNumberOfPayments:expectedNumberOfPayments];
    BOOL hasDifferentLastPayment = (lastPaymentAmount) ? YES : NO;
    NSMutableSet * payments = [NSMutableSet set];

    
    for (int payment=1; payment <= expectedNumberOfPayments; payment++) {
        Payment *newPayment = [NSEntityDescription insertNewObjectForEntityForName:@"Payment" inManagedObjectContext:managedObjectContext_];
        newPayment.paymentNumber = [NSNumber numberWithInt:payment];
        if (payment == expectedNumberOfPayments && hasDifferentLastPayment) {
            paymentAmount = [formatter numberFromString:lastPaymentAmount];
        }
        newPayment.amount = paymentAmount;
        newPayment.date = [self.loan expectedDateForPaymentNumber:payment];
        newPayment.loan = self.loan;
        [payments addObject:newPayment];
    }
	
	[formatter release];
    self.loan.payments = payments;
}

// generates payments based on scheduled EKEvents
- (void)generatePaymentsForEvents:(NSArray *)events {
    NSString * lastPaymentAmount = [self.loan lastPaymentAmountForNumberOfPayments:[events count]];
    BOOL hasDifferentLastPayment = (lastPaymentAmount) ? YES : NO;
    NSMutableSet * payments = [NSMutableSet set];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSNumber * paymentAmount = [formatter numberFromString:[self.loan paymentAmountForNumberOfPayments:[events count]]];
    
    int eventNumber = 0;
    for (EKEvent * event in events) {
        Payment *newPayment = [NSEntityDescription insertNewObjectForEntityForName:@"Payment" inManagedObjectContext:managedObjectContext_];
        newPayment.paymentNumber = [NSNumber numberWithInt:eventNumber + 1];
        if (event == [events lastObject] && hasDifferentLastPayment) {
            paymentAmount = [formatter numberFromString:lastPaymentAmount];
        }
        newPayment.amount = paymentAmount;
        newPayment.date = event.startDate;
        newPayment.loan = self.loan;
        newPayment.eventID = event.eventIdentifier;
        [payments addObject:newPayment];
        eventNumber++;
    }
	
    	[formatter release];
    self.loan.payments = payments;
}

#pragma mark -
#pragma mark Button handlers

- (void)save:(id)sender {
    LoanEventScheduler * scheduler = [[LoanEventScheduler alloc] init];
    
	NSArray *events = [scheduler scheduledPaymentEventsUsingRecurrenceForLoan:loan];
	[self generatePaymentsForEvents:events];

	if ([self.loan hasDifferentLastPaymentForNumberOfPayments:[events count]]) {
        [scheduler updateEvent:[events lastObject] withPayment:[loan.orderedPayments lastObject]];
    }

    [scheduler release];
    
    [delegate didSaveNewLoan:self.loan];
}


- (void)cancel:(id)sender {
    [delegate didCancelNewLoan:self.loan];
}

- (void)dealloc {
    [dateFormatter release];
    [numberFormatter release];
    [loan release];
    [managedObjectContext_ release];
    CFRelease(addressBook);
    [super dealloc];
}

#pragma mark -
#pragma mark DatePicker delegate

- (void)dateChanged:(NSDate *)newDate propertyKey:(NSString *)key {
    [self.loan setValue:newDate forKey:key];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark NumberPicker delegate

- (void)numberDidChange:(NSNumber *)number propertyKey:(NSString *)key {
    [self.loan setValue:number forKey:key];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    LoanEventScheduler * scheduler = [[LoanEventScheduler alloc] init];
    Payment * payment = self.loan.nextPayment;
    if (!payment) {
        payment = [self.loan.paymentsSortedByDate lastObject];
    }
    
//    EKEvent * paymentEvent = [scheduler eventRecurrenceForPayment:payment];
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDateComponents * components = [[NSDateComponents alloc] init];
    
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        // 1 Day
        [components setDay:1];
        payment.date = [calendar dateByAddingComponents:components toDate:payment.date options:0];
//        [scheduler updateEvent:paymentEvent withPayment:payment];
        
    }
    else if (buttonIndex == [alertView firstOtherButtonIndex] + 1) {
        // 3 Days
        [components setDay:3];
        payment.date = [calendar dateByAddingComponents:components toDate:payment.date options:0];
//        [scheduler updateEvent:paymentEvent withPayment:payment];
        
    }
    else if (buttonIndex == [alertView firstOtherButtonIndex] + 2) {
        // 1 Week
        [components setWeek:1];
        payment.date = [calendar dateByAddingComponents:components toDate:payment.date options:0];
//        [scheduler updateEvent:paymentEvent withPayment:payment];
    }
    [scheduler release];
    [components release];
    
    [self.managedObjectContext save:NULL];
    [self.tableView reloadData];
}

@end

