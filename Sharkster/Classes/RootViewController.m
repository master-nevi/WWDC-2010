/*
     File: RootViewController.m
 Abstract: Displays a list of loans, handles editing that list, and pushes the appropriate view controller when the user selects a loan from the list.
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

#import "RootViewController.h"
#import "LoanViewController.h"
#import "LoanTableViewCell.h"
#import "Loan.h"
#import "Payment.h"

#import "LoanEventScheduler.h";
@interface RootViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (Loan *)createNewLoan;
@end


@implementation RootViewController

@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_, loanCell;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up the edit and add buttons.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showNewLoanController)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton release];
    
    if (!addressBook) {
        addressBook = ABAddressBookCreate();
    }
    
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
    }
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
}


- (void)configureCell:(LoanTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    Loan *loan = (Loan *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSNumber *personID = loan.personID;
    if ([personID intValue] != -1) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [personID intValue]);
		if(person) {
			CFStringRef name = ABRecordCopyCompositeName(person);
			cell.nameLabel.text = (NSString *)name;
			CFRelease(name);
		}
    } else {
        cell.nameLabel.text = nil;
    }

    
    NSNumber *loanAmt = loan.principal;
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	cell.amountLabel.text = [numberFormatter stringFromNumber:loanAmt];
    
	NSNumber *loanRate = loan.interestRate;
	[numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
	cell.interestRateLabel.text = [numberFormatter stringFromNumber:loanRate];
    
    //next payment
    Payment *paymentToDisplay = loan.nextPayment;
    if (!paymentToDisplay) {
        paymentToDisplay = [loan.paymentsSortedByDate lastObject];
    }
    
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];	
	cell.nextPaymentAmountLabel.text = [numberFormatter stringFromNumber:paymentToDisplay.amount];
	CGSize nextPaymentTextSize = [cell.nextPaymentAmountLabel.text sizeWithFont:cell.nextPaymentAmountLabel.font constrainedToSize:CGSizeMake(60,20) lineBreakMode:UILineBreakModeTailTruncation];
	cell.nextPaymentAmountLabel.frame = CGRectMake(9, 25, nextPaymentTextSize.width, 20);
	
	cell.nextPaymentDueLabel.frame = CGRectMake(9 + (int)nextPaymentTextSize.width + 3, 25, 120,20);
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDoesRelativeDateFormatting:YES];
	cell.nextPaymentDueLabel.text = [NSString stringWithFormat:@"due %@", [dateFormatter stringFromDate:paymentToDisplay.date]];
}


#pragma mark -
#pragma mark Add a new object

- (void) showNewLoanController {
    LoanViewController *newLoanController = [[LoanViewController alloc] initWithNibName:@"LoanViewController" bundle:[NSBundle mainBundle]];
    newLoanController.title = @"New Loan";
    newLoanController.delegate = self;
    newLoanController.loan = [self createNewLoan];
    newLoanController.newLoan = YES;
    newLoanController.managedObjectContext = self.managedObjectContext;
    UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:newLoanController];
    [self.navigationController presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [newLoanController release];
}

- (NSManagedObject *)createNewLoan {
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidstring = CFUUIDCreateString(NULL, uuid);
    [newManagedObject setValue:(NSString *)uuidstring forKey:@"identifier"];
    CFRelease(uuid);
    CFRelease(uuidstring);
    
    return newManagedObject;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"LoanCell";
    
    LoanTableViewCell *cell = (LoanTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"LoanCell" owner:self options:nil];
		cell = self.loanCell;
		self.loanCell = nil;
    }
    
    // Configure the cell.
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 48;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Loan * loan = (Loan *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        
		// Delete the payment events from the EventStore
        LoanEventScheduler * scheduler = [[LoanEventScheduler alloc] init];
        [scheduler deleteAllEventsForPayments:loan.orderedPayments];
        [scheduler release];
		
        // Delete the managed object
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:loan];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here -- for example, create and push another view controller.
    
    LoanViewController *loanViewController = [[LoanViewController alloc] initWithNibName:@"LoanViewController" bundle:[NSBundle mainBundle]];
    NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    loanViewController.loan = (Loan*) selectedObject;
    loanViewController.title = [NSString stringWithFormat:@"%@ - %@", ((LoanTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath]).nameLabel.text, ((LoanTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath]).amountLabel.text];
    loanViewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:loanViewController animated:YES];
    [loanViewController release];
     
}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    /*
     Set up the fetched results controller.
    */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Loan" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;
}    


#pragma mark -
#pragma mark Fetched results controller delegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}


/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [dateFormatter release];
    [numberFormatter release];
    [fetchedResultsController_ release];
    [managedObjectContext_ release];
    [super dealloc];
}


#pragma mark -
#pragma mark NewLoanViewController delegate

- (void) didSaveNewLoan:(Loan *)loan {
    // Save the context.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    NSError *error = nil;
    if (![context save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
    
}

- (void) didCancelNewLoan:(Loan *)loan {
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    [context deleteObject:loan];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

@end

