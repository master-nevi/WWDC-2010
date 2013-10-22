/*
     File: RemindersViewController.m
 Abstract: The main view controller consisting primarily of an MKMapView overlaid with annotations
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

#import "RemindersViewController.h"
#import "RegionManager.h"
#import "ReminderAnnotation.h"
#import "ReminderCircleView.h"


#define ENTER_METHOD NSLog(@"Entered %s", __func__)

@interface RemindersViewController ()

@end


@implementation RemindersViewController

@synthesize mapView, locateUserButton, showListButton, addRegionButton, draggingPin;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (![CLLocationManager regionMonitoringAvailable]) {
		addRegionButton.enabled = NO;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Unsupported" message: @"Sorry, this device cannot create GeoFence reminders." delegate:self cancelButtonTitle: @"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
	goToUserLocation = YES;
	
	mapView.delegate = self;
	mapView.showsUserLocation = YES;
	
	NSSet *regions = [[RegionManager sharedInstance] regions];
	for (CLRegion *region in regions) {
		ReminderAnnotation *reminder = [ReminderAnnotation reminderWithRegion:region];
		[self addAnnotation:reminder];
	}
}

- (void)didReceiveMemoryWarning {
	NSLog(@"didReceiveMemoryWarning");
//    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[self.mapView removeAnnotations:self.mapView.annotations];
	[self.mapView removeOverlays:self.mapView.overlays];
}

- (void)dealloc {
	self.mapView =nil;
	self.locateUserButton = nil;
	self.showListButton = nil;
	self.addRegionButton = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	BOOL result = YES;
	if (self.draggingPin) {
		result = NO; // don't autorotate while dragging a pin
	}
	return result;
}

- (IBAction)locateUser:(id)sender
{
	mapView.showsUserLocation = NO;
	goToUserLocation = YES;
	mapView.showsUserLocation = YES;
}

- (IBAction)addRegion:(id)sender {
	ReminderAnnotation *reminder = [ReminderAnnotation reminderWithCoordinate:mapView.centerCoordinate];
	[self addAnnotation:reminder];
	
	[[RegionManager sharedInstance] addRegion:reminder.region];
}

- (void)addAnnotation:(id <MKAnnotation>)annotation {
	// Reminders must have unique titles, remove any existing ones with the same title
	NSMutableArray *replaced = [NSMutableArray array];
	for (id <MKAnnotation> a in mapView.annotations) {
		if ([a isKindOfClass:[ReminderAnnotation class]]) {
			if ([a.title isEqualToString:annotation.title]) {
				[replaced addObject:a];
			}
		}
	}
	
	[mapView removeAnnotations:replaced];
	[mapView removeOverlays:replaced];
	
	[mapView addAnnotation:annotation];
	if ([annotation isKindOfClass:[ReminderAnnotation class]]) {
		[mapView addOverlay:(ReminderAnnotation *)annotation];
	}
}

- (void)removeAnnotation:(id <MKAnnotation>)annotation {
	[mapView removeAnnotation:annotation];
	if ([annotation isKindOfClass:[ReminderAnnotation class]]) {
		[mapView removeOverlay:(ReminderAnnotation *)annotation];
	}
}

#pragma mark -
#pragma mark ReminderAnnotationDetailDelegate
- (void)reminderAnnotationDetailDidFinish:(ReminderAnnotationDetail *)detail withAction:(ReminderAnnotationDetailAction)action {
	switch (action) {
		case ReminderAnnotationDetailActionSave:
			[[RegionManager sharedInstance] removeRegion:detail.originalRegion];
			[[RegionManager sharedInstance] addRegion:detail.reminder.region];
			break;
		case ReminderAnnotationDetailActionRemove:
			[self removeAnnotation:detail.reminder];
			[[RegionManager sharedInstance] removeRegion:detail.reminder.region];
			break;
		case ReminderAnnotationDetailActionCancel:
		default:
			break;
	}
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark MKMapViewDelegate
//
//- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView {
//	NSLog(@"mapViewWillStartLocatingUser");
//}
//- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView {
//	NSLog(@"mapViewDidStopLocatingUser");
//}
- (void)mapView:(MKMapView *)map didUpdateUserLocation:(MKUserLocation *)userLocation {
	if (goToUserLocation && userLocation.location.horizontalAccuracy < 150 && userLocation.location.horizontalAccuracy > 0) {
		MKCoordinateRegion region;
		region.center=userLocation.location.coordinate;
		
		MKCoordinateSpan span = {0.005, 0.005};
		region.span=span;
		
		[mapView setRegion:region animated:YES];
		goToUserLocation = NO;
	}
}
- (void)mapView:(MKMapView *)map didFailToLocateUserWithError:(NSError *)error {
	goToUserLocation = NO;
	NSLog(@"didFailToLocateUserWithError: %@", error);
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation {
	static NSString * const kReminderAnnotationId = @"ReminderAnnotation";
	
	MKPinAnnotationView *annotationView = nil;
	if ([annotation isKindOfClass:[ReminderAnnotation class]])
	{
		annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:kReminderAnnotationId];
		if (annotationView == nil)
		{
			annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kReminderAnnotationId] autorelease];
			annotationView.canShowCallout = YES;
			annotationView.animatesDrop = YES;
			annotationView.draggable = YES;
			annotationView.rightCalloutAccessoryView=[UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		}
	}
	return annotationView;
}

// mapView:didAddAnnotationViews: is called after the annotation views have been added and positioned in the map.
// The delegate can implement this method to animate the adding of the annotations views.
// Use the current positions of the annotation views as the destinations of the animation.
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
	ENTER_METHOD;
}

// mapView:annotationView:calloutAccessoryControlTapped: is called when the user taps on left & right callout accessory UIControls.
- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)view
	calloutAccessoryControlTapped:(UIControl *)control {
	if ([view.annotation isKindOfClass:[ReminderAnnotation class]]) {
		ReminderAnnotationDetail *controller = [[ReminderAnnotationDetail alloc] initWithNibName:@"ReminderAnnotationDetail" bundle:nil];
		controller.delegate = self;
		controller.reminder = (ReminderAnnotation *)view.annotation;
		
		controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;//UIModalTransitionStyleFlipHorizontal;
		[self presentModalViewController:controller animated:YES];
    
		[controller release];
	}
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	MKOverlayView *result = nil;
	if ([overlay isKindOfClass:[ReminderAnnotation class]]) {
		result = [[[ReminderCircleView alloc] initWithReminder:(ReminderAnnotation *)overlay] autorelease];
		[(MKOverlayPathView *)result setFillColor:[[UIColor blueColor] colorWithAlphaComponent:0.2]];
		[(MKOverlayPathView *)result setStrokeColor:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
		[(MKOverlayPathView *)result setLineWidth:2.0];
	} else if ([overlay isKindOfClass:[MKCircle class]]) {
		result = [[[MKCircleView alloc] initWithCircle:(MKCircle *)overlay] autorelease];
		[(MKOverlayPathView *)result setFillColor:[[UIColor purpleColor] colorWithAlphaComponent:0.3]];
	}
	return result;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	ENTER_METHOD;
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
	ENTER_METHOD;
}
- (void)mapView:(MKMapView *)map
 annotationView:(MKAnnotationView *)view
	didChangeDragState:(MKAnnotationViewDragState)newState 
   fromOldState:(MKAnnotationViewDragState)oldState {
	switch (newState) {
		case MKAnnotationViewDragStateNone:
			self.draggingPin = NO;
			if ([view.annotation isKindOfClass:[ReminderAnnotation class]]) {
				ReminderAnnotation *reminder = (ReminderAnnotation *)view.annotation;
				[[RegionManager sharedInstance] addRegion:reminder.region];
			 }
			break;
		case MKAnnotationViewDragStateStarting:
			self.draggingPin = YES;
		case MKAnnotationViewDragStateDragging:
		case MKAnnotationViewDragStateCanceling:
		case MKAnnotationViewDragStateEnding:
			if (!self.draggingPin) {
				// if we're here, we didn't get a start event, something is screwy
				self.draggingPin = YES;
				NSLog(@"Warning: we changed dragState to %s passing through MKAnnotationViewDragStateStarting first",
					  MKAnnotationViewDragStateDragging==newState?"MKAnnotationViewDragStateDragging":
					  MKAnnotationViewDragStateCanceling==newState?"MKAnnotationViewDragStateCanceling":
					  MKAnnotationViewDragStateEnding==newState?"MKAnnotationViewDragStateEnding":
					  "whoops");
			}
			break;
	}
}

@end
