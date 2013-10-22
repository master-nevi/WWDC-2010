
/*
     File: ThumbnailViewController.m
 Abstract: View controller for thumbnail view. 
 
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

#import "ThumbnailViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "SimpleEditor.h"

#import <AVFoundation/AVFoundation.h>

@implementation ThumbnailViewController

@synthesize editor = _editor;

- (id)initWithEditor:(SimpleEditor *)editor
{
	// This is the designated initiliazer for UIViewController
    if (self = [super initWithNibName:nil bundle:nil]) {
		self.editor = editor;
		self.title = @"Thumbnails";
    }
    return self;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	[self.editor buildCompositionObjectsForPlayback:NO];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	self.view.layer.sublayers = nil;
	
	AVAssetImageGenerator *generator = [self.editor assetImageGenerator];
	CMTime duration = self.editor.composition.duration;
	NSInteger gridWidth = 3, gridHeight = 6, gridCount = gridWidth * gridHeight;
	NSInteger gridIndex, gridX, gridY;
	for (gridIndex = 0; gridIndex < gridCount; gridIndex++) {
		gridX = gridIndex % gridWidth;
		gridY = gridIndex / gridWidth;
		CALayer *gridLayer = [CALayer layer];
		CGRect gridFrame = self.view.layer.frame;
		gridFrame.size.width /= gridWidth;
		gridFrame.size.height /= gridHeight;
		gridFrame.origin.x += gridFrame.size.width * gridX;
		gridFrame.origin.y += gridFrame.size.height * gridY;
		gridLayer.frame = gridFrame;
		CMTime thumbTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(duration) * gridIndex / gridCount, 1000);

		gridLayer.opacity = 0.0;
		gridLayer.contentsGravity = kCAGravityResizeAspect;
		gridLayer.backgroundColor = [[UIColor blackColor] CGColor];

		AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
			if (result != AVAssetImageGeneratorSucceeded) {
				NSLog(@"couldn't generate thumbnail, error:%@", error);
			}
			else {
				[CATransaction begin];
				gridLayer.opacity = 1.0;
				gridLayer.contents = (id)image;
				[CATransaction commit];
			}
		};

		CGSize maxSize = gridFrame.size;
		CGFloat screenScale = [[UIScreen mainScreen] scale];
		maxSize.width *= screenScale;
		maxSize.height *= screenScale;
		generator.maximumSize = maxSize;
		[generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
		
		[self.view.layer addSublayer:gridLayer];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	AVAssetImageGenerator *generator = [self.editor assetImageGenerator];
	[generator cancelAllCGImageGeneration];

   [super viewWillDisappear:animated];
}

- (void)dealloc 
{
    [super dealloc];
}

@end
