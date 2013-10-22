/*
     File: DetailViewController.m 
 Abstract: The view controller representing the right or detail view of the split view controller.
  
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

#import "DetailViewController.h"
#import "RootViewController.h"
#import "TappableView.h"

@interface DetailViewController ()
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIActionSheet *noAppsActionSheet;
@property (nonatomic, retain) UIActionSheet *noOptionsActionSheet;
@property (nonatomic, retain) UIDocumentInteractionController *docInteractionController;
@end


@implementation DetailViewController

@synthesize toolbar, popoverController, detailItem,
            tappableView, docUTILabel, nameLabel, iconView, iconSize,
            noAppsActionSheet, noOptionsActionSheet,
            docInteractionController;

#pragma mark -
#pragma mark Managing the detail item

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
}

- (void)configureView
{
    // update the user interface for the detail item
    //
    self.nameLabel.text = self.docInteractionController.name;
    self.docUTILabel.text = self.docInteractionController.UTI;
    
    // get the largest icon from "docInteractionController"
    UIImage *icon = [self.docInteractionController.icons objectAtIndex:[self.docInteractionController.icons count]-1];
    self.iconView.image = icon;
    CGRect newFrame = iconView.frame;
    newFrame.size = icon.size;
    self.iconView.frame = newFrame;
    
    // Attach all the gesture recognizers to the icon view:
    // For example: tap = show preview, tap and hold = show options
    //
    // These are preconfigured to manage the quick look and options menu.
    // These gesture recognizers should only be installed on your view when the file has been copied
    // locally and is present at URL.
    //
    // Note: If you happen to attach gesture recognizers explicitly to an UIImageView,
    // it's important to set the image view's userInteractionEnabled to YES,
    // or gestures won't be recognized.
    //
    tappableView.gestureRecognizers = self.docInteractionController.gestureRecognizers;
    
    NSError *error;
    NSString *fileURLString = [self.docInteractionController.URL path];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:&error];
    NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
    
    if ((fileSize/1024) == 0)
        self.iconSize.text = [NSString stringWithFormat:@"%ld bytes", fileSize];
    else
        self.iconSize.text = [NSString stringWithFormat:@"%ld KB", fileSize/1024];
}

// when setting the detail item, update the view and dismiss the popover controller if it's showing
- (void)setDetailItem:(id)newDetailItem
{
    if (detailItem != newDetailItem)
    {
        [detailItem release];
        detailItem = [newDetailItem retain];
        
        // setup our a new UIDocumentInteractionController
        [self setupDocumentControllerWithURL:detailItem];
        
        [self configureView];   // update the view with new content
    }

    if (popoverController != nil)
    {
        [popoverController dismissPopoverAnimated:YES];
    }        
}

// dismiss the "no app can open" sheet or "no options" sheet
- (void)dismissAnySheets
{
    // if any of our custom alert sheets are showing in a popover, dismiss them
    if (noAppsActionSheet && !noAppsActionSheet.hidden)
    {
        [noAppsActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    }
    else if (noOptionsActionSheet && !noOptionsActionSheet.hidden)
    {
        [noOptionsActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    }
}


#pragma mark -
#pragma mark Button Actions

- (IBAction)previewAction:(id)sender
{
    // if any of our custom alert sheets are showing in a popover, dismiss them
    [self dismissAnySheets];
    
    self.splitViewController.delegate = nil;
    
    // dismiss any previously presented menu by UIDocumentInteractionController
    [self.docInteractionController dismissMenuAnimated:YES];
    
    if (![self.docInteractionController presentPreviewAnimated:YES])
    {
        // file could not be previewed
    }
}

- (IBAction)openInAction:(id)sender
{
    // if any of our custom alert sheets are showing in a popover, dismiss them
    [self dismissAnySheets];
    
    // dismiss any previously presented menu by UIDocumentInteractionController
    [self.docInteractionController dismissMenuAnimated:YES];
    
    // list of apps that can open the file
    if (![self.docInteractionController presentOpenInMenuFromBarButtonItem:sender animated:YES])
    {
        // no apps were found to open this document so alert the user
        //
        NSString *title = [NSString stringWithFormat:@"No application is capable of opening \"%@\"",
                                            [[self.detailItem absoluteString] lastPathComponent]];
        if (!noAppsActionSheet)
        {
            noAppsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:@"OK", nil];
        }
        
        self.noAppsActionSheet.title = title;
        [self.noAppsActionSheet showFromBarButtonItem:sender animated:YES];
    }
	else
	{
        // "presentOpenInMenuFromBarButtonItem" will present a popover menu anchored from
        // our UIBarbuttonItem: "sender"
        //
        // It includes only those applications capable of opening the current document.
        //
        // This determination is made based on the type of the document (as specified by the UTI property)
        // and the document types supported by the installed applications.
        // To support one or more document types, an application must register those types in its
        // Info.plist file using the CFBundleDocumentTypes key.
        //
        // eventually UIDocumentInteractionController will call us:
        //      willBeginSendingToApplication/didEndSendingToApplication
        //
	}
}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController: (UIPopoverController*)pc
{
    barButtonItem.title = @"Documents";
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items removeObjectAtIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = nil;
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];

    // release any retained subviews of the main view
    self.toolbar = nil;
    self.popoverController = nil;
    
    self.tappableView = nil;
    self.nameLabel = nil;
    self.docUTILabel = nil;
    self.iconView = nil;
    self.iconSize = nil;
    
    if (self.noAppsActionSheet) 
        self.noAppsActionSheet = nil;
    if (self.noOptionsActionSheet)
        self.noOptionsActionSheet = nil;
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
    [popoverController release];
    [toolbar release];

    [docInteractionController release];
    
    [tappableView release];
    [nameLabel release];
    [docUTILabel release];
    [iconView release];
    [iconSize release];
    
    [detailItem release];
    [nameLabel release];
    
    if (noAppsActionSheet)
        [noAppsActionSheet release];
    if (noOptionsActionSheet)
        [noOptionsActionSheet release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"About to ask app:'%@' to open \"%@\"",
          application, [[controller.URL absoluteString] lastPathComponent]);
    
    // note:
    // You can use the "annotation" property to pass information about the document type to the
    // application responsible for opening it.
    //
    // The type of this object should be one of the types used to contain property list information,
    // which includes an NSDictionary, NSArray, NSData, NSString, NSNumber, or NSDate.
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
           didEndSendingToApplication:(NSString *)application
{
    NSLog(@"Finished asking app:'%@' to open \"%@\"",
            application, [[controller.URL absoluteString] lastPathComponent]);
}

// tell the document interaction controller who owns the preview,
// note: this is important for the Quick Look options menu item to function.
//
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    // preview view controller is about to open
    
    // temporrily stop being the delegate to our split view controller:
    //  (previewing will result in our "willHideViewController" method to be called, which will add back the master popover button)
    //  turning of delegation here avoids willHideViewController from being called
    //
    self.splitViewController.delegate = nil;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    // preview view controller was dismissed
    
    self.splitViewController.delegate = self;	// become the delegate again
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller
{
    return self.iconView;   // so preview can zoom animate from this icon image
}

- (BOOL)documentInteractionController:(UIDocumentInteractionController *)controller canPerformAction:(SEL)action
{
    BOOL canPerform = NO;
    if (action == @selector(copy:))
        canPerform = YES;   // pretend to support the copy action
    return canPerform;
}

- (BOOL)documentInteractionController:(UIDocumentInteractionController *)controller performAction:(SEL)action
{
    BOOL handled = NO;
    if (action == @selector(copy:))
    {
        // handle the copy action
        handled = YES;
    }
    return handled;
}

@end
