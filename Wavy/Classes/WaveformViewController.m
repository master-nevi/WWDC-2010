/*
    File: WaveformViewController.m
Abstract: Draws audio sample values.
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


#import "WaveformViewController.h"
#import "WavyAppDelegate.h"

#define kSegmentLayerHeight 280
#define kSegmentInitialPosition CGPointMake(-16, (kSegmentLayerHeight / 2) - 5) 


@interface WaveformSegment : NSObject {
	CALayer *layer;
	
	double xhistory[33];
	double yhistory[33];
	double zhistory[33];
	
	int index;
}

// Returns true if adding this value fills the segment, which is necessary for properly updating the segments
-(BOOL)addX:(double)x;

// Prepares segment for reuse
-(void)reset;

// Returns true if segment has consumed 32 values.
-(BOOL)isFull;

// Returns true if segment's layer is visible in the given rect
-(BOOL)isVisibleInRect:(CGRect)r;


@property(nonatomic, readonly) CALayer *layer;


@end


@implementation WaveformSegment


@synthesize layer;


-(id)init {
	
	self = [super init];
	if(self != nil)
	{
		layer = [[CALayer alloc] init];
		layer.delegate = self;
		layer.bounds = CGRectMake(0.0, -150, 32.0, 300.0);
		layer.opaque = NO;
		
		// Index represents how many slots are left to be filled in the graph, which is also +1 compared to the array index that a new entry will be added
		index = 33;
	}
	return self;
}

-(void)dealloc {
	[layer release];
	[super dealloc];
}

-(void)reset {
	
	// Clear out our components and reset the index to 33 to start filling values again...
	memset(xhistory, 0, sizeof(xhistory));
	memset(yhistory, 0, sizeof(yhistory));
	memset(zhistory, 0, sizeof(zhistory));
	index = 33;
	
	[layer setNeedsDisplay];
}


-(BOOL)isFull {
	return index == 0;
}


-(BOOL)isVisibleInRect:(CGRect)r {
	// Just check if there is an intersection between the layer's frame and the given rect.
	return CGRectIntersectsRect(r, layer.frame);
}


-(BOOL)addX:(double)x {	
	
	// If this segment is not full, then we add a new value to the history
	if(index > 0)
	{
		// First decrement, both to get to a zero-based index and to flag one fewer position left
		--index;
		xhistory[index] = x;
		
		[layer setNeedsDisplay];
	}
	
	// And return whether we are now full or not (really just avoids needing to call isFull after adding a value).
	return index == 0;
}

-(void)drawLayer:(CALayer*)l inContext:(CGContextRef)context {
	static int count = 0;
	count++;
	
	CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
	
	CGContextFillRect(context, layer.bounds);
	
	CGPoint lines[64];
	int i;
	
	for(i = 0; i < 32; ++i) {
		lines[i * 2].x = i;
		lines[i * 2].y = xhistory[i];

		lines[i * 2 + 1].x = i + 1;
		lines[i * 2 + 1].y = -xhistory[i];
	}
	
	CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
	CGContextStrokeLineSegments(context, lines, 64);
}

-(id)actionForLayer:(CALayer *)layer forKey :(NSString *)key {
	return [NSNull null]; // Disable all actions
}

@end


@implementation WaveformViewController

@synthesize recordButton;


#pragma mark Waveform Drawing

-(void)addX:(double)x {
	
	double multiplier = (kSegmentLayerHeight / 2) * 0.9;
	
	// Add the new value to the current segment
	if( [current addX:x * multiplier] ) {
		// If we've filled up the current segment, then we need to determine the next current segment
		[self recycleSegment];
		
		// To keep the graph continuous, we add the value to the new segment as well
		[current addX:x * multiplier];
	}

	// Advance x-position of segment layers
	for(WaveformSegment *s in segments) {
		CGPoint newPosition = s.layer.position;
		newPosition.x += 1.0;
		s.layer.position = newPosition;
	}
}


- (CGPoint)initialPosition {
	CGPoint point = CGPointMake(-16, CGRectGetMaxY(self.view.bounds) / 2);
	return point;
}

-(WaveformSegment*)addSegment {
	
	WaveformSegment * segment = [[WaveformSegment alloc] init];
	
	// Add new segment at the front of the array because -recycleSegment expects the oldest segment to be at the end of the array. 
	// As long as we always insert the youngest segment at the front this will be true.
	[segments insertObject:segment atIndex:0];
	[segment release]; // this is now a weak reference
	
	// Ensure that newly added segment layers are placed after the text view's layer so that the text view always renders above the segment layer.
	[self.view.layer addSublayer:segment.layer];
	
	segment.layer.position = kSegmentInitialPosition;
	
	return segment;
}


-(void)recycleSegment {
	
	// We start with the last object in the segments array, as it should either be visible onscreen,
	// which indicates that we need more segments, or pushed offscreen which makes it eligible for recycling.
	WaveformSegment *last = [segments lastObject];
	if([last isVisibleInRect:self.view.layer.bounds]) {
		// The last segment is still visible, so create a new segment, which is now the current segment
		current = [self addSegment];
	}
	else {
		// The last segment is no longer visible, so we reset it in preperation for recycling
		[last reset];
		
		// Position it properly (see the comment for kSegmentInitialPosition)
		last.layer.position = kSegmentInitialPosition;
		
		// Move the segment from the last position in the array to the first position in the array as it is now the youngest segment.
		[segments insertObject:last atIndex:0];
		[segments removeLastObject];
		
		// And make it our current segment
		current = last;
	}
}


#pragma mark Actions

- (IBAction)toggleRecording:(id)sender {    
	
	UIBarItem *button = (UIBarItem *)sender;
	
	WavyAppDelegate *appDelegate = (WavyAppDelegate*) [[UIApplication sharedApplication] delegate];
	if ([appDelegate.captureManager isRunning]) {
		[button setTitle:@"Start"];
		[appDelegate.captureManager stopSession];
	}
	else {
		[button setTitle:@"Stop"];
		[appDelegate.captureManager startSession];
	}
}


#pragma mark ViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)viewWillAppear:(BOOL)animated {
	
	segments = [[NSMutableArray alloc] init];
	current = [self addSegment];
}	


- (void)viewWillDisappear:(BOOL)animated {
}


- (void)viewDidLoad {

	// Set up background gradient
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
	gradientLayer.bounds = CGRectMake(0.0, 0.0, self.view.layer.bounds.size.height, self.view.layer.bounds.size.width); // Switch width and height for landscape
    gradientLayer.position = CGPointMake(self.view.bounds.size.height / 2, self.view.bounds.size.width / 2); // Switch width and height for landscape
	gradientLayer.colors = [NSArray arrayWithObjects:
							(id)[[UIColor grayColor] CGColor], 
							(id)[[UIColor blackColor] CGColor], 
							(id)[[UIColor grayColor] CGColor], 
							nil];
    [[self.view layer] insertSublayer:gradientLayer atIndex:0];
    [gradientLayer release];
 
	[super viewDidLoad];
}

@end
