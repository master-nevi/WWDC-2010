/*
     File: Cutout.h
 Abstract: Representation of an individual cutout; stores a person, an image and thumbnail thereof, and a filename for the image. Can fill itself from a saved dictionary and produce a dictionary for saving.
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

#import <AddressBook/AddressBook.h>

#define kCutoutPersonIDKey              @"recordID"
#define kCutoutPersonNameCompositeKey   @"personNameComposite"
#define kCutoutPersonNameFirstKey       @"personNameFirst"
#define kCutoutPersonNameLastKey        @"personNameLast"
#define kCutoutPersonEmailsKey          @"personEmails"

#define kCutoutImageDataKey             @"image"
#define kCutoutThumbnailDataKey         @"thumbnail"

#define kCutoutImageNameKey             @"imageName"


@interface Cutout : NSObject <NSCopying> {
@private
    ABRecordRef person;
    UIImage *image;
    UIImage *thumbnail;
    
    NSString *imageName;
    
    NSString *compositeName,
             *firstName,
             *lastName;
    NSArray  *emails;
}

@property (nonatomic, readonly) NSString *compositeName;
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSString *lastName;
@property (nonatomic, readonly) NSArray  *emails;

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, copy) NSString *imageName;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict addressBook:(ABAddressBookRef)addressBook;
    // The dictionary should contain key/value pairs as specified above.
    // This method attempts to re/establish the person instance variable using the address book and dictionary.

- (void)setPerson:(ABRecordRef)person;
- (ABRecordRef)person;

- (NSMutableDictionary *)newDictionaryRepresentation;
    // Creates a dictionary with the keys specified above.

+ (ABRecordID)personRecordIDWithCutout:(Cutout *)cutout inAddressBook:(ABAddressBookRef)addressBook;
+ (ABRecordRef)newPersonWithCutout:(Cutout *)cutout;

@end
