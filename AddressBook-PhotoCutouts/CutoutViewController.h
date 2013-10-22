/*
     File: CutoutViewController.h
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

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

#import "PhotoPickerViewController.h"

@protocol CutoutViewControllerDelegate;
@class CutoutView;

@interface CutoutViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate, ABUnknownPersonViewControllerDelegate, PhotoPickerControllerDelegate, UIPopoverControllerDelegate> {
@private
	UIPopoverController *popoverController;
	
	UIImage *cutoutImage;
	UIImage *personImage;
	
    ABAddressBookRef addressBook;
    ABRecordRef personForPhoto;
	
	id <CutoutViewControllerDelegate> delegate;
    
    BOOL editable;
}

@property (nonatomic, assign) id <CutoutViewControllerDelegate> delegate;
@property (nonatomic, retain) UIImage *cutoutImage;
@property (nonatomic, retain) UIImage *personImage;

- (id)initWithAddressBook:(ABAddressBookRef)book editable:(BOOL)isEditable;

- (void)setPerson:(ABRecordRef)person;
- (ABRecordRef)person;

- (void)save:(id)sender;
- (void)share:(id)sender;

- (void)getCurrentImage:(UIImage **)outImage currentThumbnail:(UIImage **)outThumbnail;

- (IBAction)photoTapped:(id)sender;

@end


@protocol CutoutViewControllerDelegate <NSObject>

- (void)cutoutViewControllerDidCancel:(CutoutViewController *)cutoutViewController;
- (void)cutoutViewController:(CutoutViewController *)cutoutViewController saveCutoutWithPerson:(ABRecordRef)person;
- (void)cutoutViewController:(CutoutViewController *)cutoutViewController shareCutoutWithPerson:(ABRecordRef)person;

@end
