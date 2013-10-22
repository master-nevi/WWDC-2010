
/*
     File: SimpleEditor.h
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMTime.h>


typedef enum {
	SimpleEditorTransitionTypeNone,
	SimpleEditorTransitionTypeCrossFade,
	SimpleEditorTransitionTypePush
} SimpleEditorTransitionType;


@interface SimpleEditor : NSObject 
{	
	// Configuration
	
	NSArray *_clips;			// array of AVURLAssets
	NSArray *_clipTimeRanges;	// array of CMTimeRanges stored in NSValues.
	
	AVURLAsset *_commentary;
	CMTime _commentaryStartTime;
	
	SimpleEditorTransitionType _transitionType;
	CMTime _transitionDuration;
	
	NSString *_titleText;
	
	
	// Composition objects.
	
	AVComposition *_composition;
	AVVideoComposition *_videoComposition;
	AVAudioMix *_audioMix;
	
	AVPlayerItem *_playerItem;
	AVSynchronizedLayer *_synchronizedLayer;
}

// Set these properties before building the composition objects.
@property (nonatomic, retain) NSArray *clips;
@property (nonatomic, retain) NSArray *clipTimeRanges;

@property (nonatomic, retain) AVURLAsset *commentary;
@property (nonatomic) CMTime commentaryStartTime;

@property (nonatomic) SimpleEditorTransitionType transitionType;
@property (nonatomic) CMTime transitionDuration;

@property (nonatomic, retain) NSString *titleText;


// Build the composition, videoComposition, and audioMix. 
// If the composition is being built for playback then a synchronized layer and player item are also constructed.
// All of these objects can be retrieved all of these objects with the accessors below.
// Calling buildCompositionObjectsForPlayback: will get rid of any previously created composition objects.
- (void)buildCompositionObjectsForPlayback:(BOOL)forPlayback;

@property (nonatomic, readonly, retain) AVComposition *composition;
@property (nonatomic, readonly, retain) AVVideoComposition *videoComposition;
@property (nonatomic, readonly, retain) AVAudioMix *audioMix;

- (void)getPlayerItem:(AVPlayerItem**)playerItemOut andSynchronizedLayer:(AVSynchronizedLayer**)synchronizedLayerOut;
// The synchronized layer contains a layer tree which is synchronized with the provided player item.
// Inside the layer tree there is a playerLayer along with other layers related to titling.

- (AVAssetImageGenerator*)assetImageGenerator;
- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;


@end
