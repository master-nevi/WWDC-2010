/*
     File: DetailViewController.m
 Abstract: Displayed by the app's split view controller on the iPad. Contains a view for the selected cutout, and handles related toolbar items.
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

#import "DetailViewController.h"
#import "GalleryViewController.h"


@interface DetailViewController ()
@property (nonatomic, retain) UIPopoverController *popoverController;
- (void)configureView;
@end



@implementation DetailViewController

@synthesize titleBar, currentViewContainer, popoverController;
@synthesize currentView;
@synthesize delegate;


#pragma mark -
#pragma mark Managing the detail item

- (void)configureView {
    // Update the user interface for the detail item.
}

- (void)share:(id)sender {
    [delegate detailViewControllerDidShare:self];
}

- (BOOL)isShowingShareButton {
	return (titleBar.topItem.rightBarButtonItem != nil);
}

- (void)setShowingShareButton:(BOOL)showingShareButton {
    if (showingShareButton != [self isShowingShareButton]) {
		if (showingShareButton) {
			shareButton = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleBordered target:self action:@selector(share:)];
			[titleBar.topItem setRightBarButtonItem:shareButton animated:YES];
			[shareButton release];
		} else {
			titleBar.topItem.rightBarButtonItem = nil;
		}
    } 
}

- (void)setCurrentView:(UIView *)newView {
    if (currentView != newView) {
        [currentView removeFromSuperview];
        
        [currentView release];
        currentView = [newView retain];
        
        [currentView setFrame:currentViewContainer.bounds];
        
        [currentViewContainer addSubview:currentView];
        
        [self configureView];
    }
}

- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (currentView) {
		if (popoverController) {
			[popoverController dismissPopoverAnimated:YES];
		}
        CGRect rect = CGRectMake((int)(currentView.bounds.size.width / 2),(int)(currentView.bounds.size.height * .9),2,2);//[currentView convertRect:CGRectMake(currentView.bounds.size.width / 2,currentView.bounds.size.height * .8,2,2) toView:currentView.window];
        popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
        popoverController.delegate = self;
        [popoverController presentPopoverFromRect:rect inView:currentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
    }
}

- (void)dismissViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [popoverController dismissPopoverAnimated:animated];
}

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc {
    
    barButtonItem.title = @"Gallery";
	[titleBar.topItem setLeftBarButtonItem:barButtonItem animated:YES];
	if (self.popoverController) {
		[self.popoverController dismissPopoverAnimated:YES];
		self.popoverController.delegate = nil;
	}
    self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [titleBar.topItem setLeftBarButtonItem:nil animated:YES];
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Popover controller support

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)pc {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)pc {
	pc.delegate = nil;
	[pc release];
	if (pc == popoverController) {
		popoverController = nil;
	}
}


#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    popoverController.delegate = nil;
	[popoverController release];
    
    [currentView release];
    
	[super dealloc];
}

@end
