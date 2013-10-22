
/*
     File: AssetBrowserSource.m
 Abstract: A source for AssetBrowserController to find assets in. 
 
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

#import "AssetBrowserSource.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <MobileCoreServices/UTType.h>

@implementation AssetBrowserSource

@synthesize name = _sourceName, assetItems = _assetItems, delegate = _delegate, type = _sourceType;

- (NSString*)_nameForSourceType
{
	NSString *sourceName = nil;
	
	switch (_sourceType) {
		case AssetBrowserSourceTypeFileSharing:
			sourceName = @"File Sharing";
			break;
		default:
			sourceName = nil;
			break;
	}
	
	return sourceName;
}

+ (AssetBrowserSource*)assetSourceOfType:(AssetBrowserSourceType)sourceType
{
	return [[[self alloc] initWithSourceType:sourceType] autorelease];
}

- (id)initWithSourceType:(AssetBrowserSourceType)sourceType
{
	if (self = [super init]) {
		_sourceType = sourceType;
		self.name = [self _nameForSourceType];
		self.assetItems = [NSArray array];
	}
	return self;
}

- (void)updateAssetItemsAndSignalDelegate:(NSMutableArray*)newItems
{	
	NSArray *immutableAssetItems = [newItems copy];
	self.assetItems = immutableAssetItems;
	[immutableAssetItems release];
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(assetSourceLibraryDidChange:)]) {
		[self.delegate assetSourceLibraryDidChange:self];
	}
}

- (void)updateLibraryFromFolderAtPath:(NSString*)directoryPath
{
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:0];
	NSArray *subPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
	if (subPaths) {
		for (NSString *subPath in subPaths) {
			NSString *pathExtension = [subPath pathExtension];
			CFStringRef preferredUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)pathExtension, NULL);
			BOOL fileConformsToUTI = UTTypeConformsTo(preferredUTI, kUTTypeAudiovisualContent);
			CFRelease(preferredUTI);
			NSString *path = [directoryPath stringByAppendingPathComponent:subPath];
			
			if (fileConformsToUTI) {
				[paths addObject:path];
			}
		}
	}

	// A better approach would be to keep around a dictionary of assetURLs -> AssetBrowserItems
	// Then try to pull from that dictionary before creating a new AssetBrowserItem.
	// This way thumbnail and other caches will be preserved between library updates.
	// Also this would make it easier to figure out which indicies were added/removed so that
	// the view controller could animate the table view cell changes.
	
	NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:0];
	for (NSString *path in paths) {
		AssetBrowserItem *item = [[[AssetBrowserItem alloc] initWithURL:[NSURL fileURLWithPath:path]] autorelease];
		[items addObject:item];
	}
	
	[self updateAssetItemsAndSignalDelegate:items];	
	[items release];
}

- (void)updateFileSharingLibrary
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	[self updateLibraryFromFolderAtPath:documentsDirectory];
}

- (void)buildFileSharingLibrary
{
	[self updateFileSharingLibrary];
}
	 
- (void)buildSourceLibrary
{
	switch (_sourceType) {
		case AssetBrowserSourceTypeFileSharing:
			[self buildFileSharingLibrary];
			break;
		default:
			break;
	}
}

- (void)dealloc 
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_sourceName release];
	[_assetItems release];
	
	_delegate = nil;
	[super dealloc];
}

@end
