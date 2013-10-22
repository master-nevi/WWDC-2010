/*
     File: MainViewController.m
 Abstract: Controller that manages an AVCaptureVideoPreviewLayer and uses UIGestureRecognizers transform it.
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

@implementation MainViewController

- (void)viewDidLoad 
{
	[super viewDidLoad];
    
    previewOrientationLocked = YES;
    uiOrientationLocked = YES;
	
	// clip sub-layer contents
	previewParentView.layer.masksToBounds = YES;
	
	// do one time set-up of gesture recognizers
	UIGestureRecognizer *recognizer;
	
	recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapFrom:)];
	recognizer.delegate = self;
	[previewParentView addGestureRecognizer:recognizer];
	[recognizer release];
	
	recognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
	recognizer.delegate = self;
	[previewParentView addGestureRecognizer:recognizer];
	[recognizer release];
	
	recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragFrom:)];
	recognizer.delegate = self;
	((UIPanGestureRecognizer *)recognizer).maximumNumberOfTouches = 1;
	[previewParentView addGestureRecognizer:recognizer];
	[recognizer release];
	
	recognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationFrom:)];
	recognizer.delegate = self;
	[previewParentView addGestureRecognizer:recognizer];
	[recognizer release];
}

// For shake events
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self becomeFirstResponder];
	if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"InstructionsHaveBeenShown"] ) {
		[self showInfo:nil];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"InstructionsHaveBeenShown"];
	}
}

- (void)makeAndApplyAffineTransform
{
	// translate, then scale, then rotate
	CGAffineTransform affineTransform = CGAffineTransformMakeTranslation(effectiveTranslation.x, effectiveTranslation.y);
	affineTransform = CGAffineTransformScale(affineTransform, effectiveScale, effectiveScale);
	affineTransform = CGAffineTransformRotate(affineTransform, effectiveRotationRadians);
	[CATransaction begin];
	[CATransaction setAnimationDuration:.025];
	[previewLayer setAffineTransform:affineTransform];
	[CATransaction commit];
}

- (void)applyDefaults
{
	effectiveScale = 1.0;
	effectiveRotationRadians = 0.0;
	effectiveTranslation = CGPointMake(0.0, 0.0);
	[previewLayer setAffineTransform:CGAffineTransformIdentity];
	previewLayer.frame = previewParentView.layer.bounds;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if ( motion == UIEventSubtypeMotionShake ) {
        [CATransaction begin];
        [self applyDefaults];
        [CATransaction commit];
	}
}

- (void)_setupPreviewLayer
{
    if ( ! previewLayer ) {
        AVCaptureSession *session = [[[AVCaptureSession alloc] init] autorelease];
        AVCaptureDevice *videoDevice = nil;
        for ( AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] ) {
            if ( device.position == AVCaptureDevicePositionFront ) {
                videoDevice = device;
                break;
            }
        }
        
        if ( ! videoDevice )
            videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if ( videoDevice ) {
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
            [session addInput:input];
            previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
			[self applyDefaults];
			previewLayer.backgroundColor = [[UIColor redColor] CGColor];
            [previewParentView.layer insertSublayer:previewLayer atIndex:0];
        }
        else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No camera" 
				message:@"PinchyPreview is a very boring app when run on a device with no camera." 
				delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView autorelease];
			[alertView show];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self _setupPreviewLayer];
	if ( sessionStarted )
		[previewLayer.session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[previewLayer.session stopRunning];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
		beginGestureScale = effectiveScale;
	}
	else if ( [gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]] ) {
		beginGestureRotationRadians = effectiveRotationRadians;
	}
	if ( [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] ) {
        CGPoint location = [gestureRecognizer locationInView:previewParentView];
        beginGestureTranslation = CGPointMake(effectiveTranslation.x - location.x, effectiveTranslation.x - location.y);
	}
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if ( touch.view == previewParentView )
		return YES;
	return NO;
}

- (void)handleSingleTapFrom:(UITapGestureRecognizer *)recognizer
{
	CGPoint location = [recognizer locationInView:previewParentView];
	CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
	if ( [previewLayer containsPoint:convertedLocation] ) {
		// cycle to next video gravity mode.
		NSString *videoGravity = previewLayer.videoGravity;
		if ( [videoGravity isEqualToString:AVLayerVideoGravityResizeAspect] )
			previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		else if ( [videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill] )
			previewLayer.videoGravity = AVLayerVideoGravityResize;
		else if ( [videoGravity isEqualToString:AVLayerVideoGravityResize] )
			previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	}
}

- (void)handleShake
{
	[CATransaction begin];
	[self applyDefaults];
	[CATransaction commit];
}

- (void)handlePinchFrom:(UIPinchGestureRecognizer *)recognizer
{
	BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [recognizer numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [recognizer locationOfTouch:i inView:previewParentView];
		CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
		if ( ! [previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		effectiveScale = beginGestureScale * recognizer.scale;
		[self makeAndApplyAffineTransform];
	}
}

- (void)handleDragFrom:(UIPanGestureRecognizer *)recognizer
{
	CGPoint location = [recognizer locationInView:previewParentView];
	CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
	
	if ( [previewLayer containsPoint:convertedLocation] ) {
        effectiveTranslation = CGPointMake(beginGestureTranslation.x + location.x, beginGestureTranslation.y + location.y);
        [self makeAndApplyAffineTransform];
	}
}

- (void)handleRotationFrom:(UIRotationGestureRecognizer *)recognizer
{
	BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [recognizer numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [recognizer locationOfTouch:i inView:previewParentView];
		CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
		if ( ! [previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		effectiveRotationRadians = beginGestureRotationRadians + recognizer.rotation;
		[self makeAndApplyAffineTransform];
	}
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender
{	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}

- (IBAction)toggleRunning:(id)sender
{
	if ( previewLayer ) {
		NSString *buttonText = ((UIBarButtonItem *)sender).title;
		
		if ( [buttonText isEqualToString:@"Start"] ) {
			((UIBarButtonItem *)sender).title = @"Stop";
			[previewLayer.session startRunning];
			sessionStarted = YES;
		}
		else if ( [buttonText isEqualToString:@"Stop"] ) {
			((UIBarButtonItem *)sender).title = @"Start";
			[previewLayer.session stopRunning];
			sessionStarted = NO;
		}
	}
}

- (IBAction)toggleInterfaceOrientationLock:(id)sender
{
	if ( uiOrientationLocked ) {
		[(UIButton *)sender setImage:[UIImage imageNamed:@"OrientationUnlocked.png"]  forState:UIControlStateNormal];
	}
	else {
		[(UIButton *)sender setImage:[UIImage imageNamed:@"OrientationLocked.png"]  forState:UIControlStateNormal];
	}
    uiOrientationLocked = ! uiOrientationLocked;
}

- (void)centerUpArrowViewForOrientation:(UIInterfaceOrientation)newOrientation
{
    CGRect parentBounds = self.view.bounds;
    CGRect upArrowViewBounds = upArrowView.bounds;
    
    if ( (((newOrientation == UIInterfaceOrientationPortrait) || (newOrientation == UIInterfaceOrientationPortraitUpsideDown))
            && (parentBounds.size.width > parentBounds.size.height))
        || (((newOrientation == UIInterfaceOrientationLandscapeLeft) || (newOrientation == UIInterfaceOrientationLandscapeRight))
            && (parentBounds.size.height > parentBounds.size.width)) ) {
        // width is all we care about.
        parentBounds.size.width = parentBounds.size.height;
    }

    upArrowViewBounds.origin.x = CGRectGetMidX(parentBounds) - CGRectGetMidX(upArrowViewBounds);
    upArrowView.frame = upArrowViewBounds;
}

- (IBAction)togglePreviewOrientationLock:(id)sender
{
	if ( previewOrientationLocked ) {
		[(UIButton *)sender setImage:[UIImage imageNamed:@"OrientationUnlocked.png"] forState:UIControlStateNormal];
	}
	else {
		[(UIButton *)sender setImage:[UIImage imageNamed:@"OrientationLocked.png"] forState:UIControlStateNormal];
	}
    previewOrientationLocked = ! previewOrientationLocked;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    static BOOL firstTime = YES;
    // Workaround for self.interfaceOrientation infinitely recursing when called before
    // a first orientation has been established.
    if ( firstTime ) {
        firstTime = NO;
        return YES;
    }
    
	if ( uiOrientationLocked )
		return (self.interfaceOrientation == interfaceOrientation);
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[CATransaction begin];
	if ( ! previewOrientationLocked )
		previewLayer.orientation = toInterfaceOrientation;
	[self applyDefaults];
	[CATransaction commit];
    
    [self centerUpArrowViewForOrientation:toInterfaceOrientation];
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)dealloc
{
    previewLayer.session = nil;
    [previewLayer release];
    [super dealloc];
}

@end
