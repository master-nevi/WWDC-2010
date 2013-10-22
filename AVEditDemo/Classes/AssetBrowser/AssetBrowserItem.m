
/*
     File: AssetBrowserItem.m
 Abstract: Represents an asset in AssetBrowserController. 
 
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

#import "AssetBrowserItem.h"

#import <AVFoundation/AVFoundation.h>


@interface AssetBrowserItem ()

- (AVAsset*)assetIfCreated;

@property (nonatomic, retain) UIImage *thumbnailImage;

@end

@implementation AssetBrowserItem

@synthesize URL = _URL, title = _title, thumbnailTime = _thumbnailTime;
@synthesize canGenerateThumbnailImage = _canGenerateThumbnailImage, audioOnly = _audioOnly;

- (id)initWithURL:(NSURL*)URL
{
	return [self initWithURL:URL andTitle:nil];
}

// Do simple equality based on the item's URL.
- (BOOL)isEqual:(id)anObject
{
	if ([anObject isKindOfClass:[AssetBrowserItem class]]) {
		AssetBrowserItem *item = anObject;
		NSURL *myURL = self.URL;
		NSURL *theirURL = item.URL;
		if (myURL && theirURL) {
			return [myURL isEqual:theirURL];
		}
		return NO;
	}
	return NO;
}

- (NSUInteger)hash
{
	if (self.URL) {
		return [self.URL hash];
	}
	else {
		return [super hash];
	}
}

- (id)initWithURL:(NSURL*)URL andTitle:(NSString*)title
{
	if (self = [super init]) {
		_URL = [URL retain];
		if (_URL == nil) {
			[self release];
			return nil;
		}
		_title = title ? [title retain] : [[[URL lastPathComponent] stringByDeletingPathExtension] retain];
		
		// Assume we can generate a thumb unless we have loaded the assets or tried already and know otherwise.
		_canGenerateThumbnailImage = YES;
	}
	return self;
}

- (id)initWithAssetItem:(AssetBrowserItem*)asset
{
	if (self = [super init]) {
		// Inititialization time properties.
		_URL = [asset.URL retain];
		// May have been an initialization time property.
		_title = [asset.title retain];
		
		_thumbnailImage = [asset.thumbnailImage retain];
		_asset = [[asset assetIfCreated] retain];
		
		_canGenerateThumbnailImage = asset.canGenerateThumbnailImage;
		_audioOnly = asset.audioOnly;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	AssetBrowserItem *itemCopy = [[AssetBrowserItem allocWithZone:zone] initWithAssetItem:self];
	return itemCopy;
}

- (AVAsset*)copyAssetIsAudioOnly:(BOOL*)audioOnlyOut canGenerateThumbnail:(BOOL*)canGenerateThumbnailOut
{
	BOOL audioOnly = NO;
	BOOL canGenerateThumbnail = YES;
	
	AVAsset *theAsset = [[AVURLAsset alloc] initWithURL:_URL options:nil];	
	NSArray *videoTracks = theAsset ? [theAsset tracksWithMediaType:AVMediaTypeVideo] : nil;
	if ( (videoTracks == nil) || ([videoTracks count] == 0) ) {
		canGenerateThumbnail = NO;
		NSArray *audioTracks = theAsset ? [theAsset tracksWithMediaType:AVMediaTypeAudio] : nil;
		if ( (audioTracks != nil) && ([audioTracks count] != 0) ) {
			audioOnly = YES;
		}
	}
	
	if (audioOnlyOut)
		*audioOnlyOut = audioOnly;
	if (canGenerateThumbnailOut)
		*canGenerateThumbnailOut = canGenerateThumbnail;
	
	return theAsset;
}

- (AVAsset*)asset
{	
	// Lazy initialization of the asset.
	if (_asset == nil) 
	{
		_asset = [self copyAssetIsAudioOnly:&_audioOnly canGenerateThumbnail:&_canGenerateThumbnailImage];
	}
		
	return _asset;
}

- (AVAsset*)assetIfCreated
{	
	return _asset;
}

CGRect makeRectWithAspectRatioOutsideRect(CGSize aspectRatio, CGRect containerRect)
{
	CGSize scale = CGSizeMake(containerRect.size.width / aspectRatio.width, containerRect.size.height / aspectRatio.height);
	CGFloat maxScale = fmax(scale.width, scale.height);
	
	CGPoint centerPoint = CGPointMake(CGRectGetMidX(containerRect), CGRectGetMidY(containerRect));
	CGSize size = CGSizeMake(aspectRatio.width * maxScale, aspectRatio.height * maxScale);
	return CGRectMake(centerPoint.x - 0.5f * size.width, centerPoint.y - 0.5f * size.height, size.width, size.height);
}

- (CGSize)maxSizeForImageGeneratorToCropAsset:(AVAsset*)localAsset toSize:(CGSize)size
{
	CGSize naturalSize = localAsset.naturalSize;
	CGSize naturalSizeTransformed = CGSizeApplyAffineTransform (naturalSize, localAsset.preferredTransform);
	naturalSizeTransformed.width = fabs(naturalSizeTransformed.width);
	naturalSizeTransformed.height = fabs(naturalSizeTransformed.height);
	
	NSArray *videoTracks = localAsset ? [localAsset tracksWithMediaType:AVMediaTypeVideo] : nil;
	if ( (videoTracks != nil) && ([videoTracks count] > 0) ) {
		AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
		naturalSize = videoTrack.naturalSize;
		naturalSizeTransformed = CGSizeApplyAffineTransform (naturalSize, videoTrack.preferredTransform);
		naturalSizeTransformed.width = fabs(naturalSizeTransformed.width);
		naturalSizeTransformed.height = fabs(naturalSizeTransformed.height);
	}
	
	
	CGRect croppedRect = CGRectZero;
	croppedRect.size = size;
	CGRect containerRect = makeRectWithAspectRatioOutsideRect(naturalSizeTransformed, croppedRect);
	containerRect.origin = CGPointZero;
	containerRect = CGRectIntegral(containerRect);
	
	return containerRect.size;
}

- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size
{
	UIImage *thumbUIImage = nil;
	
	CGRect thumbRect = CGRectMake(0.0, 0.0, CGImageGetWidth(image), CGImageGetHeight(image));
	CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(size, thumbRect);
	cropRect.origin.x = round(cropRect.origin.x);
	cropRect.origin.y = round(cropRect.origin.y);
	cropRect = CGRectIntegral(cropRect);
	CGImageRef croppedThumbImage = CGImageCreateWithImageInRect(image, cropRect);
	thumbUIImage = [[UIImage alloc] initWithCGImage:croppedThumbImage];
	CGImageRelease(croppedThumbImage);
	
	return thumbUIImage;
}

- (void)generateThumbnailWithSize:(CGSize)size fillMode:(AssetBrowserItemFillMode)mode
{	
	if ( (mode == AssetBrowserItemFillModeCrop) && CGSizeEqualToSize(size, CGSizeZero) ) {
		return;
	}
	
	// Lazy creation of the asset.	
	self.asset;
	
	NSError *error = nil;
	AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_asset];
	
	imageGenerator.appliesPreferredTrackTransform = YES;
	
	if ( (mode == AssetBrowserItemFillModeAspectFit) && !CGSizeEqualToSize(size, CGSizeZero) )
		imageGenerator.maximumSize = size;
	if ( mode == AssetBrowserItemFillModeCrop ) {
		imageGenerator.maximumSize = [self maxSizeForImageGeneratorToCropAsset:_asset toSize:size];
	}
	
	CMTime imageTime = _thumbnailTime;
	if (CMTIME_IS_INVALID(imageTime))
		imageTime = CMTimeMake(2, 1);
	CGImageRef cgImage = [imageGenerator copyCGImageAtTime:imageTime actualTime:NULL error:&error];
	if (error)
		NSLog(@"_generateThumbWithSize error:%@", error);
	
	UIImage *image = nil;
	
	if (cgImage) {
		if (mode == AssetBrowserItemFillModeCrop) {
			image = [self copyImageFromCGImage:cgImage croppedToSize:size];
		}
		else {
			image = [[UIImage alloc] initWithCGImage:cgImage];
		}
	}
	
	CGImageRelease(cgImage);
	
	[_thumbnailImage release];
	_thumbnailImage = image;
}

- (void)generateThumbnailAsynchronouslyWithSize:(CGSize)size fillMode:(AssetBrowserItemFillMode)mode completionHandler:(void (^)(UIImage *thumbnail, NSError *error))handler
{
	__block BOOL canGenerateThumbnail = _canGenerateThumbnailImage;
	__block BOOL isAudioOnly = _audioOnly;
	
	if (canGenerateThumbnail == NO) {
		if (handler)
			handler(nil, nil);
		return;
	}
	
	__block AVAsset *localAsset = [_asset retain];
	
	CMTime imageTime = _thumbnailTime;
	if (CMTIME_IS_INVALID(imageTime))
		imageTime = CMTimeMake(2, 1);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[localAsset autorelease];
		
		if (localAsset == nil) {
			localAsset = [[self copyAssetIsAudioOnly:&isAudioOnly canGenerateThumbnail:&canGenerateThumbnail] autorelease];
		}
		
		if (canGenerateThumbnail == NO) {
			dispatch_async(dispatch_get_main_queue(), ^{
				_canGenerateThumbnailImage = canGenerateThumbnail;
				_audioOnly = isAudioOnly;
				if (handler) {
					handler(nil, nil);
				}
			});
		}
		else if ( (mode == AssetBrowserItemFillModeCrop) && CGSizeEqualToSize(size, CGSizeZero) ) {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSLog(@"generateThumbnailAsynchronouslyWithSize: size is zero but mode is crop, returning nil");
				_canGenerateThumbnailImage = canGenerateThumbnail;
				_audioOnly = isAudioOnly;
				if (handler) {
					handler(nil, nil);
				}
			});
		}
		else {
			AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:localAsset];
			
			imageGenerator.appliesPreferredTrackTransform = YES;
			
			if ( (mode == AssetBrowserItemFillModeAspectFit) && !CGSizeEqualToSize(size, CGSizeZero) )
				imageGenerator.maximumSize = size;
			if ( mode == AssetBrowserItemFillModeCrop ) {
				imageGenerator.maximumSize = [self maxSizeForImageGeneratorToCropAsset:localAsset toSize:size];
			}
			
			NSValue *imageTimeValue = [NSValue valueWithCMTime:imageTime];
			
			[imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:imageTimeValue] completionHandler:
			^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) 
			{	
				UIImage *thumbUIImage = nil;
				if (image) {
					if (mode == AssetBrowserItemFillModeCrop) {
						thumbUIImage = [self copyImageFromCGImage:image croppedToSize:size];
					}
					else {
						thumbUIImage = [[UIImage alloc] initWithCGImage:image];
					}
				}
				
				[imageGenerator release];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					self.thumbnailImage = thumbUIImage;
					[thumbUIImage release];

					if (result == AVAssetImageGeneratorFailed)
						canGenerateThumbnail = NO;
					
					_canGenerateThumbnailImage = canGenerateThumbnail;
					_audioOnly = isAudioOnly;
					if (handler) {
						handler(_thumbnailImage, error);
					}
				});
			}];
		}
		
		[pool drain];
	});

}

- (UIImage*)placeHolderImage
{
	UIImage *thumb = nil;
	if (self.audioOnly) {
		thumb = [UIImage imageNamed:@"AudioOnly"];
	}
	else if (!self.canGenerateThumbnailImage) {
		thumb = [UIImage imageNamed:@"ErrorLoading"];
	}
	else {
		thumb = [UIImage imageNamed:@"Placeholder"];
	}
	return thumb;
}

@synthesize thumbnailImage = _thumbnailImage;

- (void)clearThumbnailCache
{
	self.thumbnailImage = nil;
}

- (void)clearAssetCache
{
	[_asset release];
	_asset = nil;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<AssetItem: %p, '%@'>", self, self.title];
}

- (void)dealloc 
{
	[_URL release];
	[_title release];
	
	[self clearThumbnailCache];
	[self clearAssetCache];
	
	[super dealloc];
}
@end
