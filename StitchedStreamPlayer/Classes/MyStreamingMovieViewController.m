/*
    File: MyStreamingMovieViewController.m
Abstract: 
A UIViewController controller subclass that loads the SecondView nib file that contains its view.
 Contains an action method that is called when the Play Movie button is pressed to play the movie.
 Provides a text edit control for the user to enter a movie URL.
 Manages a collection of transport control UI that allows the user to play/pause and seek.

 Version: 1.2

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

#import "MyStreamingMovieViewController.h"

#import "MyPlayerLayerView.h"

#import <AVFoundation/AVFoundation.h>

static void *MyStreamingMovieViewControllerTimedMetadataObserverContext = @"MyStreamingMovieViewControllerTimedMetadataObserverContext";
static void *MyStreamingMovieViewControllerSeekableTimeRangesObserverContext = @"MyStreamingMovieViewControllerSeekableTimeRangesObserverContext";

@implementation MyStreamingMovieViewController

@synthesize movieURLTextField;
@synthesize controlView;
@synthesize movieTimeControl;
@synthesize sliderWell;
@synthesize playerLayerView;

- (void)dealloc
{
	[player removeObserver:self forKeyPath:@"currentItem.timedMetadata"];
	[player removeObserver:self forKeyPath:@"currentItem.seekableTimeRanges"];
	
	[player release]; 
	[adList release];
	[adViews release];
	
	[movieURLTextField release];
	[controlView release];
	[movieTimeControl release];
	[sliderWell release];
	[playerLayerView release];
	
    [super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIImage *thumb = [UIImage imageNamed:@"playhead.png"];
	[movieTimeControl setThumbImage:thumb forState:UIControlStateNormal];
	
	UIImage *white = [UIImage imageNamed:@"16x16white.png"];
	[movieTimeControl setMinimumTrackImage:[white stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0]
								  forState:UIControlStateNormal];
	[movieTimeControl setMaximumTrackImage:[white stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0]
								  forState:UIControlStateNormal];

	[movieTimeControl addTarget:self action:@selector(sliderDragBeganAction) forControlEvents:UIControlEventTouchDown];
	[movieTimeControl addTarget:self action:@selector(sliderDragEndedAction) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
	[movieTimeControl addTarget:self action:@selector(sliderValueChange) forControlEvents:UIControlEventValueChanged];	
}

- (void)updateTimeControl
{
	[movieTimeControl setValue:CMTimeGetSeconds([player currentTime])];
}

- (void)sliderDragBeganAction
{
	isSeeking = YES;
}

- (void)sliderDragEndedAction
{
	isSeeking = NO;
}

- (void)sliderValueChange
{
	// seek when user moves slider
	[player seekToTime:CMTimeMakeWithSeconds(movieTimeControl.value, 1000)];
}

- (void)startObservingTimeChanges
{
	if (!playerTimeObserver) {
		playerTimeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:NULL usingBlock:
							   ^(CMTime time) {
								   if ( NO == isSeeking) {
									   [self updateTimeControl];
								   }
							   }] retain];
	}
}

- (void)stopObservingTimeChanges
{
	if (playerTimeObserver) {
		[player removeTimeObserver:playerTimeObserver];
		[playerTimeObserver release];
		playerTimeObserver = nil;
	}
}

- (void) itemDidPlayToEnd:(NSNotification*) aNotification 
{
	seekToZeroBeforePlay = YES;
}

- (void)loadMovieWithURL:(NSURL *)newMovieURL
{
	if (!movieURL || ![movieURL isEqual:newMovieURL]) {
		newMovieURL = [newMovieURL copy];
		[movieURL release];
		movieURL = newMovieURL;
		
		[[NSNotificationCenter defaultCenter]
			removeObserver:self
			name:AVPlayerItemDidPlayToEndTimeNotification
			object:nil];

		[player removeObserver:self forKeyPath:@"currentItem.timedMetadata"];
		[player removeObserver:self forKeyPath:@"currentItem.seekableTimeRanges"];
		[player pause];
		[player release];
		
		player = [[AVPlayer alloc] initWithURL:newMovieURL];
		if (player)
		{
			[[NSNotificationCenter defaultCenter]
				addObserver:self
				selector:@selector(itemDidPlayToEnd:)
				name:AVPlayerItemDidPlayToEndTimeNotification
				object:player.currentItem];

			seekToZeroBeforePlay = NO;
	
			[player addObserver:self forKeyPath:@"currentItem.timedMetadata" options:0 context:MyStreamingMovieViewControllerTimedMetadataObserverContext];
			[player addObserver:self forKeyPath:@"currentItem.seekableTimeRanges" options:NSKeyValueObservingOptionInitial context:MyStreamingMovieViewControllerSeekableTimeRangesObserverContext];
			
			[self startObservingTimeChanges];
			
			playerLayerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
			playerLayerView.playerLayer.hidden = YES;
			
			// Play the movie!
			[player play];
		}
		
		[playerLayerView.playerLayer setPlayer:player];
	}
}

// Only observre time changes when the view controller's view is visible.
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self startObservingTimeChanges];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[self stopObservingTimeChanges];
}

- (void)updateAdViews
{
	// remove old ad views
	for (UIView *oldAdView in adViews) {
		[oldAdView removeFromSuperview];
	}
	[adViews release];
	adViews = nil;		
	
	if (adList) {
		// pause playback and set up the playback controller when we discover the ad list
		[player setRate:0.0];
		
		playerLayerView.playerLayer.hidden = NO;
		
		NSArray *seekableTimeRanges = [[player currentItem] seekableTimeRanges];
		if ([seekableTimeRanges count] > 0) {
			NSValue *range = [seekableTimeRanges objectAtIndex:0];
			CMTimeRange timeRange = [range CMTimeRangeValue];
			float startSeconds = CMTimeGetSeconds(timeRange.start);
			float durationSeconds = CMTimeGetSeconds(timeRange.duration);
			
			// Set the minimum and maximum values of the time slider to match the seekable time range.
			movieTimeControl.minimumValue = startSeconds;
			movieTimeControl.maximumValue = startSeconds + durationSeconds;
			
			// add subviews to sliderWell to color areas of ads
			UIColor *colors[] = {[UIColor redColor], [UIColor greenColor], [UIColor magentaColor]};
			size_t numberOfColors = sizeof(colors) / sizeof(colors[0]);
			NSInteger index = 0;
			NSMutableArray *mutableAdViews = [NSMutableArray arrayWithCapacity:[adList count]];
			for (NSDictionary *adInfo in adList) {
				NSNumber *startTime = [adInfo objectForKey:@"start-time"];
				NSNumber *endTime = [adInfo objectForKey:@"end-time"];
				float adStart = [startTime floatValue];
				float adLen = [endTime floatValue] - adStart;
				CGRect sliderRect = movieTimeControl.bounds;
				CGSize thumbSize = [movieTimeControl currentThumbImage].size;
				CGFloat sliderLen = sliderRect.size.width - thumbSize.width;
				CGRect adFrame = sliderRect;
				adFrame.origin.x = adStart / durationSeconds * sliderLen + sliderRect.origin.x + thumbSize.width / 2;
				adFrame.size.width = adLen / durationSeconds * sliderLen;
				adFrame = [[movieTimeControl superview] convertRect:adFrame fromView:movieTimeControl];
				adFrame = [sliderWell convertRect:adFrame fromView:[movieTimeControl superview]];
				adFrame.origin.y = 0;
				adFrame.size.height = sliderWell.bounds.size.height;
				
				UIView *adView = [[UIView alloc] initWithFrame:adFrame];
				adView.backgroundColor = colors[(index++) % numberOfColors];
				[sliderWell addSubview:adView];
				[mutableAdViews addObject:adView];
				[adView release];
			}
			
			adViews = [mutableAdViews copy];
			
			controlView.hidden = NO;
		}
	}	
}

- (void)updateAdList:(NSArray *)newAdList
{
	if (!adList || ![adList isEqualToArray:newAdList]) {
		newAdList = [newAdList copy];
		[adList release];
		adList = newAdList;
		
		[self updateAdViews];
	}
}	

- (void)updateControlViewForNewSeekableTimeRanges
{
	AVPlayerItem *currentItem = [player currentItem];
	NSArray *seekableTimeRanges = [currentItem seekableTimeRanges];
	
	if ([seekableTimeRanges count] > 0) {
		// update the layout of the ad views to reflect the new time ranges.
		[self updateAdViews];
	}
	else {
		controlView.hidden = YES;
	}
}

- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata
{
	// We expect the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries.
	if ([(NSString *)[timedMetadata key] isEqualToString:AVMetadataID3MetadataKeyGeneralEncapsulatedObject]) {
		if ([[timedMetadata value] isKindOfClass:[NSDictionary class]]) {
			NSDictionary *propertyList = (NSDictionary *)[timedMetadata value];

			// metadata payload could be the list of ads
			NSArray *newAdList = [propertyList objectForKey:@"ad-list"];
			if (newAdList != nil) {
				[self updateAdList:newAdList];
				NSLog(@"ad-list is %@", newAdList);
			}

			// or it might be an ad record
			NSString *adURL = [propertyList objectForKey:@"url"];
			if (adURL != nil) {
				if ([adURL isEqualToString:@""]) {
					movieTimeControl.enabled = YES;	// enable seeking for main content
					NSLog(@"enabling seek at %g", CMTimeGetSeconds([player currentTime]));
				}
				else {
					movieTimeControl.enabled = NO;	// disable seeking for ad content
					NSLog(@"disabling seek at %g", CMTimeGetSeconds([player currentTime]));
				}
			}
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == MyStreamingMovieViewControllerTimedMetadataObserverContext) {
		NSArray* array = [[player currentItem] timedMetadata];
		for (AVMetadataItem *metadataItem in array) {
			[self handleTimedMetadata:metadataItem];
		}
	}
	else if (context == MyStreamingMovieViewControllerSeekableTimeRangesObserverContext) {
		[self updateControlViewForNewSeekableTimeRanges];
	}	
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (IBAction)loadMovieButtonPressed:(id)sender
{
	// Has the user entered a movie URL?
	if (self.movieURLTextField.text.length > 0)
	{
		NSURL *newMovieURL = [NSURL URLWithString:self.movieURLTextField.text];
		if ([newMovieURL scheme])	// sanity check on the URL
		{
			// Instantiate an AVPlayer with movieURL and play it,
			[self loadMovieWithURL:newMovieURL];
		}
	}
}

- (IBAction)playPauseButtonPressed:(id)sender
{
	if ( player.rate == 0.0) {
		// if we are at the end of the movie we must seek to the beginning first before starting playback
		if (YES == seekToZeroBeforePlay) {
			seekToZeroBeforePlay = NO;
			[player seekToTime:kCMTimeZero];
		}
		player.rate = 1.0;
	} else {
		player.rate = 0.0;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	// When the user presses return, take focus away from the text field so that the keyboard is dismissed.
	if (theTextField == self.movieURLTextField) {
		[self.movieURLTextField resignFirstResponder];
	}
	
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}

@end
