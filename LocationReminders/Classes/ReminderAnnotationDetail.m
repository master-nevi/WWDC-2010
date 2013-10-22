/*
     File: ReminderAnnotationDetail.m
 Abstract: View controller for editing Reminder details
  Version: 1.0
 
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

#import "ReminderAnnotationDetail.h"
#import "RegionManager.h"

@implementation ReminderAnnotationDetail

@synthesize table, delegate, originalRegion, titleText, titleCell, radiusCell, radiusSlider;

- (ReminderAnnotation *)reminder {
    return [[reminder retain] autorelease];
}

- (void)setReminder:(ReminderAnnotation *)value {
    if (reminder != value) {
        [reminder release];
        reminder = [value retain];
		
		[self updateFields];
    }
}

- (void)updateFields {
	titleText.text = reminder.title;
	radiusSlider.value = reminder.radius;
	radiusSlider.minimumValue = [[RegionManager sharedInstance] minDistance];
	radiusSlider.maximumValue = [[RegionManager sharedInstance] maxDistance];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.table.allowsSelection = NO;
	[self updateFields];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)save:(id)sender {
	// assign fields back into the annotation then call
	
	self.originalRegion = self.reminder.region;
	
	reminder.title = titleText.text;
	reminder.radius = radiusSlider.value;
	
	[self.delegate reminderAnnotationDetailDidFinish:self withAction:ReminderAnnotationDetailActionSave];
}
- (IBAction)cancel:(id)sender {
	// just return, nothing happened
	[self.delegate reminderAnnotationDetailDidFinish:self withAction:ReminderAnnotationDetailActionCancel];
}
- (IBAction)remove:(id)sender {
	// just return, delegate should delete the annotation
	[self.delegate reminderAnnotationDetailDidFinish:self withAction:ReminderAnnotationDetailActionRemove];
}

- (IBAction)sliderChanged:(id)sender {
	[self.table reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)dealloc {
	self.originalRegion = nil;
	self.reminder = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark UITextFieldDelegate

// UITextField delegate response to dismiss the keyboard upon return
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}


#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	NSInteger numRows = 0;
	switch (section) {
		case 0:
		case 1:
			numRows = 1;
			break;
		case 2:
			numRows = 2;
			break;
		default:
			NSAssert(NO, @"don't know about this section");
			break;
	}
	return numRows;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"%@",indexPath);
	UITableViewCell *cell = nil;
	switch (indexPath.section) {
		case 0:
			cell = self.titleCell;
			break;
		case 1:
			cell = self.radiusCell;
			break;
		case 2:
			if (indexPath.row == 0) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];
				cell.textLabel.text = @"Latitude";
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", reminder.coordinate.latitude];
			} else {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil] autorelease];
				cell.textLabel.text = @"Longitude";
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", reminder.coordinate.longitude];
			}
			break;
		default:
			NSAssert(NO, @"don't know about this section");
			break;
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *header = nil;
	switch (section) {
		case 0:
			header = @"Remember to";
			break;
		case 1:
			header = @"within";
			break;
		case 2:
			header = @"of";
			break;
		case 3:
		default:
			header = nil;
			break;
	}
	return header;
}// fixed font style. use custom view (UILabel) if you want something different

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *footer = nil;
	switch (section) {
		case 1:
			footer = [NSString stringWithFormat:@"%.0f meters", radiusSlider.value];
			break;
		default:
			footer = nil;
			break;
	}
	return footer;
}
@end
