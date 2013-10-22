/*
     File: GalleryViewController.m
 Abstract: Main view controller. Manages the list of cutouts and handles the transitions between view controllers, acting as the delegate for most of them.
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

#import "Cutout.h"
#import "GalleryViewController.h"
#import "DetailViewController.h"

#define kCutoutsSavedIndex        0
#define kCutoutsReceievedIndex    1

@interface GalleryViewController ()
@property(nonatomic, retain, readonly) NSArray *allCutoutPhotos;
@end

void abChanged(ABAddressBookRef addressBook, CFDictionaryRef info, void *context);

@interface GalleryViewController (Private)
- (void)loadAllCutoutPhotos;
- (void)saveAllCutoutPhotos;
@end

@implementation GalleryViewController

- (void)dealloc {
	if (addressBook) {
        CFRelease(addressBook);
    }
    
    [cutoutNames release];
    [allCutoutPhotos release];
    
    [selectedIndexPath release];
    
    cutoutViewController.delegate = nil;
    [cutoutViewController release];
    
    cutoutViewController.delegate = nil;
    [cutoutViewController release];
    
    [detailViewController release];
    
    [super dealloc];
}

@synthesize detailViewController;
@synthesize selectedIndexPath;
@synthesize addressBook;

- (void)setAddressBook:(ABAddressBookRef)book {
	if (addressBook != book) {
		if (addressBook) {
            ABAddressBookUnregisterExternalChangeCallback(addressBook, abChanged, self);
			CFRelease(addressBook);
		}
        if (book) {
            ABAddressBookRegisterExternalChangeCallback(book, abChanged, self);
            CFRetain(book);
        }
		addressBook = book;
	}
}

- (UIImage *)displayImageForPhotoName:(NSString *)photoName {
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",photoName]];
}

- (UIImage *)transparentImageForPhotoName:(NSString *)photoName {
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_frame.png", photoName]];
}

- (IBAction)showNewPhotoPicker:(id)sender {
	if (!cutoutNames) {
		cutoutNames = [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cutouts" ofType:@"plist"]] retain];
	}
	
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:[cutoutNames count]];
    for (NSString *photoName in cutoutNames) {
        [photos addObject:[self displayImageForPhotoName:photoName]];
    }

    PhotoPickerViewController *photoPickerController = [[PhotoPickerViewController alloc] init];
    photoPickerController.delegate = self;
    photoPickerController.title = @"Choose Frame";
    photoPickerController.photos = photos;
    
    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:photoPickerController];
    
    [photoPickerController release];
    
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [detailViewController dismissViewController:self animated:YES];
        modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [detailViewController presentModalViewController:modalNavigationController animated:YES];
	} else {
		[[self navigationController] presentModalViewController:modalNavigationController animated:YES];
	}
    [modalNavigationController release];
}

- (void)refresh {
	[self loadAllCutoutPhotos];
	[self.tableView reloadData];
}

- (BOOL)hasSavedData {
    return (self.allCutoutPhotos && [[self.allCutoutPhotos objectAtIndex:kCutoutsSavedIndex] count]);
}

- (BOOL)hasReceivedData {
    return (self.allCutoutPhotos && [[self.allCutoutPhotos objectAtIndex:kCutoutsReceievedIndex] count]);
}

- (BOOL)hasData {
    return ([self hasSavedData] || [self hasReceivedData]);
}

- (Cutout *)cutoutAtIndexPath:(NSIndexPath *)indexPath {
    return [[allCutoutPhotos objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (void)displayCutoutViewControllerAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    [self setSelectedIndexPath:indexPath];
    
    Cutout *cutout = [self cutoutAtIndexPath:indexPath];
    
    UIImage *personImage = [cutout image];
    ABRecordRef person = [cutout person];
    
    if (!cutoutViewController) {
        cutoutViewController = [[CutoutViewController alloc] initWithAddressBook:self.addressBook editable:NO];
        cutoutViewController.delegate = self;
    }
    
    [cutoutViewController setPerson:person];
    cutoutViewController.personImage = personImage;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        detailViewController.currentView = cutoutViewController.view;
        detailViewController.showingShareButton = (cutoutViewController.view != nil);
		detailViewController.titleBar.topItem.title = cutoutViewController.title;
    } else {
        if ([self.navigationController topViewController] != self) {
            [self.navigationController popToRootViewControllerAnimated:animated];
        }
        [self.navigationController pushViewController:cutoutViewController animated:animated];            
    }
}

- (NSArray *)allCutoutPhotos {
	if (allCutoutPhotos == nil) {
		[self loadAllCutoutPhotos];
	}
	
	return allCutoutPhotos;
}

- (void)shareCutoutRepresentation:(NSDictionary *)dict {
    NSMutableData *archiveData = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];
    [archiver encodeObject:dict forKey:@"info"];
    [archiver finishEncoding];
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.mailComposeDelegate = self;
    [composer addAttachmentData:archiveData mimeType:@"application/x-photobook-cutout" fileName:[NSString stringWithFormat:@"%@.pbcutout", [dict objectForKey:kCutoutPersonNameCompositeKey]]];
    [composer setMessageBody:@"Check out this picture I made!" isHTML:NO];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        composer.modalPresentationStyle = UIModalPresentationFormSheet;
        [detailViewController presentModalViewController:composer animated:YES];
    } else {
        [self.navigationController presentModalViewController:composer animated:YES];
    }
    
    [composer release];
    [archiver release];
    [archiveData release];
}

- (void)loadReceivedCutoutPhotoWithData:(NSData *)cutoutData {
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:cutoutData];
	NSDictionary *infoDict = [unarchiver decodeObjectForKey:@"info"];
    if (infoDict) {
        Cutout *cutout = [[Cutout alloc] initWithDictionaryRepresentation:infoDict addressBook:addressBook];
        NSUInteger row = [[self.allCutoutPhotos objectAtIndex:kCutoutsReceievedIndex] count];
        [[self.allCutoutPhotos objectAtIndex:kCutoutsReceievedIndex] addObject:cutout];
        [cutout release];

        // Save, which commits the images to disk, but also in case we just matched the received cutout.
        [self saveAllCutoutPhotos];
        
        [self.tableView reloadData]; // our number of photos may have changed
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:kCutoutsReceievedIndex];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
		[self displayCutoutViewControllerAtIndexPath:indexPath animated:NO];
	} else {
		NSLog(@"Something's wrong with the archive");
	}
	[unarchiver release];
}

- (void)loadImageDataForCutout:(Cutout *)cutout representation:(NSDictionary *)dict {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *imageName = [dict valueForKey:kCutoutImageNameKey];
    NSString *imagePath = [documentsPath stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    NSString *thumbPath = [imagePath stringByAppendingString:@"_thumb"];
    UIImage *thumbnail = [UIImage imageWithContentsOfFile:thumbPath];
    
    [cutout setImageName:imageName];
    [cutout setImage:image];
    [cutout setThumbnail:thumbnail];
}

- (void)loadAllCutoutPhotos {
	if (allCutoutPhotos != nil) {
		[allCutoutPhotos release];
		allCutoutPhotos = nil;
	}
    
    // Create room for saved and received cutoutPhotos.
    allCutoutPhotos = [[NSArray alloc] initWithObjects:[NSMutableArray array], [NSMutableArray array], nil];
    
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"Cutouts.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSData *plistData = [NSData dataWithContentsOfFile:[documentsPath stringByAppendingPathComponent:@"Cutouts.plist"]];
        NSArray *root = (NSArray *)[NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:NULL];
        NSUInteger i = 0;
        for (NSArray *savedCutoutPhotos in root) {
            NSMutableArray *cutoutPhotos = [allCutoutPhotos objectAtIndex:i];
            for (NSDictionary *dict in savedCutoutPhotos) {
                Cutout *cutout = [[Cutout alloc] initWithDictionaryRepresentation:dict addressBook:addressBook];
                [self loadImageDataForCutout:cutout representation:dict];
                [cutoutPhotos addObject:cutout];
                [cutout release];
            }
            ++i;
        }
	}
}

- (void)saveImageDataForCutout:(Cutout *)cutout representation:(NSMutableDictionary *)mutableDict {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    // Save image/thumbnail data separately from the person data.
    NSData *imageData = [[mutableDict valueForKey:kCutoutImageDataKey] retain];
    [mutableDict removeObjectForKey:kCutoutImageDataKey];
    
    NSData *thumbnailData = [[mutableDict valueForKey:kCutoutThumbnailDataKey] retain];
    [mutableDict removeObjectForKey:kCutoutThumbnailDataKey];
    
    if (![cutout imageName]) {
        // Save its images to disk (and save an image name for lookup when loading).
        CFUUIDRef uuidObj = CFUUIDCreate(NULL);
        NSString *imageName = (NSString *)CFUUIDCreateString(NULL, uuidObj);
        CFRelease(uuidObj);
        
        [cutout setImageName:imageName];
        
        NSString *imagePath = [documentsPath stringByAppendingPathComponent:imageName];
        [imageData writeToFile:imagePath atomically:YES];
        
        NSString *thumbPath = [imagePath stringByAppendingString:@"_thumb"];
        [thumbnailData writeToFile:thumbPath atomically:YES];
        
        // Track the image write-to-disk by setting/storing the image name.
        [mutableDict setValue:imageName forKey:kCutoutImageNameKey];
        [imageName release];
    }
    
    [imageData release];
    [thumbnailData release];    
}

- (void)saveAllCutoutPhotos {
    NSArray *root = [NSArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], nil];
    
    NSUInteger i = 0;    
    for (NSArray *cutoutPhotos in allCutoutPhotos) {
        NSMutableArray *cutoutPhotosToSave = [root objectAtIndex:i];
        for (Cutout *cutout in cutoutPhotos) {
            NSMutableDictionary *mutableDict = [cutout newDictionaryRepresentation];            
            if (mutableDict) {
                [self saveImageDataForCutout:cutout representation:mutableDict];
                [cutoutPhotosToSave addObject:mutableDict];
                [mutableDict release];
            }
        }
        ++i;
    }
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"Cutouts.plist"];
    [root writeToFile:plistPath atomically:YES];
}

#pragma mark -
#pragma mark DetailViewControllerDelegate

- (void)detailViewControllerDidShare:(DetailViewController *)detailVC {
    // Our cutout controller call back after sharing.
    [cutoutViewController share:self];
}

#pragma mark -
#pragma mark PhotoPickerControllerDelegate

- (void)photoPickerControllerDidCancel:(PhotoPickerViewController *)photoPickerController {
    if (photoPickerController.delegate == self) {
        photoPickerController.delegate = nil;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [detailViewController dismissModalViewControllerAnimated:YES];
    } else {
        [[self navigationController] dismissModalViewControllerAnimated:YES];
    }    
}

- (void)photoPickerController:(PhotoPickerViewController *)photoPickerController didFinishPickingImageAtIndex:(NSInteger)index {
    CutoutViewController *modalCutoutViewController = [[CutoutViewController alloc] initWithAddressBook:self.addressBook editable:YES];
    modalCutoutViewController.delegate = self;
    
    NSString *cutoutName = [cutoutNames objectAtIndex:index];
    UIImage *cutoutImage = [self transparentImageForPhotoName:cutoutName];
    modalCutoutViewController.cutoutImage = cutoutImage;
    modalCutoutViewController.personImage = nil;
    [modalCutoutViewController setPerson:NULL];
        
	[[photoPickerController navigationController] pushViewController:modalCutoutViewController animated:YES];
    [modalCutoutViewController release];
}

#pragma mark -
#pragma mark CutoutViewControllerDelegate

- (void)cutoutViewControllerDidCancel:(CutoutViewController *)cutoutVC {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[detailViewController dismissModalViewControllerAnimated:YES];
	} else {
		[[self navigationController] dismissModalViewControllerAnimated:YES];
	}
}

- (void)cutoutViewController:(CutoutViewController *)cutoutVC saveCutoutWithPerson:(ABRecordRef)person {
    Cutout *cutout = nil;
    NSIndexPath *indexPath = nil;
    BOOL shouldInsert = NO;
    if (cutoutVC == cutoutViewController) {
        // An existing cutout needs the updated person info.
        indexPath = [self selectedIndexPath];        
        cutout = [[self cutoutAtIndexPath:indexPath] retain];        
    } else {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:kCutoutsSavedIndex];
        cutout = [[Cutout alloc] init];
        // A new cutout needs the image data.
        UIImage *image = nil;
        UIImage *thumbnail = nil;
        [cutoutVC getCurrentImage:&image currentThumbnail:&thumbnail];
        [cutout setImage:image];
        [cutout setThumbnail:thumbnail];
        
        shouldInsert = YES;
    }
    
    [cutout setPerson:person];

    if (shouldInsert) {
        [[allCutoutPhotos objectAtIndex:indexPath.section] insertObject:cutout atIndex:indexPath.row];
    }
    
    // Now update the UI.
    [self.tableView reloadData];
    [self displayCutoutViewControllerAtIndexPath:indexPath animated:NO];

    if (cutoutVC != cutoutViewController) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
            [[self navigationController] dismissModalViewControllerAnimated:YES];
        } else {
			[detailViewController dismissModalViewControllerAnimated:YES];
		}
    }
    
    [cutout release];
    
    // Save entry point. 
    [self saveAllCutoutPhotos];
}

- (void)cutoutViewController:(CutoutViewController *)cutoutVC shareCutoutWithPerson:(ABRecordRef)person {    
    if ([MFMailComposeViewController canSendMail]) {
        Cutout *cutout = [self cutoutAtIndexPath:[self selectedIndexPath]];
        NSMutableDictionary *mutableDict = [cutout newDictionaryRepresentation];
        if (mutableDict) {
            [mutableDict removeObjectForKey:kCutoutPersonIDKey]; // Don't send the record ID.
            [mutableDict removeObjectForKey:kCutoutImageNameKey]; // Don't send along the image file name.

            [self shareCutoutRepresentation:mutableDict];
            [mutableDict release];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Mail Account" message:@"To share this Cutout, you need an email account set up. You can use the Mail app to set up an account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
    }
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	if (result == MFMailComposeResultFailed) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not Send Message" message:@"Please try again." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	[controller.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self refresh];
        if ([self hasData]) {
            NSIndexPath *indexPath = [self selectedIndexPath];
            if (!indexPath) {
                NSInteger section = ([self hasSavedData]) ? kCutoutsSavedIndex : kCutoutsReceievedIndex;
                indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            }
            if (indexPath) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
                [self displayCutoutViewControllerAtIndexPath:indexPath animated:NO];
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([self hasData]) {
		return 2;
	}
    return 1; // just the "no Cutouts" section
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if ([self hasData]) {
		if (section == 0) {
			return @"Saved";
		}
		if (section == 1) {
			return @"Received";
		}
	}
	return nil;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self hasData]) {
        return [[self.allCutoutPhotos objectAtIndex:section] count];
    } else {
        return 1; // just the "no Cutouts" section
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *cutoutIdentifier = @"CutoutCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cutoutIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cutoutIdentifier] autorelease];
	}
	
    if ([self hasData]) {
        Cutout *cutout = [self cutoutAtIndexPath:indexPath];
        ABRecordRef person = [cutout person];
        NSString *name = nil;
        if (person) {
            name = (NSString *)ABRecordCopyCompositeName(person);
        } else {
            name = @"No Name";
        }
        cell.textLabel.text = name;
        [name release];
        
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [cutout thumbnail];
    } else {
        cell.textLabel.text = @"No Cutouts";
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = nil;
    }

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 56;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self hasData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // If deleting the last cutout, revert to a table view that only shows "no Cutouts".
        NSUInteger savedCutouts = [tableView numberOfRowsInSection:kCutoutsSavedIndex];
        NSUInteger receivedCutouts = [tableView numberOfRowsInSection:kCutoutsReceievedIndex];
        BOOL isLastCutout = ([tableView numberOfRowsInSection:indexPath.section] == 1 &&
                             ((indexPath.section == kCutoutsSavedIndex && receivedCutouts == 0) ||
                              (indexPath.section == kCutoutsReceievedIndex && savedCutouts == 0)));

        [[allCutoutPhotos objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];

        if (isLastCutout) {
            [tableView reloadData];
        } else {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];            
        }
        
        // Deselect all.
        [self setSelectedIndexPath:nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            detailViewController.currentView = nil;
        }        
        
        [self saveAllCutoutPhotos];
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self hasData]) {
        [self displayCutoutViewControllerAtIndexPath:indexPath animated:YES];        
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Relinquish ownership any cached data, images, etc that aren't in use.
	if (allCutoutPhotos) {
		[allCutoutPhotos release];
		allCutoutPhotos = nil;
	}
}

#pragma mark -
#pragma mark Background Change Callbacks

- (void)updateCutoutsAndRefreshUI:(NSDictionary*)recordIDByCutout {
    for (Cutout *cutout in [recordIDByCutout allKeys]) {
        ABRecordID newRecordID = [[recordIDByCutout objectForKey:cutout] intValue];
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, newRecordID);
        if (person == NULL) {
            person = [Cutout newPersonWithCutout:cutout];
        } else {
            CFRetain(person);
        }
        cutout.person = person;
        CFRelease(person);
    }
    [self.tableView reloadData];
}

- (void)backgroundMatchAllCutouts:(NSArray*)cutouts {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    ABAddressBookRef ab = ABAddressBookCreate();
    NSMutableDictionary *recordIDByCutout = [NSMutableDictionary new];
    for (Cutout *cutout in cutouts) {
        ABRecordID recordID = [Cutout personRecordIDWithCutout:cutout inAddressBook:ab];
        [recordIDByCutout setObject:[NSNumber numberWithInt:recordID] forKey:cutout];
    }
    CFRelease(ab);
    [self performSelectorOnMainThread:@selector(updateCutoutsAndRefreshUI:) withObject:recordIDByCutout waitUntilDone:YES];
    [recordIDByCutout release];
    
    [pool release];
}

- (void)addressBookChanged:(ABAddressBookRef)ab {
    if ([self hasData]) {
        NSMutableArray *cutouts = [NSMutableArray array];
        
        [cutouts addObjectsFromArray:[allCutoutPhotos objectAtIndex:0]]; // the created cutouts
        [cutouts addObjectsFromArray:[allCutoutPhotos objectAtIndex:1]]; // the received cutouts
        
        [NSThread detachNewThreadSelector:@selector(backgroundMatchAllCutouts:) toTarget:self withObject:cutouts];
    }
}

void abChanged(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    [(GalleryViewController*)context addressBookChanged:addressBook];
}

@end
