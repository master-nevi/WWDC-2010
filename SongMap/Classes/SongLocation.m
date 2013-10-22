/*
     File: SongLocation.m
 Abstract: SongLocation is a simple NSManagedObject subclass that provides a few utility methods as well as type checking.
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

#import "SongLocation.h"


@implementation SongLocation 

@dynamic location;
@dynamic timestamp;
@dynamic song;

- (CLLocationCoordinate2D)coordinate
{
	return self.location.coordinate;
}

- (UIImage *)artworkImageWithSize:(CGSize)size
{
	MPMediaItemArtwork *artwork = [self.song valueForProperty:MPMediaItemPropertyArtwork];
	
	if (CGSizeEqualToSize(size,CGSizeZero)) {
		size = artwork.bounds.size;
	}
	
	UIImage *artworkImage =	[artwork imageWithSize:size];
	return artworkImage;
}

- (NSString *)title
{
	NSString *title = [NSDateFormatter localizedStringFromDate:self.timestamp
													 dateStyle:kCFDateFormatterShortStyle
													 timeStyle:kCFDateFormatterLongStyle];
	return title;
}

- (NSString *)subtitle
{
	NSString *subtitle = nil;
	MPMediaItem *song = self.song;
	if (song) {
		subtitle = [song valueForProperty:MPMediaItemPropertyTitle];
	} else {
		subtitle = [NSString stringWithFormat:@"%f, %f\n",
					self.location.coordinate.latitude,
					self.location.coordinate.longitude];
	}
	return subtitle;
}

+ (SongLocation *)insertNewSong:(MPMediaItem *)song
					   location:(CLLocation *)location
		 inManagedObjectContext:(NSManagedObjectContext *)context
{
	SongLocation *newSonglocation = [NSEntityDescription
									 insertNewObjectForEntityForName:@"SongLocation"
									 inManagedObjectContext:context];
	newSonglocation.location = location;
	newSonglocation.song = song;
	newSonglocation.timestamp = location.timestamp;
	return newSonglocation;
}

+ (NSArray *)fetchRecentLimit:(NSUInteger)limit inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError **)error
{
	NSArray *result = nil;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"SongLocation"
										inManagedObjectContext:context]];
	NSMutableArray *sortDescriptors = [NSMutableArray array];
    [sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO] autorelease]];
    [fetchRequest setSortDescriptors:sortDescriptors];
	[fetchRequest setFetchLimit:limit];
	
	result = [context executeFetchRequest:fetchRequest error:error];
	[fetchRequest release];
	return result;
}

@end
