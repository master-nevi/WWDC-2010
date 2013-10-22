/*
    File: MainViewController.m
Abstract: This controller manages the primary view. It is responsible for monitoring changes to the managed object context, adding additional annotations, and returning annotation views to the map view for display.
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


#import "MainViewController.h"
#import "SongLocation.h"

@implementation MainViewController

//@synthesize managedObjectContext=managedObjectContext;
@synthesize mapView=mapView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    MKCoordinateRegion newRegion;
    newRegion.center.latitude = 37.332170;
    newRegion.center.longitude = -122.030598;
    newRegion.span.latitudeDelta = 0.014203;
    newRegion.span.longitudeDelta = 0.013741;
	[self.mapView setRegion:newRegion animated:NO];
	
	NSError *error = nil;
	NSArray *newAnnotations = [SongLocation fetchRecentLimit:20 inManagedObjectContext:self.managedObjectContext error:&error];
	[self addAnnotations:newAnnotations];
}


 // Implement viewWillAppear: to do additional setup before the view is presented. You might, for example, fetch objects from the managed object context if necessary.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"LaunchedPreviously"]) {
		[self performSelector:@selector(showInfo:) withObject:self afterDelay:1.0];
	}
}


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"LaunchedPreviously"];
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    controller.delegate = self;
    
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [managedObjectContext release];
    [super dealloc];
}


#pragma mark -
#pragma mark MKMapViewDelegate
// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *annotationViewID = @"SongLocation";
	
    MKPinAnnotationView *annotationView =
	(MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationViewID];
    if (annotationView == nil)
    {
        annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationViewID] autorelease];
		annotationView.canShowCallout = YES;
    }
    
	UIImage *albumIcon = nil;
	if ([(SongLocation *)annotation song]) {
		albumIcon = [(SongLocation *)annotation artworkImageWithSize:CGSizeMake(32.f, 32.f)];
		if (!albumIcon) {
			albumIcon = [UIImage imageNamed:@"noArtwork.png"];
		}
	} else {
		albumIcon = [UIImage imageNamed:@"noMedia.png"];
	}
	
	annotationView.image = albumIcon;
    
    return annotationView;
}

- (NSManagedObjectContext *)managedObjectContext
{
	return managedObjectContext;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)context
{
	if (managedObjectContext != context) {
		// we must remember to remove our old observer if we have one
		if (managedObjectContext)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:managedObjectContext];
			[managedObjectContext release];
		}
		
		managedObjectContext = [context retain];
		
		// register the new observer, unless assigning nil
		if (context)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(managedObjectContextDidSave:)
														 name:NSManagedObjectContextDidSaveNotification
													   object:managedObjectContext];
		}
	}
}

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
	NSDictionary *info = [notification userInfo];
	
	NSArray *deleted = [[info valueForKey:NSDeletedObjectsKey] allObjects];
	NSArray *inserted = [[info valueForKey:NSInsertedObjectsKey] allObjects];
	
	if (deleted) {
		[self.mapView removeAnnotations:deleted];
	}
	if (inserted) {
		[self addAnnotations:inserted];
	}
}

- (void)addAnnotations:(NSArray *)annotations {
	MKCoordinateRegion newRegion;
    newRegion.span.latitudeDelta = 0.014203;
    newRegion.span.longitudeDelta = 0.013741;
	
	if ([annotations count] > 0) {
		SongLocation *sl = [annotations objectAtIndex:0];
		newRegion.center = sl.location.coordinate;
		[self.mapView setRegion:newRegion animated:YES];
		[mapView addAnnotations:annotations];
	}
}
@end
