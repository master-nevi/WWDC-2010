
/*
     File: PlayerViewController.m
 Abstract: View controller for composition playback. 
 
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

#import "PlayerViewController.h"

#import "PlayerView.h"
#import "SimpleEditor.h"

#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVSynchronizedLayer.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVUtilities.h>
#import <QuartzCore/QuartzCore.h>

@implementation PlayerViewController

@synthesize player = _player, editor = _editor;

- (id)initWithEditor:(SimpleEditor *)editor
{
    if ((self = [super initWithNibName:@"Player" bundle:nil])) {
		self.editor = editor;
		self.title = @"Player";
		self.wantsFullScreenLayout = YES;
    }
	return self;
}

- (void)updateSyncLayerPositionAndTransform
{
	CGSize presentationSize = [self.editor.composition naturalSize];
	CGSize viewSize = self.view.bounds.size;
	CGFloat scale = fmin(viewSize.width/presentationSize.width, viewSize.height/presentationSize.height);
	CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(presentationSize, self.view.bounds);
	_syncContainer.center = CGPointMake( CGRectGetMidX(videoRect), CGRectGetMidY(videoRect));
	_syncContainer.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void)addTimeObserverToPlayer
{
	if (_timeObserver)
		return;
	
	double interval = 0.1;
	AVAsset *asset = (AVAsset *)self.editor.composition;
	
	if (asset)
	{
		double duration = CMTimeGetSeconds([asset duration]);
		
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([_scrubber bounds]);
			interval = 0.5 * duration / width;
		}
	}
	
	_timeObserver = [[_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
					  ^(CMTime time) {
						  [self syncScrubber];
						  [self syncTimeLabel];
					  }] retain];
}

- (void)removeTimeObserverFromPlayer
{
	if (_timeObserver)
	{
		[_player removeTimeObserver:_timeObserver];
		[_timeObserver release];
		_timeObserver = nil;
	}
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	UITapGestureRecognizer *recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsHidden:)] autorelease];
	recognizer.delegate = self;
	[self.view addGestureRecognizer:recognizer];
	
	self.player = [[[AVPlayer alloc] init] autorelease];
	[_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
	[(PlayerView *)self.view setPlayer:_player];
	
	[self.editor buildCompositionObjectsForPlayback:YES];
	
	AVPlayerItem *playerItem = nil;
	AVSynchronizedLayer *syncLayer = nil;
	[self.editor getPlayerItem:&playerItem andSynchronizedLayer:&syncLayer];
	[_player replaceCurrentItemWithPlayerItem:playerItem];
	
	_currentTimeLabel.text = @"0:00";
	[self syncScrubber];
	[self syncTimeLabel];
	
	if (syncLayer) {
		// A 0x0 UIView for positioning the sync layer.
		// We don't want to set properties on the sync layer directly since they would be in the movie's timebase.
		// A work around is to disable actions for the transaction, but this means you can't set an animation
		// on the sync layer, which we would need to do during screen rotation.
		_syncContainer = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		
		[_syncContainer.layer addSublayer:syncLayer];
		[self updateSyncLayerPositionAndTransform];
		[self.view insertSubview:_syncContainer belowSubview:_toolbar];
	}

}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	// Let the subviews handle their own touches.	
	return ([touch.view isEqual:gestureRecognizer.view]) ? YES : NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait) || UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	if (_syncContainer) 
	{
		[self updateSyncLayerPositionAndTransform];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[self addTimeObserverToPlayer];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self removeTimeObserverFromPlayer];
}

#pragma mark -
#pragma mark Playback Controls

- (void)toggleControlsHidden:(id)sender
{
	_controlsHidden = !_controlsHidden;

	// If we are unhiding and have switched orientations since hiding then we need to relayout the navBar ourselves.
	if (_controlsHidden == NO) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO];
		CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
		CGFloat statusBarHeight = UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? statusBarSize.width : statusBarSize.height;

		CGRect frame = self.navigationController.navigationBar.frame;
		frame.origin.y = statusBarHeight;
		self.navigationController.navigationBar.frame = frame;
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
	}
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:_controlsHidden ? 0.27 : 0.23];
	
	CGFloat newAlpha = _controlsHidden ? 0.0 : 1.0;
	[[UIApplication sharedApplication] setStatusBarHidden:_controlsHidden withAnimation:UIStatusBarAnimationFade];
	self.navigationController.navigationBar.alpha = newAlpha;
	_toolbar.alpha = newAlpha;
	_currentTimeLabel.alpha = newAlpha;
	
	[UIView commitAnimations];
}
	
- (void)updatePlayPauseButton
{
	// Grab an up to date position for the scrubber.
	[_toolbar layoutIfNeeded];
	CGPoint oldSrubberPosition = _scrubber.center;
	
	UIBarButtonSystemItem style = _playing ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay;
	UIBarButtonItem *newPlayPauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:style target:self action:@selector(togglePlayPause:)];
	
	NSMutableArray *items = [[_toolbar items] mutableCopy];
	[items replaceObjectAtIndex:[items indexOfObject:_playPauseButton] withObject:newPlayPauseButton];
	[_toolbar setItems:items];
	[items release];
	
	_playPauseButton = newPlayPauseButton;
	
	// Keep the scrubber at the same position after updating the play/pause button.
	[_toolbar layoutIfNeeded];
	CGPoint newSrubberPosition = _scrubber.center;
	CGFloat scrubberXOffset = newSrubberPosition.x - oldSrubberPosition.x;
	_scrubberSpacer.width -= scrubberXOffset;
	[_toolbar setNeedsLayout];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_player && object == _player && [keyPath isEqualToString:@"rate"]) {
		float newRate = [[change objectForKey:@"new"] floatValue];
		_playing = newRate != 0.0;
		[self updatePlayPauseButton];
    }
}

- (void)togglePlayPause:(id)sender
{
	_playing = !_playing;
	_playing ? [_player play] : [_player pause];
	[self updatePlayPauseButton];
}

- (void)syncTimeLabel
{
	double seconds = CMTimeGetSeconds([_player currentTime]);
	if (isfinite(seconds)) {
		if (seconds < 0.0) {
			seconds = 0.0;
		}
		int secondsInt = round(seconds);
		int minutes = secondsInt/60;
		secondsInt -= minutes*60;
		int secondsOnes = secondsInt%10;
		int secondsTens = secondsInt/10;

		_currentTimeLabel.text = [NSString stringWithFormat:@"%i:%i%i", minutes, secondsTens, secondsOnes];
	}
}

- (void)syncScrubber
{
	AVAsset *asset = (AVAsset *)self.editor.composition;
	
	if (!asset)
		return;
	
	double duration = CMTimeGetSeconds([asset duration]);
	
	if (isfinite(duration))
	{
		double time = CMTimeGetSeconds([_player currentTime]);
		
		[_scrubber setValue:time / duration];
	}
}

- (void)beginScrubbing:(id)sender
{
	_playRateToRestore = [_player rate];
	[_player setRate:0.0];
	
	[self removeTimeObserverFromPlayer];
}

- (void)scrub:(id)sender
{	
	AVAsset *asset = (AVAsset *)self.editor.composition;
	
	if (!asset)
		return;
	
	double duration = CMTimeGetSeconds([asset duration]);
	
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([_scrubber bounds]);
		
		float value = [_scrubber value];
		double time = duration*value;
		double tolerance = 1.0f * duration / width;
		
		[_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) 
			toleranceBefore:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) 
			 toleranceAfter:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)];
	}
	
	[self syncTimeLabel];
}

- (void)endScrubbing:(id)sender
{
	[self addTimeObserverToPlayer];
	
	[_player setRate:_playRateToRestore];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
	[super viewDidUnload];
	
	_syncContainer = nil;
	[self removeTimeObserverFromPlayer];
	[_player removeObserver:self forKeyPath:@"rate"];
    self.player = nil;
}


- (void)dealloc 
{	
	[_editor release];
	
	[self removeTimeObserverFromPlayer];
	[_player removeObserver:self forKeyPath:@"rate"];
	[_player release];
	
    [super dealloc];
}


@end
