/*
     File: AVCamDemoViewController.m
 Abstract: View controller code that manages all the buttons in the main view (HUD, Swap, Record, Still, Grav) as well as the device controls and and session properties (Focus, Exposure, Power, Peak, etc.) that are displayed over the live capture window.
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

#import "AVCamDemoViewController.h"
#import "AVCamDemoCaptureManager.h"
#import "ExpandyButton.h"
#import "AVCamDemoPreviewView.h"

// KVO contexts
static void *AVCamDemoFocusModeObserverContext = &AVCamDemoFocusModeObserverContext;
static void *AVCamDemoTorchModeObserverContext = &AVCamDemoTorchModeObserverContext;
static void *AVCamDemoFlashModeObserverContext = &AVCamDemoFlashModeObserverContext;
static void *AVCamDemoAdjustingObserverContext = &AVCamDemoAdjustingObserverContext;

// HUD Appearance
const CGFloat hudCornerRadius = 8.f;
const CGFloat hudLayerWhite = 1.f;
const CGFloat hudLayerAlpha = .5f;
const CGFloat hudBorderWhite = .0f;
const CGFloat hudBorderAlpha = 1.f;
const CGFloat hudBorderWidth = 1.f;

@interface AVCamDemoViewController ()
@property (nonatomic,assign,getter=isConfigHidden) BOOL configHidden;
@property (nonatomic,retain) CALayer *focusBox;
@property (nonatomic,retain) CALayer *exposeBox;
@end

@interface AVCamDemoViewController (InternalMethods)
+ (CGRect)cleanApertureFromPorts:(NSArray *)ports;
+ (CGSize)sizeForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize;
+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove;
- (CGPoint)translatePoint:(CGPoint)point fromGravity:(NSString *)gravity1 toGravity:(NSString *)gravity2;
- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point;
- (void)drawExposeBoxAtPointOfInterest:(CGPoint)point;
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
@end


@interface AVCamDemoViewController (AVCamDemoCaptureManagerDelegate) <AVCamDemoCaptureManagerDelegate>
@end

@interface AVCamDemoViewController (AVCamDemoPreviewViewDelegate) <AVCamDemoPreviewViewDelegate>
@end

@implementation AVCamDemoViewController

@synthesize captureManager = _captureManager;
@synthesize videoPreviewView = _videoPreviewView;
@synthesize captureVideoPreviewLayer = _captureVideoPreviewLayer;
@synthesize adjustingInfoView = _adjustingInfoView;
@synthesize hudButton = _hudButton;
@synthesize cameraToggleButton = _cameraToggleButton;
@synthesize recordButton = _recordButton;
@synthesize stillImageButton = _stillImageButton;
@synthesize gravityButton = _gravityButton;
@synthesize flash = _flash;
@synthesize torch = _torch;
@synthesize focus = _focus;
@synthesize exposure = _exposure;
@synthesize whiteBalance = _whiteBalance;
@synthesize adjustingFocus = _adjustingFocus;
@synthesize adjustingExposure = _adjustingExposure;
@synthesize adjustingWhiteBalance = _adjustingWhiteBalance;
@synthesize configHidden = _configHidden;
@synthesize focusBox = _focusBox;
@synthesize exposeBox = _exposeBox;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:(NSCoder *)decoder];
    if (self != nil) {
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.flashMode" options:NSKeyValueObservingOptionNew context:AVCamDemoFlashModeObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.torchMode" options:NSKeyValueObservingOptionNew context:AVCamDemoTorchModeObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamDemoFocusModeObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingFocus" options:NSKeyValueObservingOptionNew context:AVCamDemoAdjustingObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingExposure" options:NSKeyValueObservingOptionNew context:AVCamDemoAdjustingObserverContext];
        [self addObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingWhiteBalance" options:NSKeyValueObservingOptionNew context:AVCamDemoAdjustingObserverContext];
    }
    return self;
}

- (void) dealloc
{
    [self setCaptureManager:nil];
    [super dealloc];
}

- (void)viewDidLoad
{
    NSError *error;
    
    CALayer *adjustingInfolayer = [[self adjustingInfoView] layer];
    [adjustingInfolayer setCornerRadius:hudCornerRadius];
    [adjustingInfolayer setBorderColor:[[UIColor colorWithWhite:hudBorderWhite alpha:hudBorderAlpha] CGColor]];
    [adjustingInfolayer setBorderWidth:hudBorderWidth];
    [adjustingInfolayer setBackgroundColor:[[UIColor colorWithWhite:hudLayerWhite alpha:hudLayerAlpha] CGColor]];
    [adjustingInfolayer setPosition:CGPointMake([adjustingInfolayer position].x, [adjustingInfolayer position].y + 12.f)];
    
    AVCamDemoCaptureManager *captureManager = [[AVCamDemoCaptureManager alloc] init];
    if ([captureManager setupSessionWithPreset:AVCaptureSessionPresetHigh error:&error]) {
        [self setCaptureManager:captureManager];
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[captureManager session]];
        UIView *view = [self videoPreviewView];
        CALayer *viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        
        CGRect bounds = [view bounds];
        
        [captureVideoPreviewLayer setFrame:bounds];
        
        if ([captureVideoPreviewLayer isOrientationSupported]) {
            [captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        }
        
        [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [self setCaptureVideoPreviewLayer:captureVideoPreviewLayer];
        
        NSDictionary *unanimatedActions = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"bounds",[NSNull null], @"frame",[NSNull null], @"position", nil];
        CALayer *focusBox = [[CALayer alloc] init];
        [focusBox setActions:unanimatedActions];
        [focusBox setBorderWidth:3.f];
        [focusBox setBorderColor:[[UIColor colorWithRed:0.f green:0.f blue:1.f alpha:.8f] CGColor]];
        [focusBox setOpacity:0.f];
        [viewLayer addSublayer:focusBox];
        [self setFocusBox:focusBox];
        [focusBox release];
        
        CALayer *exposeBox = [[CALayer alloc] init];
        [exposeBox setActions:unanimatedActions];
        [exposeBox setBorderWidth:3.f];
        [exposeBox setBorderColor:[[UIColor colorWithRed:1.f green:0.f blue:0.f alpha:.8f] CGColor]];
        [exposeBox setOpacity:0.f];
        [viewLayer addSublayer:exposeBox];
        [self setExposeBox:exposeBox];
        [exposeBox release];
        [unanimatedActions release];
        
        CGPoint screenCenter = CGPointMake(bounds.size.width / 2.f, bounds.size.height / 2.f);
        
        [self drawFocusBoxAtPointOfInterest:screenCenter];
        [self drawExposeBoxAtPointOfInterest:screenCenter];        
        
        if ([[captureManager session] isRunning]) {
            [self setConfigHidden:YES];
            NSInteger count = 0;
            if ([captureManager hasFlash]) {
                ExpandyButton *flash =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f)
                                                                       title:@"Flash"
                                                                 buttonNames:[NSArray arrayWithObjects:@"Off",@"On",@"Auto",nil]
                                                                selectedItem:[captureManager flashMode]];
                [flash setHidden:YES];
                [flash addTarget:self action:@selector(flashChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:flash];
                [self setFlash:flash];
                [flash release];
                count++;
            }
            
            if ([captureManager hasTorch]) {
                ExpandyButton *torch =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                       title:@"Torch"
                                                                 buttonNames:[NSArray arrayWithObjects:@"Off",@"On",@"Auto",nil]
                                                                selectedItem:[captureManager torchMode]];
                [torch setHidden:YES];
                [torch addTarget:self action:@selector(torchChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:torch];
                [self setTorch:torch];
                [torch release];
                count++;
            }
            
            if ([captureManager hasFocus]) {
                ExpandyButton *focus =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                       title:@"AFoc"
                                                                 buttonNames:[NSArray arrayWithObjects:@"Lock",@"Auto",@"Cont",nil]
                                                                selectedItem:[captureManager focusMode]];
                [focus setHidden:YES];
                [focus addTarget:self action:@selector(focusChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:focus];
                [self setFocus:focus];
                [focus release];
                count++;
            }
            
            if ([captureManager hasExposure]) {
                ExpandyButton *exposure =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                          title:@"AExp"
                                                                    buttonNames:[NSArray arrayWithObjects:@"Lock",@"Cont",nil]
                                                                   selectedItem:([captureManager exposureMode] == 2 ? 1 : [captureManager exposureMode])];
                [exposure setHidden:YES];
                [exposure addTarget:self action:@selector(exposureChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:exposure];
                [self setExposure:exposure];
                [exposure release];
                count++;
            }
            
            if ([captureManager hasWhiteBalance]) {
                ExpandyButton *whiteBalance =  [[ExpandyButton alloc] initWithPoint:CGPointMake(8.f, 8.f + (40.f * count))
                                                                              title:@"AWB"
                                                                        buttonNames:[NSArray arrayWithObjects:@"Lock",@"Cont",nil]
                                                                       selectedItem:([captureManager whiteBalanceMode] == 2 ? 1 : [captureManager whiteBalanceMode])];
                [whiteBalance setHidden:YES];
                [whiteBalance addTarget:self action:@selector(whiteBalanceChange:) forControlEvents:UIControlEventValueChanged];
                [view addSubview:whiteBalance];
                [self setWhiteBalance:whiteBalance];
                [whiteBalance release];
            }
            
            [captureManager setDelegate:self];
            
            NSUInteger cameraCount = [captureManager cameraCount];
            if (cameraCount < 1) {
                [[self hudButton] setEnabled:NO];
                [[self cameraToggleButton] setEnabled:NO];
                [[self stillImageButton] setEnabled:NO];
                [[self gravityButton] setEnabled:NO];
            } else if (cameraCount < 2) {
                [[self cameraToggleButton] setEnabled:NO];
            }
            
            if (cameraCount < 1 && [captureManager micCount] < 1) {
                [[self recordButton] setEnabled:NO];
            }
            
            [viewLayer insertSublayer:captureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
            
            [captureVideoPreviewLayer release];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                                message:@"Failed to start session."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input Device Init Failed"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];        
    }
    
    [captureManager release];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.flashMode"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.torchMode"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingFocus"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingExposure"];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.adjustingWhiteBalance"];
    
    [self setVideoPreviewView:nil];
    [self setCaptureVideoPreviewLayer:nil];
    [self setAdjustingInfoView:nil];
    [self setHudButton:nil];
    [self setCameraToggleButton:nil];
    [self setRecordButton:nil];
    [self setGravityButton:nil];
    [self setFlash:nil];
    [self setTorch:nil];
    [self setFocus:nil];
    [self setExposure:nil];
    [self setWhiteBalance:nil];
    [self setAdjustingFocus:nil];
    [self setAdjustingExposure:nil];
    [self setAdjustingWhiteBalance:nil];
    [self setFocusBox:nil];
    [self setExposeBox:nil];
}


#pragma mark Capture Buttons
- (IBAction)record:(id)sender
{
    if (![[self captureManager] isRecording]) {
        [[self recordButton] setEnabled:NO];
        [[self captureManager] startRecording];
    } else {
        [[self recordButton] setEnabled:NO];
        [[self captureManager] stopRecording];
    }
}

- (IBAction)still:(id)sender
{
    [[self captureManager] captureStillImage];
    
    UIView *flashView = [[UIView alloc] initWithFrame:[[self videoPreviewView] frame]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [flashView setAlpha:0.f];
    [[[self view] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:1.f];
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                         [flashView release];
                     }
    ];
}

#pragma mark Camera Toggle
- (IBAction)cameraToggle:(id)sender
{
    [[self captureManager] cameraToggle];
    [[self focusBox] removeAllAnimations];
    [[self exposeBox] removeAllAnimations];
    [self resetFocusAndExpose];
    
    // Update displaying of expandy buttons (don't display buttons for unsupported features)
    BOOL isConfigHidden = [self isConfigHidden];
    int count = 0;
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    ExpandyButton *expandyButton = [self flash];
    if ([captureManager hasFlash]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self torch];
    if ([captureManager hasTorch]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self focus];
    if ([captureManager hasFocus]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self exposure];
    if ([captureManager hasExposure]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        count++;
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }
    
    expandyButton = [self whiteBalance];
    if ([captureManager hasWhiteBalance]) {
        CGRect frame = [expandyButton frame];
        [expandyButton setFrame:CGRectMake(8.f, 8.f + (40.f * count), frame.size.width, frame.size.height)];
        if (!isConfigHidden) [expandyButton setHidden:NO];
    } else {
        [expandyButton setHidden:YES];
    }    
}

#pragma mark Config View
- (IBAction)hudViewToggle:(id)sender
{
    if ([self isConfigHidden]) {
        [self setConfigHidden:NO];
        AVCamDemoCaptureManager *captureManager = [self captureManager];
        if ([captureManager hasFlash]) {
            [[self flash] setHidden:NO];
        }
        if ([captureManager hasTorch]) {
            [[self torch] setHidden:NO];
        }
        if ([captureManager hasFocus]) {
            [[self focus] setHidden:NO];
        }
        if ([captureManager hasExposure]) {
            [[self exposure] setHidden:NO];
        }
        if ([captureManager hasWhiteBalance]) {
            [[self whiteBalance] setHidden:NO];
        }
        [[self adjustingInfoView] setHidden:NO];
    } else {
        [self setConfigHidden:YES];
        [[self flash] setHidden:YES];
        [[self torch] setHidden:YES];
        [[self focus] setHidden:YES];
        [[self exposure] setHidden:YES];
        [[self whiteBalance] setHidden:YES];
        [[self adjustingInfoView] setHidden:YES];
    }
}

- (IBAction)flashChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setFlashMode:AVCaptureFlashModeOff];
            break;
        case 1:
            [[self captureManager] setFlashMode:AVCaptureFlashModeOn];
            break;
        case 2:
            [[self captureManager] setFlashMode:AVCaptureFlashModeAuto];
            break;
    }
}

- (IBAction)torchChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setTorchMode:AVCaptureTorchModeOff];
            break;
        case 1:
            [[self captureManager] setTorchMode:AVCaptureTorchModeOn];
            break;
        case 2:
            [[self captureManager] setTorchMode:AVCaptureTorchModeAuto];
            break;
    }
}

- (IBAction)focusChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setFocusMode:AVCaptureFocusModeLocked];
            break;
        case 1:
            [[self captureManager] setFocusMode:AVCaptureFocusModeAutoFocus];
            break;
        case 2:
            [[self captureManager] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            break;
    }
}

- (IBAction)exposureChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setExposureMode:AVCaptureExposureModeLocked];
            break;
        case 1:
            [[self captureManager] setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            break;
    }
}

- (IBAction)whiteBalanceChange:(id)sender
{
    switch ([(ExpandyButton *)sender selectedItem]) {
        case 0:
            [[self captureManager] setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
            break;
        case 1:
            [[self captureManager] setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
        return;
    }
    if (AVCamDemoFocusModeObserverContext == context) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[self focus] selectedItem]) {
            [[self focus] setSelectedItem:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
    } else if (AVCamDemoFlashModeObserverContext == context) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[self flash] selectedItem]) {
            [[self flash] setSelectedItem:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
    } else if (AVCamDemoTorchModeObserverContext == context) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] != [[self torch] selectedItem]) {
            [[self torch] setSelectedItem:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
        }
    } else if (AVCamDemoAdjustingObserverContext == context) {
        UIView *view = nil;
        if ([keyPath isEqualToString:@"captureManager.videoInput.device.adjustingFocus"]) {
            view = [self adjustingFocus];
            [AVCamDemoViewController addAdjustingAnimationToLayer:[self focusBox] removeAnimation:NO];
        } else if ([keyPath isEqualToString:@"captureManager.videoInput.device.adjustingExposure"]) {
            view = [self adjustingExposure];
            [AVCamDemoViewController addAdjustingAnimationToLayer:[self exposeBox] removeAnimation:NO];
        } else if ([keyPath isEqualToString:@"captureManager.videoInput.device.adjustingWhiteBalance"]) {
            view = [self adjustingWhiteBalance];
        }
        
        if (view != nil) {
            CALayer *layer = [view layer];
            [layer setBorderWidth:1.f];
            [layer setBorderColor:[[UIColor colorWithWhite:0.f alpha:.7f] CGColor]];
            [layer setCornerRadius:8.f];
            
            if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == YES) {
                [layer setBackgroundColor:[[UIColor colorWithRed:1.f green:0.f blue:0.f alpha:.7f] CGColor]];
            } else {
                [layer setBackgroundColor:[[UIColor colorWithWhite:1.f alpha:.2f] CGColor]];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)changeGravity
{
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [self captureVideoPreviewLayer];
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        [[self focusBox] setPosition:[self translatePoint:[[self focusBox] position] fromGravity:AVLayerVideoGravityResize toGravity:AVLayerVideoGravityResizeAspect]];
        [[self exposeBox] setPosition:[self translatePoint:[[self exposeBox] position] fromGravity:AVLayerVideoGravityResize toGravity:AVLayerVideoGravityResizeAspect]];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];        
    } else if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
        [[self focusBox] setPosition:[self translatePoint:[[self focusBox] position] fromGravity:AVLayerVideoGravityResizeAspect toGravity:AVLayerVideoGravityResizeAspectFill]];
        [[self exposeBox] setPosition:[self translatePoint:[[self exposeBox] position] fromGravity:AVLayerVideoGravityResizeAspect toGravity:AVLayerVideoGravityResizeAspectFill]];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    } else if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill] ) {        
        [[self focusBox] setPosition:[self translatePoint:[[self focusBox] position] fromGravity:AVLayerVideoGravityResizeAspectFill toGravity:AVLayerVideoGravityResize]];
        [[self exposeBox] setPosition:[self translatePoint:[[self exposeBox] position] fromGravity:AVLayerVideoGravityResizeAspectFill toGravity:AVLayerVideoGravityResize]];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResize];
    }
    
    [self drawFocusBoxAtPointOfInterest:[[self focusBox] position]];
    [self drawExposeBoxAtPointOfInterest:[[self exposeBox] position]];    
}

@end

@implementation AVCamDemoViewController (InternalMethods)

+ (CGRect)cleanApertureFromPorts:(NSArray *)ports
{
    CGRect cleanAperture;
    for (AVCaptureInputPort *port in ports) {
        if ([port mediaType] == AVMediaTypeVideo) {
            cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
            break;
        }
    }
    return cleanAperture;
}

+ (CGSize)sizeForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
    return size;
}

+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove
{
    if (remove) {
        [layer removeAnimationForKey:@"animateOpacity"];
    }
    if ([layer animationForKey:@"animateOpacity"] == nil) {
        [layer setHidden:NO];
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [opacityAnimation setDuration:.3f];
        [opacityAnimation setRepeatCount:1.f];
        [opacityAnimation setAutoreverses:YES];
        [opacityAnimation setFromValue:[NSNumber numberWithFloat:1.f]];
        [opacityAnimation setToValue:[NSNumber numberWithFloat:.0f]];
        [layer addAnimation:opacityAnimation forKey:@"animateOpacity"];
    }
}

- (CGPoint)translatePoint:(CGPoint)point fromGravity:(NSString *)oldGravity toGravity:(NSString *)newGravity
{
    CGPoint newPoint;
        
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
    
    CGSize oldSize = [AVCamDemoViewController sizeForGravity:oldGravity frameSize:frameSize apertureSize:apertureSize];
    
    CGSize newSize = [AVCamDemoViewController sizeForGravity:newGravity frameSize:frameSize apertureSize:apertureSize];
    
    if (oldSize.height < newSize.height) {
        newPoint.y = ((point.y * newSize.height) / oldSize.height) - ((newSize.height - oldSize.height) / 2.f);
    } else if (oldSize.height > newSize.height) {
        newPoint.y = ((point.y * newSize.height) / oldSize.height) + ((oldSize.height - newSize.height) / 2.f) * (newSize.height / oldSize.height);
    } else if (oldSize.height == newSize.height) {
        newPoint.y = point.y;
    }
    
    if (oldSize.width < newSize.width) {
        newPoint.x = (((point.x - ((newSize.width - oldSize.width) / 2.f)) * newSize.width) / oldSize.width);
    } else if (oldSize.width > newSize.width) {
        newPoint.x = ((point.x * newSize.width) / oldSize.width) + ((oldSize.width - newSize.width) / 2.f);
    } else if (oldSize.width == newSize.width) {
        newPoint.x = point.x;
    }
    
    return newPoint;
}

- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager hasFocus]) {
        CGSize frameSize = [[self videoPreviewView] frame].size;
        
        CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
        
        CGSize oldBoxSize = [AVCamDemoViewController sizeForGravity:[[self captureVideoPreviewLayer] videoGravity] frameSize:frameSize apertureSize:apertureSize];
        
        CGPoint focusPointOfInterest = [[[captureManager videoInput] device] focusPointOfInterest];
        CGSize newBoxSize;
        if (focusPointOfInterest.x == .5f && focusPointOfInterest.y == .5f) {
            newBoxSize.width = (116.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (158.f / frameSize.height) * oldBoxSize.height;
        } else {
            newBoxSize.width = (80.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (110.f / frameSize.height) * oldBoxSize.height;
        }
        
        CALayer *focusBox = [self focusBox];
        [focusBox setFrame:CGRectMake(0.f, 0.f, newBoxSize.width, newBoxSize.height)];
        [focusBox setPosition:point];
        [AVCamDemoViewController addAdjustingAnimationToLayer:focusBox removeAnimation:YES];
    }    
}

- (void)drawExposeBoxAtPointOfInterest:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager hasExposure]) {
        CGSize frameSize = [[self videoPreviewView] frame].size;
        
        CGSize apertureSize = [AVCamDemoViewController cleanApertureFromPorts:[[[self captureManager] videoInput] ports]].size;
        
        CGSize oldBoxSize = [AVCamDemoViewController sizeForGravity:[[self captureVideoPreviewLayer] videoGravity] frameSize:frameSize apertureSize:apertureSize];
        
        CGPoint exposurePointOfInterest = [[[captureManager videoInput] device] exposurePointOfInterest];
        CGSize newBoxSize;
        if (exposurePointOfInterest.x == .5f && exposurePointOfInterest.y == .5f) {
            newBoxSize.width = (290.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (395.f / frameSize.height) * oldBoxSize.height;
        } else {
            newBoxSize.width = (114.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (154.f / frameSize.height) * oldBoxSize.height;
        }
        
        CALayer *exposeBox = [self exposeBox];
        [exposeBox setFrame:CGRectMake(0.f, 0.f, newBoxSize.width, newBoxSize.height)];
        [exposeBox setPosition:point];
        [AVCamDemoViewController addAdjustingAnimationToLayer:exposeBox removeAnimation:YES];
    }    
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates 
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [self captureVideoPreviewLayer];
    
    if ([[self captureVideoPreviewLayer] isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }    
    
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

@end

@implementation AVCamDemoViewController (AVCamDemoCaptureManagerDelegate)

- (void) captureStillImageFailedWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Still Image Capture Failure"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void) acquiringDeviceLockFailedWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Device Configuration Lock Failure"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
}

- (void) cannotWriteToAssetLibrary
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Incompatible with Asset Library"
                                                        message:@"The captured file cannot be written to the asset library. It is likely an audio-only file."
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
}

- (void) assetLibraryError:(NSError *)error forURL:(NSURL *)assetURL
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Asset Library Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
}

- (void) someOtherError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
}

- (void) recordingBegan
{
    [[self recordButton] setTitle:@"Stop"];
    [[self recordButton] setEnabled:YES];
}

- (void) recordingFinished
{
    [[self recordButton] setTitle:@"Record"];
    [[self recordButton] setEnabled:YES];
}

- (void) deviceCountChanged
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([captureManager cameraCount] >= 1 || [captureManager micCount] >= 1) {
        [[self recordButton] setEnabled:YES];
    } else {
        [[self recordButton] setEnabled:NO];
    }

}

@end

@implementation AVCamDemoViewController (AVCamDemoPreviewViewDelegate)

- (void)tapToFocus:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:point];
        [captureManager focusAtPoint:convertedFocusPoint];
        [self drawFocusBoxAtPointOfInterest:point];
    }
}

- (void)tapToExpose:(CGPoint)point
{
    AVCamDemoCaptureManager *captureManager = [self captureManager];
    if ([[[captureManager videoInput] device] isExposurePointOfInterestSupported]) {
        CGPoint convertedExposurePoint = [self convertToPointOfInterestFromViewCoordinates:point];
        [captureManager exposureAtPoint:convertedExposurePoint];
        [self drawExposeBoxAtPointOfInterest:point];
    }
}

- (void)resetFocusAndExpose
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    [[self captureManager] focusAtPoint:pointOfInterest];
    [[self captureManager] exposureAtPoint:pointOfInterest];
    
    CGRect bounds = [[self videoPreviewView] bounds];
    CGPoint screenCenter = CGPointMake(bounds.size.width / 2.f, bounds.size.height / 2.f);
    
    [self drawFocusBoxAtPointOfInterest:screenCenter];
    [self drawExposeBoxAtPointOfInterest:screenCenter];
    
    [[self captureManager] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
}

@end
