//     File: BreadcrumbViewController.m
// Abstract: 
//     Main view controller for the application.  Displays the user location along with the path traveled on an MKMapView.  Implements the MKMapViewDelegate messages for tracking user location and managing overlays.
//   
//  Version: 1.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2010 Apple Inc. All Rights Reserved.
// 

#import "BreadcrumbViewController.h"

@implementation BreadcrumbViewController

// This delegate message is sent from MKMapView when the MKUserLocation annotation
// updates.  As the MKUserLocation annotation is fixed in place in the simulator
// this sample is only useful when run on a device that is in motion.
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocation *location = userLocation.location;
    if (location) {
        if (!crumbs) {
            // This is the first time we're getting a location update, so create
            // the CrumbPath and add it to the map.
            crumbs = [[CrumbPath alloc] initWithCenterCoordinate:location.coordinate];
            [map addOverlay:crumbs];
            
            // On the first location update only, zoom map to user location
            MKCoordinateRegion region = 
                MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                   2000,
                                                   2000);
            [map setRegion:region animated:YES];
        } else {
            // This is a subsequent location update.  If the crumbs MKOverlay
            // model object determines that the current location has moved
            // far enough from the previous location, use the returned updateRect
            // to redraw just the changed area.
            MKMapRect updateRect = [crumbs addCoordinate:location.coordinate];
            if (!MKMapRectIsNull(updateRect)) {
                // There is a non null update rect.
                // Compute the currently visible map zoom scale
                MKZoomScale currentZoomScale = map.bounds.size.width / map.visibleMapRect.size.width;
                // Find out the line width at this zoom scale and outset the updateRect by that amount
                CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                // Ask the overlay view to update just the changed area.
                [crumbView setNeedsDisplayInMapRect:updateRect];
            }
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if (!crumbView) {
        crumbView = [[CrumbPathView alloc] initWithOverlay:overlay];
    }
    return crumbView;
}


- (void)dealloc
{
    [crumbView release];
    [crumbs release];
    [super dealloc];
}

@end
