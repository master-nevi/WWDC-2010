//     File: GCViewController.m
// Abstract: The main view controller
//  Version: 1.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2010 Apple Inc. All Rights Reserved.
// 

#import <QuartzCore/QuartzCore.h>
#import "RecentCommandsController.h"
#import "GCConfig.h"
#import "GCViewController.h"

#define CONSOLE_BAR_HEIGHT 44.0
#define degreesToRadian(x) (M_PI * (x) / 180.0)

@implementation GCViewController

@synthesize console, recentCommandsController, recentCommandsPopoverController, recentCommandsNavController;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		displayConsole = NO;
		deviceWidth = [UIScreen mainScreen].applicationFrame.size.width;
		deviceHeight = [UIScreen mainScreen].applicationFrame.size.height;
    }
    return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (void)executeCommand:(NSString *)commandString
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[recentCommandsPopoverController dismissPopoverAnimated:NO];		
	} else {
		[recentCommandsController.tableView removeFromSuperview];
	}
    [console resignFirstResponder];
	
	NSArray *array = [commandString componentsSeparatedByString: @"="];
	NSString *key = nil;
	NSString *value = nil;
	
	if (array.count == 2) {
		key = [array objectAtIndex:0];
		value = [array objectAtIndex:1];
	} else if (array.count == 1) {
		key = [array objectAtIndex:0];
		value = @"YES";		// commands are represented as "command=YES". We need a value for the key-value pair, but it really doesn't matter what the value is
	}
	
	if (key && key.length && value && value.length) {
		
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *n = [f numberFromString: value];
		[f release];
		
		if (n != nil) {
			[[GCConfig sharedConfig] setValue: n
								   forCommand: key];
		} else {
			[[GCConfig sharedConfig] setValue: value
								   forCommand: key];			
		}
		
	}
}

- (IBAction)toggleConsole:(id)sender
{
	CGFloat consoleBarWidth = 320.0;		// sensible defaults
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if ((orientation == UIDeviceOrientationLandscapeRight) || (orientation == UIDeviceOrientationLandscapeLeft)) {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.height;
	} else {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.width;
	}
	
	// also, make it a singleton instead of creating one per screen
	if (!console) {
		[self setConsole: [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, -CONSOLE_BAR_HEIGHT, consoleBarWidth, CONSOLE_BAR_HEIGHT)]];
		console.barStyle = UIBarStyleBlackTranslucent;
		console.keyboardType = UIKeyboardTypeASCIICapable;
		console.delegate = self;
		
		// Create and configure the recent searches controller.
		RecentCommandsController *aRecentsController = [[RecentCommandsController alloc] initWithStyle:UITableViewStylePlain];
		self.recentCommandsController = aRecentsController;
		recentCommandsController.delegate = self;
		[aRecentsController release];
		
		// Create a navigation controller to contain the recent searches controller, and create the popover controller to contain the navigation controller.
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:recentCommandsController];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
			self.recentCommandsPopoverController = popover;
			recentCommandsPopoverController.delegate = self;
			
			// Ensure the popover is not dismissed if the user taps in the search bar.
			popover.passthroughViews = [NSArray arrayWithObject:console];
			[popover release];
		} else {
			self.recentCommandsNavController = navigationController;
		}
		[navigationController release];
		
		// customize the keyboard
		for (UIView *searchBarSubview in [console subviews]) {
			
            if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {
				
                @try {
                    [(UITextField *)searchBarSubview setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [(UITextField *)searchBarSubview setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [(UITextField *)searchBarSubview setReturnKeyType:UIReturnKeyGo];
                    [(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
                }
                @catch (NSException * e) {
					
                    // ignore exception
                }
            }
        }
		
		[self.view addSubview: console];
		
		[console release];
	}
	
	CGRect newFrame = console.frame;
	
	if (displayConsole) {
		newFrame.origin.y -= CONSOLE_BAR_HEIGHT;
		[console resignFirstResponder];
	} else {
		newFrame.origin.y = 0.0;
		[console becomeFirstResponder];
	}
	
	[console setFrame: newFrame];
	
	displayConsole = !displayConsole;
}

#pragma mark -
#pragma mark Search results controller delegate method

- (void)recentCommandsController:(RecentCommandsController *)controller didSelectString:(NSString *)commandString {
    
    /*
     The user selected a row in the recent searches list.
     Set the text in the search bar to the search string, and conduct the search.
     */
    console.text = commandString;
	//    [self executeCommand:commandString];
}

#pragma mark -
#pragma mark Search bar delegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect popoverRect = [console bounds];
		popoverRect.origin.y = CONSOLE_BAR_HEIGHT;
		popoverRect.origin.x = -console.bounds.size.width * 0.5;
		[recentCommandsPopoverController presentPopoverFromRect:popoverRect inView:console permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		CGRect tableViewRect = [console frame];
		tableViewRect.origin.y = CONSOLE_BAR_HEIGHT;
		tableViewRect.size.height *= 3;
		
		[recentCommandsController.tableView setFrame: tableViewRect];
		[self.view addSubview: recentCommandsController.tableView];
		[recentCommandsController.tableView scrollsToTop];
	}
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)aSearchBar {
    
    // If the user finishes editing text in the search bar by, for example tapping away rather than selecting from the recents list, then just dismiss the popover.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[recentCommandsPopoverController dismissPopoverAnimated:NO];		
	} else {
		NSString *commandString = [console text];
		[recentCommandsController addToRecentSearches:commandString];
		[recentCommandsController.tableView removeFromSuperview];
	}
    [aSearchBar resignFirstResponder];
	[self toggleConsole:self];
}


- (void)console:(UISearchBar *)console textDidChange:(NSString *)searchText {
    
    // When the search string changes, filter the recents list accordingly.
    [recentCommandsController filterResultsUsingString:searchText];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    
    // When the search button is tapped, add the search term to recents and conduct the search.
    NSString *commandString = [console text];
    [recentCommandsController addToRecentSearches:commandString];
    [self executeCommand:commandString];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
    // Remove focus from the search bar without committing the search.
    [console resignFirstResponder];
}

#pragma mark -
#pragma mark Housekeeping

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (displayConsole) {
		[self toggleConsole:self];		
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	CGFloat consoleBarWidth = 320.0;		// sensible defaults
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if ((orientation == UIDeviceOrientationLandscapeRight) || (orientation == UIDeviceOrientationLandscapeLeft)) {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.height;
	} else {
		consoleBarWidth = [UIScreen mainScreen].applicationFrame.size.width;
	}
	
	[console setFrame: CGRectMake(0.0, 0.0, consoleBarWidth, CONSOLE_BAR_HEIGHT)];
}

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


- (void)dealloc {
    [super dealloc];
}


@end
