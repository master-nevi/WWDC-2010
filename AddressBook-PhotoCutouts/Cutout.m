/*
     File: Cutout.m
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

#import "Cutout.h"

@interface Cutout (Private)

+ (ABRecordRef)copyPersonMatchingName:(NSString *)name emails:(NSArray *)emails inAddressBook:(ABAddressBookRef)addressBook;
+ (ABRecordRef)newPersonWithFirstName:(NSString *)first lastName:(NSString *)last emails:(NSArray*)emails;

@end


@implementation Cutout

+ (ABRecordID)personRecordIDWithCutout:(Cutout *)cutout inAddressBook:(ABAddressBookRef)addressBook {
    ABRecordRef person = [Cutout copyPersonMatchingName:cutout.compositeName emails:cutout.emails inAddressBook:addressBook];
    ABRecordID recordID = kABRecordInvalidID;
    if (person) {
        recordID = ABRecordGetRecordID(person);
        CFRelease(person);
    }
    
    return recordID;
}

+ (ABRecordRef)newPersonWithCutout:(Cutout *)cutout {
    return [self newPersonWithFirstName:cutout.firstName lastName:cutout.lastName emails:cutout.emails];
}

+ (ABRecordRef)copyPersonMatchingName:(NSString *)name emails:(NSArray *)emails inAddressBook:(ABAddressBookRef)addressBook {
    ABRecordRef foundPerson = NULL;
    CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook, (CFStringRef)name);
    if (people) {
        CFIndex count = CFArrayGetCount(people);
        if (count == 1) {
            foundPerson = (ABRecordRef)CFArrayGetValueAtIndex(people, 0);
        } else if (count > 1) {
            for (CFIndex i = 0; i < count && !foundPerson; i++) {
                ABRecordRef somePerson = (ABRecordRef)CFArrayGetValueAtIndex(people, i);
                ABMultiValueRef multiValue = ABRecordCopyValue(somePerson, kABPersonEmailProperty);
                if (multiValue) {
                    NSArray *values = (NSArray *)ABMultiValueCopyArrayOfAllValues(multiValue);
                    for (NSString *email in values) {
                        if ([emails containsObject:email]) {
                            foundPerson = somePerson;
                            break;
                        }
                    }
                    [values release];
                    CFRelease(multiValue);
                }
            }
            if (foundPerson == NULL) {
                foundPerson = CFArrayGetValueAtIndex(people, 0);
            }
        }
        if (foundPerson) {
            CFRetain(foundPerson);
        }
        CFRelease(people);
    }
    
    return foundPerson;
}

+ (ABRecordRef)newPersonWithFirstName:(NSString *)firstName lastName:(NSString *)lastName emails:(NSArray*)emails {
    ABRecordRef newPerson = ABPersonCreate();
    
    ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (CFStringRef)firstName, NULL);
    ABRecordSetValue(newPerson, kABPersonLastNameProperty, (CFStringRef)lastName, NULL);
    
    ABMutableMultiValueRef mmv = ABMultiValueCreateMutable(kABStringPropertyType);
    for (NSString *email in emails) {
        ABMultiValueAddValueAndLabel(mmv, (CFStringRef)email, kABHomeLabel, NULL);
    }
    ABRecordSetValue(newPerson, kABPersonEmailProperty, mmv, NULL);
    CFRelease(mmv);
    
    return newPerson;
}

@synthesize image, thumbnail, imageName, compositeName, firstName, lastName, emails;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict addressBook:(ABAddressBookRef)addressBook {
    self = [super init];
    if (self) {
        ABRecordRef p = NULL;
        NSNumber *recordNumber = [dict valueForKey:kCutoutPersonIDKey];
        if (recordNumber) {
            ABRecordID recordID = [recordNumber intValue];
            p = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
            if (p) {
                CFRetain(p);
            }
        } else {
            NSString *theCompositeName = [dict valueForKey:kCutoutPersonNameCompositeKey];
            NSArray *theEmails = [dict valueForKey:kCutoutPersonEmailsKey];
            p = [Cutout copyPersonMatchingName:theCompositeName emails:theEmails inAddressBook:addressBook];
        }
        
        if (p == NULL) {
            NSString *newFirstName = [dict valueForKey:kCutoutPersonNameFirstKey];
            NSString *newLastName = [dict valueForKey:kCutoutPersonNameLastKey];
            NSArray *newEmails = [dict valueForKey:kCutoutPersonEmailsKey];
            p = [Cutout newPersonWithFirstName:newFirstName lastName:newLastName emails:newEmails];
        }
        
        self.person = p;
        if (p) {
            CFRelease(p);
        }
        
        NSData *imageData = [dict valueForKey:kCutoutImageDataKey];
        NSData *thumbnailImageData = [dict valueForKey:kCutoutThumbnailDataKey];
        
        if (imageData && thumbnailImageData) {
            self.image = [UIImage imageWithData:imageData];
            self.thumbnail = [UIImage imageWithData:thumbnailImageData];
        } else {        
            NSString *anImageName = [dict valueForKey:kCutoutImageNameKey];
            self.imageName = anImageName;
        }
    }
    
    return self;
}

- (void)setPerson:(ABRecordRef)aPerson {
    if (person != aPerson) {
        NSString *newComposite = nil;
        NSString *newFirst = nil;
        NSString *newLast = nil;
        NSArray  *newEmails = nil;
        
        if (person) {
            CFRelease(person);
        }
        if (aPerson) {
            CFRetain(aPerson);
            newComposite = (NSString*)ABRecordCopyCompositeName(aPerson);
            newFirst = (NSString*)ABRecordCopyValue(aPerson, kABPersonFirstNameProperty);
            newLast = (NSString*)ABRecordCopyValue(aPerson, kABPersonLastNameProperty);

            ABMultiValueRef multiValue = ABRecordCopyValue(aPerson, kABPersonEmailProperty);
            if (multiValue) {
                newEmails = (NSArray *)ABMultiValueCopyArrayOfAllValues(multiValue);
                CFRelease(multiValue);
            }
        }
        
        [compositeName release];
        compositeName = newComposite;
        [firstName release];
        firstName = newFirst;
        [lastName release];
        lastName = newLast;
        [emails release];
        emails = newEmails;
        
        person = aPerson;
    }
}

- (ABRecordRef)person {
    return person;
}

- (void)setImage:(UIImage *)anImage {
    if (image != anImage) {
        [image release];
        image = [anImage retain];
    }
}

- (void)setThumbnail:(UIImage *)aThumbnail {
    if (thumbnail != aThumbnail) {
        [thumbnail release];
        thumbnail = [aThumbnail retain];
    }
}

- (void)dealloc {
    if (person) {
        CFRelease(person);
    }
    [image release];
    [thumbnail release];
    
    [imageName release];
    [compositeName release];
    [firstName release];
    [lastName release];
    [emails release];
    
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    // we'll treat ourselves as immutable objects
    return [self retain];
}

- (NSMutableDictionary *)newDictionaryRepresentation {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    ABRecordID recordID = ABRecordGetRecordID(person);
    NSNumber *recordNumber = [NSNumber numberWithInt:recordID];
    [dict setValue:recordNumber forKey:kCutoutPersonIDKey];
    
    NSString *theCompositeName = [(NSString *)ABRecordCopyCompositeName(person) autorelease];		   
    if (theCompositeName) {
        [dict setValue:theCompositeName forKey:kCutoutPersonNameCompositeKey];
    }
    
    NSString *theFirstName = [(NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty) autorelease];
    if (theFirstName) {
        [dict setValue:theFirstName forKey:kCutoutPersonNameFirstKey];
    }
    NSString *theLastName = [(NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty) autorelease];
    if (theLastName) {
        [dict setValue:theLastName forKey:kCutoutPersonNameLastKey];
    }
    
    NSMutableArray *theEmails = [NSMutableArray array];
    NSArray *linkedPeople = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 4.0) {
        linkedPeople = [(NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person) autorelease];
    } else {
        linkedPeople = [NSArray arrayWithObject:(id)person];
    }
    for (id object in linkedPeople) {
		ABRecordRef linkedPerson = (ABRecordRef)object;
		ABMultiValueRef mv = ABRecordCopyValue(linkedPerson, kABPersonEmailProperty);
		if (mv) {
            NSArray *linkedEmails = (NSArray *)ABMultiValueCopyArrayOfAllValues(mv);
			[theEmails addObjectsFromArray:linkedEmails];
            [linkedEmails release];
            CFRelease(mv);
        }
	}
    if (theEmails) {
        [dict setValue:theEmails forKey:kCutoutPersonEmailsKey];
    }
    
    if (image) {
        NSData *imageData = UIImagePNGRepresentation(image);
        [dict setValue:imageData forKey:kCutoutImageDataKey];
    }

    if (thumbnail) {
        NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnail);
        [dict setValue:thumbnailImageData forKey:kCutoutThumbnailDataKey];
    }
    
    if (imageName) {
        [dict setValue:imageName forKey:kCutoutImageNameKey];
    }

    return dict;
}

@end
