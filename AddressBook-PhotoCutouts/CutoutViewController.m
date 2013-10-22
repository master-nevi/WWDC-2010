/*
     File: CutoutViewController.m
 Abstract: Displays a contact's photo in a scroll view, allowing the user to move and scale it to fit within a "cutout" overlay. When not being edited, presents the contact's information (in either a person view controller or unknown-person view controller) when the user taps it. Calls various delegate methods when the user taps its "Cancel", "Save", or "Share" buttons.
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

#import "CutoutViewController.h"
#import "GalleryViewController.h"
#import "CutoutView.h"

@interface CutoutViewController (Private)
- (void)updateSaveShareButton;
- (void)updateNavigationButtons;
- (void)updateTitle;
@end

@implementation CutoutViewController

@synthesize cutoutImage;
@synthesize personImage;

@synthesize delegate;


- (id)initWithAddressBook:(ABAddressBookRef)book editable:(BOOL)isEditable {
	self = [super init];
	if (self) {
        editable = isEditable;
        
        addressBook = CFRetain(book);
	}
	
	return self;
}

- (void)dealloc {
	CFRelease(addressBook);
	
    popoverController.delegate = nil;
    [popoverController release];
	
    if (personForPhoto) {
        CFRelease(personForPhoto);
    }
    
    [cutoutImage release];
    [personImage release];
    
	[super dealloc];
}

- (BOOL)shouldPresentViewControllerInPopover:(UIViewController *)viewController {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (void)presentViewControllerInPopover:(UIViewController *)viewController {
    if (!popoverController) {
        popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
        popoverController.delegate = self;
    
        [popoverController presentPopoverFromRect:self.view.bounds inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)dismissPopover {
    if (popoverController) {
        [popoverController dismissPopoverAnimated:YES];
        popoverController.delegate = nil;
        [popoverController release];
        popoverController = nil;
    }
}

- (void)presentViewController:(UIViewController *)viewController {
    if ([self shouldPresentViewControllerInPopover:viewController]) {
        [self presentViewControllerInPopover:viewController];
    } else {
        [self presentModalViewController:viewController animated:YES];
    }
}

- (void)dismissViewController:(UIViewController *)viewController {
    if ([self shouldPresentViewControllerInPopover:viewController]) {
        [self dismissPopover];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)photoTapped:(id)sender {
    if (editable) {
        // The user is in the middle of creating a cutout picture.
        // Show the people picker.
        ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        peoplePicker.addressBook = addressBook;
        peoplePicker.peoplePickerDelegate = self;
        [self presentViewController:peoplePicker];
        [peoplePicker release];
    } else if (personForPhoto) {
        // The user is viewing a previously-created cutout picture.
        // Show the picture's contact information.
        UIViewController *viewController = nil;
        if (ABRecordGetRecordID(personForPhoto) != kABRecordInvalidID) {
            ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
            personViewController.displayedPerson = personForPhoto;
            personViewController.allowsEditing = YES;
            if ([[UIDevice currentDevice].systemVersion floatValue] >= 4.0) {
                personViewController.shouldShowLinkedPeople = YES;
            }
            
            viewController = personViewController;
        } else {
            ABUnknownPersonViewController *unknownPersonViewController = [[ABUnknownPersonViewController alloc] init];
            unknownPersonViewController.addressBook = addressBook;
            unknownPersonViewController.displayedPerson = personForPhoto;
            unknownPersonViewController.allowsAddingToAddressBook = YES;
            unknownPersonViewController.unknownPersonViewDelegate = self;
            
            viewController = unknownPersonViewController;
        }
        
        UINavigationController *navigationController = nil;
        if ([self shouldPresentViewControllerInPopover:viewController]) {
            navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [self presentViewControllerInPopover:navigationController];
        } else {
            [[self navigationController] pushViewController:viewController animated:YES];
        }
        [navigationController release];
        [viewController release];
    }
}

- (void)cancel:(id)sender {
	[delegate cutoutViewControllerDidCancel:self];
}

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSArray *)allImagesForPerson:(ABRecordRef)person {
    NSArray *linkedPeople = nil;
    
    if (person) {
		if ([[UIDevice currentDevice].systemVersion floatValue] >= 4.0) {
            linkedPeople = [(NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person) autorelease];
		} else {
			linkedPeople = [NSArray arrayWithObject:(id)person];
		}
    }

    NSMutableArray *linkedImages = [[[NSMutableArray alloc] initWithCapacity:[linkedPeople count]] autorelease];

    for (id object in linkedPeople) {
        ABRecordRef linkedPerson = (ABRecordRef)object;
        UIImage *image = nil;
        NSData *imageData = (NSData *)ABPersonCopyImageData(linkedPerson);
        if (imageData) {
            image = [UIImage imageWithData:imageData];
            [linkedImages addObject:image];
            [imageData release];
        }
    }

    return linkedImages;
}


- (void)save:(id)sender {	
    [delegate cutoutViewController:self saveCutoutWithPerson:personForPhoto];
}

- (void)share:(id)sender {
    [delegate cutoutViewController:self shareCutoutWithPerson:personForPhoto];
}

- (void)getCurrentImage:(UIImage **)outImage currentThumbnail:(UIImage **)outThumbnail {
    [(CutoutView *)self.view getCurrentImage:outImage currentThumbnail:outThumbnail];
}

#pragma mark -
#pragma mark Setters/getters

- (void)setPerson:(ABRecordRef)person {
    if (personForPhoto != person) {
        if (personForPhoto) {
            CFRelease(personForPhoto);
        }
        if (person) {
            CFRetain(person);
        }
        personForPhoto = person;
    }
    [self updateTitle];
}

- (ABRecordRef)person {
    return personForPhoto;
}

- (void)setCutoutImage:(UIImage *)image {
    if (cutoutImage != image) {
        [cutoutImage release];
        cutoutImage = [image retain];
        [(CutoutView *)self.view setCutoutImage:image];
    }
}

- (void)setPersonImage:(UIImage *)image {
    if (personImage != image) {
        [personImage release];
        personImage = [image retain];
        [(CutoutView *)self.view setPersonImage:image];
        [self updateSaveShareButton];
    }
}

#pragma mark Display update methods

- (void)updateTitle {
    if (personForPhoto) {
        NSString *personName = (NSString *)ABRecordCopyCompositeName(personForPhoto);
        self.title = personName;
        [personName release];
    } else {
        self.title = @"Tap to add photo";
    }
}

- (void)updateSaveShareButton {
    if (editable) {
        if (self.personImage) {
            UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
            self.navigationItem.rightBarButtonItem = saveButton;
            [saveButton release];        
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    } else {
        // Only useful for iPhone version - iPad version calls [DetailViewController setShowingShareButton:]
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleBordered target:self action:@selector(share:)];
        self.navigationItem.rightBarButtonItem = shareButton;
        [shareButton release];
    }
}

- (void)updateNavigationButtons {
    if (editable) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];
    } else {
        // Only useful for iPhone version - iPad version sits in split view controller
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    }
    
    [self updateSaveShareButton];
}

#pragma mark -
#pragma mark ABUnknownPersonViewControllerDelegate

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonViewController didResolveToPerson:(ABRecordRef)person {
    [self dismissViewController:unknownPersonViewController];

    if (person) {
        [self setPerson:person];
        [delegate cutoutViewController:self saveCutoutWithPerson:person];
    }
}

#pragma mark -
#pragma mark ABPeoplePickerNavigationControllerDelegate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewController:peoplePicker];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    NSArray *personImages = [self allImagesForPerson:person];
    int numImages = [personImages count];
    if (numImages > 0) {
        [self setPerson:person];
        
        if (numImages == 1) { // don't need a picker UI
            self.personImage = [personImages objectAtIndex:0];
            [self dismissViewController:peoplePicker];
        } else {
            PhotoPickerViewController *photoPickerController = [[PhotoPickerViewController alloc] init];
            photoPickerController.delegate = self;
            photoPickerController.photos = personImages;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photoPickerController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [photoPickerController release];
            
            if ([self shouldPresentViewControllerInPopover:navController]) {
                [self dismissViewController:peoplePicker];
                [self presentModalViewController:navController animated:YES];
            } else {
                [peoplePicker presentModalViewController:navController animated:YES];
            }
            [navController release];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No photo" message:@"Please choose a contact who has a photo." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
	
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return NO;
}

#pragma mark -
#pragma mark PhotoPickerControllerDelegate

- (void)photoPickerController:(PhotoPickerViewController *)photoPickerController didFinishPickingImageAtIndex:(NSInteger)index {
	UIImage *chosenImage = [photoPickerController.photos objectAtIndex:index];
	self.personImage = chosenImage;

    if (![self shouldPresentViewControllerInPopover:photoPickerController]) {
        [photoPickerController retain];
        UIViewController *peoplePicker = photoPickerController.parentViewController.parentViewController;
        [photoPickerController dismissModalViewControllerAnimated:NO];
        [peoplePicker dismissModalViewControllerAnimated:NO];
        [self presentModalViewController:photoPickerController animated:NO];
        [photoPickerController autorelease];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)photoPickerControllerDidCancel:(PhotoPickerViewController *)photoPickerController {
    [self setPerson:NULL];
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
    
    [(CutoutView *)self.view setAllowsEditing:editable];
    [(CutoutView *)self.view setCutoutImage:self.cutoutImage];
    [(CutoutView *)self.view setPersonImage:self.personImage];
    
    [self updateTitle];
    [self updateNavigationButtons];
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)pc {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)pc {
    popoverController.delegate = nil;
    [popoverController release];
    popoverController = nil;
}


@end
