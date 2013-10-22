/*
     File: ReminderAnnotation.m
 Abstract: ReminderAnnotation implements MKOverlay protocol and is used as both an annotation and an overlay
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

#import "ReminderAnnotation.h"
#import "RegionManager.h"


@implementation ReminderAnnotation

@synthesize title, coordinate, radius;

- (id)initWithTitle:(NSString *)t coordinate:(CLLocationCoordinate2D)c radius:(CLLocationDistance)r {
	if ((self = [super init])) {
		self.title = t;
		self.coordinate = c;
		self.radius = r;
	}
	return self;
}

- (id)initWithRegion:(CLRegion *)region {
	if ((self = [self init])) {
		self.region = region;
	}
	return self;
}

+ (id)reminderWithRegion:(CLRegion *)region {
	return [[[[self class] alloc] initWithRegion:region] autorelease];
}

+ (id)reminderWithCoordinate:(CLLocationCoordinate2D)c {
	return [[[[self class] alloc] initWithTitle:@"New Reminder" // can't be nil
									 coordinate:c
										 radius:[[RegionManager sharedInstance] minDistance]]
			autorelease];
}

- (CLRegion *)region {
	CLRegion *region = [[[CLRegion alloc] initCircularRegionWithCenter:self.coordinate
																radius:self.radius
															identifier:self.title] autorelease];
	return region;
}

- (void)setRegion:(CLRegion *)region {
	self.title = region.identifier;
	self.coordinate = region.center;
	self.radius = region.radius;
}

- (MKMapRect)boundingMapRect {
	// the overlay can move and grow based on user interaction, thus our bounds are potentially limitless
	// be aware that this has performance implications
	return MKMapRectWorld;
}

@end