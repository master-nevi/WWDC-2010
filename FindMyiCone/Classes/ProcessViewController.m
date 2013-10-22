/*
    File: ProcessViewController.m
Abstract: Controls display of video preview, color recognition rectangle, and settings controls.
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

#import "ProcessViewController.h"

#define RECT_UPDATE_INTERVAL 0.02


@implementation ProcessViewController

@synthesize captureManager;
@synthesize overlayLayer;


- (IBAction)showSettingsUI:(id)sender {
	
	for (UIControl *control in settingsUIItems)
		if (control)
            [control setHidden:NO];
}


- (IBAction)hideSettingsUI:(id)sender {
	
	for (UIControl *control in settingsUIItems)
		if (control)
            [control setHidden:YES];
}


- (IBAction) updateRedrawDelta:(id)sender {
	redrawDelta = (uint)[(UISlider *)sender value];
	[redrawDeltaValueLabel setText:[NSString stringWithFormat:@"%u", redrawDelta]];
}


- (IBAction) updateThreshold:(id)sender {
	captureManager.matchThreshold = (uint)[(UISlider *)sender value];
	[thresholdValueLabel setText:[NSString stringWithFormat:@"%u", captureManager.matchThreshold]];
}


- (IBAction) updateRecognitionMatches:(id)sender {
	captureManager.matchesForRecognition = (uint)[(UISlider *)sender value];
	[recognitionMatchesValueLabel setText:[NSString stringWithFormat:@"%u", captureManager.matchesForRecognition]];
}


- (void) updateRecognitionRect {
	
	// Speed up animations
	[CATransaction setValue:[NSNumber numberWithFloat:RECT_UPDATE_INTERVAL * 0.4]
					 forKey:kCATransactionAnimationDuration]; 
	
//	// Disable animations
//	[CATransaction setValue:(id)kCFBooleanTrue
//					 forKey:kCATransactionDisableActions];
	
	CGRect newRect = captureManager.recognizedRect;
	if (captureManager.foundColor) {
		
		// Only move rect for significant changes
		int delta = abs(overlayLayer.frame.origin.x - newRect.origin.x) + abs(overlayLayer.frame.origin.y - newRect.origin.y);
		if (delta > redrawDelta) {
			//overlayLayer.frame = captureManager.recognizedRect;
			overlayLayer.frame = newRect;
		}
		overlayLayer.hidden = NO;
	}
	else {
		overlayLayer.hidden = YES;
	}
	
	[numFoundLabel setText:[NSString stringWithFormat:@"%u", captureManager.numMatches]];

	
	[overlayLayer setNeedsDisplay];
}


- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {

	int border = 0;
	CGContextSetLineWidth(context, 2.0);
    CGContextSetRGBStrokeColor(context, 0.0, 0.8, 1.0, 1.0);
    CGContextStrokeRect(context, CGRectMake(layer.bounds.origin.x + border, 
											layer.bounds.origin.y + border, 
											layer.bounds.size.width - border * 2, 
											layer.bounds.size.height - border * 2));
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
	[captureManager setColorReferencePoint:touchPoint];
	NSLog(@"Touch at %d, %d", (int) touchPoint.x, (int) touchPoint.y);
}


- (void)viewDidLoad {
	
	redrawDelta = 10;

	captureManager = [[CaptureSessionManager alloc] init];

	// Configure capture session
	[captureManager addVideoInput];
	[captureManager addVideoDataOutput];

	// Set up video preview layer
	[captureManager addVideoPreviewLayer];
	CGRect layerRect = self.view.layer.bounds;
	captureManager.previewLayer.bounds = layerRect;
	captureManager.previewLayer.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
	[self.view.layer addSublayer:captureManager.previewLayer];
	
	// Set up recognition rectangle overlay
	overlayLayer = [CALayer layer]; 
    CGRect frame = self.view.layer.bounds;
    frame.origin.x += 10.0f;
	frame.origin.y += 10.0f;
	frame.size.width = 20.0f;
	frame.size.height = 20.0f;
	overlayLayer.frame = frame;
    overlayLayer.backgroundColor = [[UIColor clearColor] CGColor];
	overlayLayer.delegate = self;
    [self.view.layer addSublayer:overlayLayer];
	
	settingsUIItems = [[NSMutableArray alloc] init];

	numFoundLabel = [[UILabel alloc] initWithFrame:CGRectMake( 20, 20, 100, 36)];
	[numFoundLabel setFont:[UIFont systemFontOfSize:36]];
	[numFoundLabel setTextColor:[UIColor whiteColor]];
	[numFoundLabel setBackgroundColor:[UIColor clearColor]];
	[numFoundLabel setText:[NSString stringWithFormat:@"%u", captureManager.numMatches]];
	[self.view addSubview:numFoundLabel];
	[settingsUIItems addObject:numFoundLabel];
	
	UILabel *redrawDeltaLabel = [[UILabel alloc] initWithFrame:CGRectMake( 20, 185, 320, 24)];
	[redrawDeltaLabel setFont:[UIFont systemFontOfSize:18]];
	[redrawDeltaLabel setTextColor:[UIColor whiteColor]];
	[redrawDeltaLabel setBackgroundColor:[UIColor clearColor]];
	[redrawDeltaLabel setText:[NSString stringWithFormat:@"Redraw Delta", redrawDelta]];
	[self.view addSubview:redrawDeltaLabel];
	[settingsUIItems addObject:redrawDeltaLabel];
	
	UISlider *redrawDeltaSlider = [[UISlider alloc ] initWithFrame: CGRectMake( 20, 200, 250, 60)];
	redrawDeltaSlider.minimumValue = 0;
	redrawDeltaSlider.maximumValue = 50;
	redrawDeltaSlider.value = redrawDelta;
	redrawDeltaSlider.continuous = YES;
	[redrawDeltaSlider addTarget:self action:@selector(updateRedrawDelta:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:redrawDeltaSlider];
	[settingsUIItems addObject:redrawDeltaSlider];
	
	redrawDeltaValueLabel = [[UILabel alloc] initWithFrame:CGRectMake( 280, 218, 40, 24)];
	[redrawDeltaValueLabel setFont:[UIFont systemFontOfSize:18]];
	[redrawDeltaValueLabel setTextColor:[UIColor whiteColor]];
	[redrawDeltaValueLabel setBackgroundColor:[UIColor clearColor]];
	[redrawDeltaValueLabel setText:[NSString stringWithFormat:@"%u", redrawDelta]];
	[self.view addSubview:redrawDeltaValueLabel];
	[settingsUIItems addObject:redrawDeltaValueLabel];
	
	UILabel *thresholdLabel = [[UILabel alloc] initWithFrame:CGRectMake( 20, 285, 320, 24)];
	[thresholdLabel setFont:[UIFont systemFontOfSize:18]];
	[thresholdLabel setTextColor:[UIColor whiteColor]];
	[thresholdLabel setBackgroundColor:[UIColor clearColor]];
	[thresholdLabel setText:[NSString stringWithFormat:@"Match Threshold", captureManager.matchThreshold]];
	[self.view addSubview:thresholdLabel];
	[settingsUIItems addObject:thresholdLabel];
	
	UISlider *thresholdSlider = [[UISlider alloc ] initWithFrame: CGRectMake( 20, 300, 250, 60)];
	thresholdSlider.minimumValue = 0;
	thresholdSlider.maximumValue = 50;
	thresholdSlider.value = captureManager.matchThreshold;
	thresholdSlider.continuous = YES;
	[thresholdSlider addTarget:self action:@selector(updateThreshold:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:thresholdSlider];
	[settingsUIItems addObject:thresholdSlider];
	
	thresholdValueLabel = [[UILabel alloc] initWithFrame:CGRectMake( 280, 318, 40, 24)];
	[thresholdValueLabel setFont:[UIFont systemFontOfSize:18]];
	[thresholdValueLabel setTextColor:[UIColor whiteColor]];
	[thresholdValueLabel setBackgroundColor:[UIColor clearColor]];
	[thresholdValueLabel setText:[NSString stringWithFormat:@"%u", captureManager.matchThreshold]];
	[self.view addSubview:thresholdValueLabel];
	[settingsUIItems addObject:thresholdValueLabel];
	
	UILabel *recognitionMatchesLabel = [[UILabel alloc] initWithFrame:CGRectMake( 20, 385, 320, 24)];
	[recognitionMatchesLabel setFont:[UIFont systemFontOfSize:18]];
	[recognitionMatchesLabel setTextColor:[UIColor whiteColor]];
	[recognitionMatchesLabel setBackgroundColor:[UIColor clearColor]];
	[recognitionMatchesLabel setText:[NSString stringWithFormat:@"Minimum Matches", captureManager.matchesForRecognition]];
	[self.view addSubview:recognitionMatchesLabel];
	[settingsUIItems addObject:recognitionMatchesLabel];
	
	UISlider *recognitionMatchesSlider = [[UISlider alloc ] initWithFrame: CGRectMake( 20, 400, 250, 60)];
	recognitionMatchesSlider.minimumValue = 1;
	recognitionMatchesSlider.maximumValue = 100;
	recognitionMatchesSlider.value = captureManager.matchesForRecognition;
	recognitionMatchesSlider.continuous = YES;
	[recognitionMatchesSlider addTarget:self action:@selector(updateRecognitionMatches:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:recognitionMatchesSlider];
	[settingsUIItems addObject:recognitionMatchesSlider];
	
	recognitionMatchesValueLabel = [[UILabel alloc] initWithFrame:CGRectMake( 280, 418, 40, 24)];
	[recognitionMatchesValueLabel setFont:[UIFont systemFontOfSize:18]];
	[recognitionMatchesValueLabel setTextColor:[UIColor whiteColor]];
	[recognitionMatchesValueLabel setBackgroundColor:[UIColor clearColor]];
	[recognitionMatchesValueLabel setText:[NSString stringWithFormat:@"%u", captureManager.matchesForRecognition]];
	[self.view addSubview:recognitionMatchesValueLabel];
	[settingsUIItems addObject:recognitionMatchesValueLabel];
	
	UISwipeGestureRecognizer* swipeUpRecognizer = [[UISwipeGestureRecognizer allocWithZone:[self zone]] initWithTarget:self action:@selector(showSettingsUI:)];
	[swipeUpRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
	[self.view addGestureRecognizer:swipeUpRecognizer];
	[swipeUpRecognizer release];

	UISwipeGestureRecognizer* swipeDownRecognizer = [[UISwipeGestureRecognizer allocWithZone:[self zone]] initWithTarget:self action:@selector(hideSettingsUI:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
	[self.view addGestureRecognizer:swipeDownRecognizer];
	[swipeDownRecognizer release];	
	
	[self hideSettingsUI:(id)self];

	[captureManager.captureSession startRunning];

	[NSTimer scheduledTimerWithTimeInterval:RECT_UPDATE_INTERVAL target:self selector:@selector(updateRecognitionRect) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {
    [super dealloc];
}

@end
