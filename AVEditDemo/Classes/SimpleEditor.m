
/*
     File: SimpleEditor.m
 Abstract: Demonstrates construction of AVComposition, AVAudioMix, and AVVideoComposition. 
 
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

#import "SimpleEditor.h"

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@interface SimpleEditor ()
@property (nonatomic, readwrite, retain) AVComposition *composition;
@property (nonatomic, readwrite, retain) AVVideoComposition *videoComposition;
@property (nonatomic, readwrite, retain) AVAudioMix *audioMix;
@property (nonatomic, readwrite, retain) AVPlayerItem *playerItem;
@property (nonatomic, readwrite, retain) AVSynchronizedLayer *synchronizedLayer;

@end


@implementation SimpleEditor

- (id)init
{
	if (self = [super init]) {
		_commentaryStartTime = CMTimeMake(2, 1); // Default start time for the commentary is two seconds.
		
		_transitionDuration = CMTimeMake(1, 1); // Default transition duration is one second.
		
		// just until we have the UI for this wired up
		NSMutableArray *clipTimeRanges = [[NSMutableArray alloc] initWithCapacity:3];
		CMTimeRange defaultTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(5, 1));
		NSValue *defaultTimeRangeValue = [NSValue valueWithCMTimeRange:defaultTimeRange];
		[clipTimeRanges addObject:defaultTimeRangeValue];
		[clipTimeRanges addObject:defaultTimeRangeValue];
		[clipTimeRanges addObject:defaultTimeRangeValue];
		_clipTimeRanges = clipTimeRanges;
	}
	return self;
}

// Configuration

@synthesize clips = _clips, clipTimeRanges = _clipTimeRanges;
@synthesize commentary = _commentary, commentaryStartTime = _commentaryStartTime;
@synthesize transitionType = _transitionType, transitionDuration = _transitionDuration;
@synthesize titleText = _titleText;

// Composition objects.

@synthesize composition = _composition;
@synthesize videoComposition =_videoComposition;
@synthesize audioMix = _audioMix;
@synthesize playerItem = _playerItem;
@synthesize synchronizedLayer = _synchronizedLayer;

static CGImageRef createStarImage(CGFloat radius)
{
	int i, count = 5;
#if TARGET_OS_IPHONE
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
#else // not TARGET_OS_IPHONE
	CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
#endif // not TARGET_OS_IPHONE
	CGImageRef image = NULL;
	size_t width = 2*radius;
	size_t height = 2*radius;
	size_t bytesperrow = width * 4;
	CGContextRef context = CGBitmapContextCreate((void *)NULL, width, height, 8, bytesperrow, colorspace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	CGContextClearRect(context, CGRectMake(0, 0, 2*radius, 2*radius));
	CGContextSetLineWidth(context, radius / 15.0);
	
	for( i = 0; i < 2 * count; i++ ) {
		CGFloat angle = i * M_PI / count;
		CGFloat pointradius = (i % 2) ? radius * 0.37 : radius * 0.95;
		CGFloat x = radius + pointradius * cos(angle);
		CGFloat y = radius + pointradius * sin(angle);
		if (i == 0)
			CGContextMoveToPoint(context, x, y);
		else
			CGContextAddLineToPoint(context, x, y);
	}
	CGContextClosePath(context);
	
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	CGContextDrawPath(context, kCGPathFillStroke);
	CGColorSpaceRelease(colorspace);
	image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	return image;
}

- (void)buildSequenceComposition:(AVMutableComposition *)composition
{
	CMTime nextClipStartTime = kCMTimeZero;
	NSInteger i;
	
	// No transitions: place clips into one video track and one audio track in composition.
	
	AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	for (i = 0; i < [_clips count]; i++ ) {
		AVURLAsset *asset = [_clips objectAtIndex:i];
		NSValue *clipTimeRange = [_clipTimeRanges objectAtIndex:i];
		CMTimeRange timeRangeInAsset;
		if (clipTimeRange)
			timeRangeInAsset = [clipTimeRange CMTimeRangeValue];
		else
			timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
		
		AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		[compositionVideoTrack insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:nil];
		
		AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
		[compositionAudioTrack insertTimeRange:timeRangeInAsset ofTrack:clipAudioTrack atTime:nextClipStartTime error:nil];
		
		// Note: This is largely equivalent:
		// [composition insertTimeRange:timeRangeInAsset ofAsset:asset atTime:nextClipStartTime error:NULL];
		// except that if the video tracks dimensions do not match, additional video tracks will be added to the composition.

		nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
	}
}

- (void)buildTransitionComposition:(AVMutableComposition *)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition
{
	CMTime nextClipStartTime = kCMTimeZero;
	NSInteger i;

	// Make transitionDuration no greater than half the shortest clip duration.
	CMTime transitionDuration = self.transitionDuration;
	for (i = 0; i < [_clips count]; i++ ) {
		NSValue *clipTimeRange = [_clipTimeRanges objectAtIndex:i];
		if (clipTimeRange) {
			CMTime halfClipDuration = [clipTimeRange CMTimeRangeValue].duration;
			halfClipDuration.timescale *= 2; // You can halve a rational by doubling its denominator.
			transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration);
		}
	}
	
	// Add two video tracks and two audio tracks.
	AVMutableCompositionTrack *compositionVideoTracks[2];
	AVMutableCompositionTrack *compositionAudioTracks[2];
	compositionVideoTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionVideoTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionAudioTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	compositionAudioTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	CMTimeRange *passThroughTimeRanges = alloca(sizeof(CMTimeRange) * [_clips count]);
	CMTimeRange *transitionTimeRanges = alloca(sizeof(CMTimeRange) * [_clips count]);
	
	// Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
	for (i = 0; i < [_clips count]; i++ ) {
		NSInteger alternatingIndex = i % 2; // alternating targets: 0, 1, 0, 1, ...
		AVURLAsset *asset = [_clips objectAtIndex:i];
		NSValue *clipTimeRange = [_clipTimeRanges objectAtIndex:i];
		CMTimeRange timeRangeInAsset;
		if (clipTimeRange)
			timeRangeInAsset = [clipTimeRange CMTimeRangeValue];
		else
			timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
		
		AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		[compositionVideoTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:nil];
		
		AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
		[compositionAudioTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipAudioTrack atTime:nextClipStartTime error:nil];
		
		// Remember the time range in which this clip should pass through.
		// Every clip after the first begins with a transition.
		// Every clip before the last ends with a transition.
		// Exclude those transitions from the pass through time ranges.
		passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration);
		if (i > 0) {
			passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration);
			passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
		}
		if (i+1 < [_clips count]) {
			passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
		}
		
		// The end of this clip will overlap the start of the next by transitionDuration.
		// (Note: this arithmetic falls apart if timeRangeInAsset.duration < 2 * transitionDuration.)
		nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
		nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
		
		// Remember the time range for the transition to the next item.
		transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
	}
	
	// Set up the video composition if we are to perform crossfade or push transitions between clips.
	NSMutableArray *instructions = [NSMutableArray array];

	// Cycle between "pass through A", "transition from A to B", "pass through B", "transition from B to A".
	for (i = 0; i < [_clips count]; i++ ) {
		NSInteger alternatingIndex = i % 2; // alternating targets
		
		// Pass through clip i.
		AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		passThroughInstruction.timeRange = passThroughTimeRanges[i];
		AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]];
		
		passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
		[instructions addObject:passThroughInstruction];
		
		if (i+1 < [_clips count]) {
			// Add transition from clip i to clip i+1.
			
			AVMutableVideoCompositionInstruction *transitionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
			transitionInstruction.timeRange = transitionTimeRanges[i];
			AVMutableVideoCompositionLayerInstruction *fromLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]];
			AVMutableVideoCompositionLayerInstruction *toLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[1-alternatingIndex]];
			
			if (self.transitionType == SimpleEditorTransitionTypeCrossFade) {
				// Fade out the fromLayer by setting a ramp from 1.0 to 0.0.
				[fromLayer setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:transitionTimeRanges[i]];
			}
			else if (self.transitionType == SimpleEditorTransitionTypePush) {
				// Set a transform ramp on fromLayer from identity to all the way left of the screen.
				[fromLayer setTransformRampFromStartTransform:CGAffineTransformIdentity toEndTransform:CGAffineTransformMakeTranslation(-composition.naturalSize.width, 0.0) timeRange:transitionTimeRanges[i]];
				// Set a transform ramp on toLayer from all the way right of the screen to identity.
				[toLayer setTransformRampFromStartTransform:CGAffineTransformMakeTranslation(+composition.naturalSize.width, 0.0) toEndTransform:CGAffineTransformIdentity timeRange:transitionTimeRanges[i]];
			}
			
			transitionInstruction.layerInstructions = [NSArray arrayWithObjects:fromLayer, toLayer, nil];
			[instructions addObject:transitionInstruction];
		}
	}
		
	videoComposition.instructions = instructions;
}

- (void)addCommentaryTrackToComposition:(AVMutableComposition *)composition withAudioMix:(AVMutableAudioMix *)audioMix
{
	NSInteger i;
	NSArray *tracksToDuck = [composition tracksWithMediaType:AVMediaTypeAudio]; // before we add the commentary
	
	// Clip commentary duration to composition duration.
	CMTimeRange commentaryTimeRange = CMTimeRangeMake(self.commentaryStartTime, self.commentary.duration);
	if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(commentaryTimeRange), >, [composition duration]))
		commentaryTimeRange.duration = CMTimeSubtract([composition duration], commentaryTimeRange.start);
	
	// Add the commentary track.
	AVMutableCompositionTrack *compositionCommentaryTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	[compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, commentaryTimeRange.duration) ofTrack:[[self.commentary tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:commentaryTimeRange.start error:nil];
	
	
	NSMutableArray *trackMixArray = [NSMutableArray array];
	CMTime rampDuration = CMTimeMake(1, 2); // half-second ramps
	for (i = 0; i < [tracksToDuck count]; i++) {
		AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:[tracksToDuck objectAtIndex:i]];
		[trackMix setVolumeRampFromStartVolume:1.0 toEndVolume:0.2 timeRange:CMTimeRangeMake(CMTimeSubtract(commentaryTimeRange.start, rampDuration), rampDuration)];
		[trackMix setVolumeRampFromStartVolume:0.2 toEndVolume:1.0 timeRange:CMTimeRangeMake(CMTimeRangeGetEnd(commentaryTimeRange), rampDuration)];
		[trackMixArray addObject:trackMix];
	}
	audioMix.inputParameters = trackMixArray;
}

- (void)buildPassThroughVideoComposition:(AVMutableVideoComposition *)videoComposition forComposition:(AVMutableComposition *)composition
{
	// Make a "pass through video track" video composition.
	AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
	
	AVAssetTrack *videoTrack = [[composition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
	AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	
	passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
	videoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
}

- (CALayer *)buildAnimatedTitleLayerForSize:(CGSize)videoSize
{
	// Create a layer for the overall title animation.
	CALayer *animatedTitleLayer = [CALayer layer];
	
	// Create a layer for the text of the title.
	CATextLayer *titleLayer = [CATextLayer layer];
	titleLayer.string = self.titleText;
	titleLayer.font = @"Helvetica";
	titleLayer.fontSize = videoSize.height / 6;
	//?? titleLayer.shadowOpacity = 0.5;
	titleLayer.alignmentMode = kCAAlignmentCenter;
	titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6);
	
	// Add it to the overall layer.
	[animatedTitleLayer addSublayer:titleLayer];
	
	// Create a layer that contains a ring of stars.
	CALayer *ringOfStarsLayer = [CALayer layer];

	NSInteger starCount = 9, s;
	CGFloat starRadius = videoSize.height / 10;
	CGFloat ringRadius = videoSize.height * 0.8 / 2;
	CGImageRef starImage = createStarImage(starRadius);
	for (s = 0; s < starCount; s++) {
		CALayer *starLayer = [CALayer layer];
		CGFloat angle = s * 2 * M_PI / starCount;
		starLayer.bounds = CGRectMake(0, 0, 2 * starRadius, 2 * starRadius);
		starLayer.position = CGPointMake(ringRadius * cos(angle), ringRadius * sin(angle));
		starLayer.contents = (id)starImage;
		[ringOfStarsLayer addSublayer:starLayer];
	}
	CGImageRelease(starImage);
	
	// Rotate the ring of stars.
	CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	rotationAnimation.repeatCount = 1e100; // forever
	rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0];
	rotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
	rotationAnimation.duration = 10.0; // repeat every 10 seconds
	rotationAnimation.additive = YES;
	rotationAnimation.removedOnCompletion = NO;
	rotationAnimation.beginTime = 1e-100; // CoreAnimation automatically replaces zero beginTime with CACurrentMediaTime().  The constant AVCoreAnimationBeginTimeAtZero is also available.
	[ringOfStarsLayer addAnimation:rotationAnimation forKey:nil];
	
	// Add the ring of stars to the overall layer.
	animatedTitleLayer.position = CGPointMake(videoSize.width / 2.0, videoSize.height / 2.0);
	[animatedTitleLayer addSublayer:ringOfStarsLayer];
	
	// Animate the opacity of the overall layer so that it fades out from 3 sec to 4 sec.
	CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0];
	fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];
	fadeAnimation.additive = NO;
	fadeAnimation.removedOnCompletion = NO;
	fadeAnimation.beginTime = 10.0;
	fadeAnimation.duration = 2.0;
	fadeAnimation.fillMode = kCAFillModeBoth;
	[animatedTitleLayer addAnimation:fadeAnimation forKey:nil];
	
	return animatedTitleLayer;
}

- (void)buildCompositionObjectsForPlayback:(BOOL)forPlayback
{	
	CGSize videoSize = [[_clips objectAtIndex:0] naturalSize];
	AVMutableComposition *composition = [AVMutableComposition composition];
	AVMutableVideoComposition *videoComposition = nil;
	AVMutableAudioMix *audioMix = nil;
	CALayer *animatedTitleLayer = nil;
	
	composition.naturalSize = videoSize;
	
	if (self.transitionType == SimpleEditorTransitionTypeNone) {
		// No transitions: place clips into one video track and one audio track in composition.
		
		[self buildSequenceComposition:composition];
	}
	else {
		// With transitions:
		// Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
		// Set up the video composition to cycle between "pass through A", "transition from A to B", 
		// "pass through B", "transition from B to A".
		
		videoComposition = [AVMutableVideoComposition videoComposition];
		[self buildTransitionComposition:composition andVideoComposition:videoComposition];
	}
	
	// If one is provided, add a commentary track and duck all other audio during it.
	if (self.commentary) {
		// Add the commentary track and duck all other audio during it.
		
		audioMix = [AVMutableAudioMix audioMix];
		[self addCommentaryTrackToComposition:composition withAudioMix:audioMix];
	}
	
	// Set up Core Animation layers to contribute a title animation overlay if we have a title set.
	if (self.titleText) {
		animatedTitleLayer = [self buildAnimatedTitleLayerForSize:videoSize];
		
		if (! forPlayback) {
			// For export: build a Core Animation tree that contains both the animated title and the video.
			CALayer *parentLayer = [CALayer layer];
			CALayer *videoLayer = [CALayer layer];
			parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
			videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
			[parentLayer addSublayer:videoLayer];
			[parentLayer addSublayer:animatedTitleLayer];

			if (! videoComposition) {
				// No transition set -- make a "pass through video track" video composition so we can include the Core Animation tree as a post-processing stage.
				videoComposition = [AVMutableVideoComposition videoComposition];
				
				[self buildPassThroughVideoComposition:videoComposition forComposition:composition];
			}
			
			videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
		}
	}
	
	if (videoComposition) {
		// Every videoComposition needs these properties to be set:
		videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
		videoComposition.renderSize = videoSize;
	}
	
	self.composition = composition;
	self.videoComposition = videoComposition;
	self.audioMix = audioMix;

	self.synchronizedLayer = nil;
	
	if (forPlayback) {
#if TARGET_OS_EMBEDDED
		// Render high-def movies at half scale for real-time playback (device-only).
		if (videoSize.width > 640)
			videoComposition.renderScale = 0.5;
#endif // TARGET_OS_EMBEDDED
		
		AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
		playerItem.videoComposition = videoComposition;
		playerItem.audioMix = audioMix;
		self.playerItem = playerItem;

		if (animatedTitleLayer) {
			// Build an AVSynchronizedLayer that contains the animated title.
			self.synchronizedLayer = [AVSynchronizedLayer synchronizedLayerWithPlayerItem:self.playerItem];
			self.synchronizedLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height);
			[self.synchronizedLayer addSublayer:animatedTitleLayer];
		}
	}
}

- (void)getPlayerItem:(AVPlayerItem**)playerItemOut andSynchronizedLayer:(AVSynchronizedLayer**)synchronizedLayerOut
{
	if (playerItemOut) {
		*playerItemOut = _playerItem;
	}
	if (synchronizedLayerOut) {
		*synchronizedLayerOut = _synchronizedLayer;
	}
}

- (AVAssetImageGenerator*)assetImageGenerator
{
	AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.composition];
	generator.videoComposition = self.videoComposition;
	return generator;
}

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName
{
	AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:presetName];
	session.videoComposition = self.videoComposition;
	session.audioMix = self.audioMix;
	return [session autorelease];
}

- (void)dealloc 
{
	[_clips release];
	[_clipTimeRanges release];
	
	[_commentary release];	
	[_titleText release];
	
	
	[_composition release];
	[_videoComposition release];
	[_audioMix release];
	
	[_playerItem release];
	[_synchronizedLayer release];
	
    [super dealloc];
}

@end
