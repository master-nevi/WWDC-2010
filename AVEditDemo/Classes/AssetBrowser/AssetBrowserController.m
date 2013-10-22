
/*
     File: AssetBrowserController.m
 Abstract: A view controller for asset selection. 
 
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

#import "AssetBrowserController.h"

#import "AssetBrowserSource.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MobileCoreServices/UTCoreTypes.h>

#define ONLY_GENERATE_THUMBS_WHEN_NOT_SCROLLING 1

@interface AssetBrowserController (AssetBrowserControllerPrivate) <AssetBrowserSourceDelegate, UIScrollViewDelegate,UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>
- (void)updateCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)updateActiveAssetSources;
- (void)enableThumbnailGeneration;
- (void)disableThumbnailGeneration;
- (void)updateThumbnails;
- (void)generateThumbnails;

@end

NSString *const kAssetBrowserGenerateThumbnails = @"AssetBrowserGenerateThumbnails";

@implementation AssetBrowserController

@synthesize assetSources = _assetSources;
@synthesize delegate = _delegate;

enum {
	AssetBrowserScrollDirectionDown,
    AssetBrowserScrollDirectionUp
};

#pragma mark -
#pragma mark Initialization

- (id)init
{
	return [self initWithSourceType:AssetBrowserSourceTypeAll];
}

- (id)initWithSourceType:(AssetBrowserSourceType)sourceType
{
    if ((self = [super initWithStyle:UITableViewStylePlain])) 
	{
		_sourceType = sourceType;
		if ((_sourceType & AssetBrowserSourceTypeAll) == 0) {
			NSLog(@"AssetBrowserController: Invalid sourceType");
			[self release];
			return nil;
		}
		
		self.wantsFullScreenLayout = YES;
		self.title = @"Assets";
		
		_thumbnailScale = [[UIScreen mainScreen] scale];
		
		_activeAssetSources = [[NSMutableArray alloc] initWithCapacity:0];
	}
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.tableView.rowHeight = 65.0;
	float decel = UIScrollViewDecelerationRateNormal - (UIScrollViewDecelerationRateNormal - UIScrollViewDecelerationRateFast)/2.0;
	self.tableView.decelerationRate = decel;
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																						   target:self action:@selector(cancelAction)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
	
	_lastTableViewYContentOffset = self.tableView.contentOffset.y;
	
	[self enableThumbnailGeneration];
	
	// Don't reinitialize asset sources.
	if ([self.assetSources count] > 0)
		return;
	
	// Okay now generate the list of Assets to be displayed.
	// This should be quick since we are not creating assets or thumbnails.
	NSMutableArray *sources = [NSMutableArray arrayWithCapacity:0];
	
	if (_sourceType & AssetBrowserSourceTypeFileSharing) {
		[sources addObject:[AssetBrowserSource assetSourceOfType:AssetBrowserSourceTypeFileSharing]];		
	}

	self.assetSources = [[sources copy] autorelease];
	
	for (AssetBrowserSource *source in sources) {
		[source buildSourceLibrary];
	}
	
	[self updateActiveAssetSources];

	if ([sources count] == 1) {
		_singleSourceTypeMode = YES;
		self.title = [[sources objectAtIndex:0] name];
	}
	else {
		self.tableView.sectionHeaderHeight = 22.0;
	}
	
	[self.tableView reloadData];
	
	for (AssetBrowserSource *source in sources) {
		source.delegate = self;	
	}
}

- (void)cancelAction
{
	if ([self.delegate respondsToSelector:@selector(assetBrowserDidCancel:)]) {
		[[self retain] autorelease];
		[self.delegate assetBrowserDidCancel:self];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self updateThumbnails];
	
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	if (indexPath) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
	[self disableThumbnailGeneration];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	
	// If we aren't presenting the image picker.
	if (!self.modalViewController) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		if (indexPath)
			[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	// If a thumbnail finished while we were rotating then its cell might not have been updated, but the cell could still be cached.
	for (UITableViewCell *visibleCell in [self.tableView visibleCells]) {
		NSIndexPath *indexPath = [self.tableView indexPathForCell:visibleCell];
		[self updateCell:visibleCell forRowAtIndexPath:indexPath];
	}
}

#pragma mark -
#pragma mark Table view data source

- (void)updateActiveAssetSources
{
	[_activeAssetSources removeAllObjects];
	for (AssetBrowserSource *source in self.assetSources) {
		if ( ([source.assetItems count] > 0) ) {
			[_activeAssetSources addObject:source];
		}
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return [_activeAssetSources count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	if (_singleSourceTypeMode)
		return nil;
	
	AssetBrowserSource *source = [_activeAssetSources objectAtIndex:section];
	NSString *name = [source.assetItems count] > 0 ? source.name : nil;
	return name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	NSInteger numRows = 0;
	
	numRows = [[[_activeAssetSources objectAtIndex:section] assetItems] count];
	
	return numRows;
}

- (void)updateCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{	
	AssetBrowserSource *source = [_activeAssetSources objectAtIndex:indexPath.section];
	
	AssetBrowserItem *item = [[source assetItems] objectAtIndex:indexPath.row];
	cell.textLabel.text = item.title;

	UIImage *thumb = item.thumbnailImage;
	if (!thumb) {
		thumb = [item placeHolderImage];
		if (!item.audioOnly && item.canGenerateThumbnailImage) {
			[self updateThumbnails];
		}
	}
	cell.imageView.image = thumb;
	cell.accessoryType = UITableViewCellAccessoryNone;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {

		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
	}
	
	[self updateCell:cell forRowAtIndexPath:indexPath];
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	AssetBrowserItem *selectedItem = [[(AssetBrowserSource*)[_activeAssetSources objectAtIndex:indexPath.section] assetItems] objectAtIndex:indexPath.row];
	
	if ([self.delegate respondsToSelector:@selector(assetBrowser:didChooseAssets:)]) {
		[[self retain] autorelease];
		AssetBrowserItem *selectedItemCopy = [selectedItem copy];
		[self.delegate assetBrowser:self didChooseAssets:[NSArray arrayWithObject:selectedItemCopy]];
		[selectedItemCopy release];
	}
}

#pragma mark -
#pragma mark Asset Library Delegate

- (void)assetSourceLibraryDidChange:(AssetBrowserSource*)source
{	
	[self updateActiveAssetSources];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Thumbnail Generation

- (void)enableThumbnailGeneration
{
	_thumbnailGenerationEnabled = YES;
}

- (void)disableThumbnailGeneration
{
	_thumbnailGenerationEnabled = NO;
}

- (void)updateThumbnails
{
	if (! _thumbnailGenerationEnabled) {
		return;
	}
	if (! _thumbnailGenerationIsRunning) {
		// Run after this run loop iteration is done, don't cause table view display to slow down.
		NSArray *modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil];
		[self performSelector:@selector(generateThumbnails) withObject:nil afterDelay:0.0 inModes:modes];
		_thumbnailGenerationIsRunning = YES;
		[modes release];
	}
}

- (void)displayGeneratedThumbnail:(UIImage*)thumbnail forAssetItem:(AssetBrowserItem*)assetItem error:(NSError*)error
{	
	// Need to find the indexPath again, since it may have changed.
	NSUInteger sourceIdx = 0;
	for (AssetBrowserSource *source in _activeAssetSources) {
		NSUInteger idx = [source.assetItems indexOfObject:assetItem];
		if (idx != NSNotFound) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:sourceIdx];
			NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
			
			if ([visibleIndexPaths containsObject:indexPath]) 
			{
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
				if (cell) {
					cell.imageView.image = thumbnail;
					[cell setNeedsLayout];
				}
			}
			break;
		}
		sourceIdx++;
	}
}

- (void)generateThumbnails
{	
	if (! _thumbnailGenerationEnabled) {
		_thumbnailGenerationIsRunning = NO;
		return;
	}
	
	_thumbnailGenerationIsRunning = YES;
	
	NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
	
	id objOrEnumerator = (_lastTableViewScrollDirection == AssetBrowserScrollDirectionDown) ? (id)visibleIndexPaths : (id)[visibleIndexPaths reverseObjectEnumerator];
	for (NSIndexPath *path in objOrEnumerator) 
	{
		NSArray *assetItemsInSection = [[_activeAssetSources objectAtIndex:path.section] assetItems];
		AssetBrowserItem *assetItem = ([assetItemsInSection count] > path.row) ? [assetItemsInSection objectAtIndex:path.row] : nil;
		if (assetItem && assetItem.canGenerateThumbnailImage && (assetItem.thumbnailImage == nil)) {
			CGFloat targetHeight = self.tableView.rowHeight -1.0; // The contentView is one point smaller than the cell because of the divider.
			targetHeight *= _thumbnailScale;
			
			CGFloat targetAspectRatio = 1.5;
			CGSize targetSize = CGSizeMake(targetHeight*targetAspectRatio, targetHeight);
			
			[assetItem generateThumbnailAsynchronouslyWithSize:targetSize fillMode:AssetBrowserItemFillModeCrop completionHandler:^(UIImage *thumbnail, NSError *error) 
			{
				if (error) {
					NSLog(@"Couldn't generate thumbnail for %@, error:%@", assetItem, error);
				}
				if (!thumbnail) {
					thumbnail = [assetItem placeHolderImage];
				}
				[self displayGeneratedThumbnail:thumbnail forAssetItem:assetItem error:error];
				
				// Continue generating until all thumbnails in range have been finished.
				[self generateThumbnails];
			}];
			
			return;
		}
	}
	
	_thumbnailGenerationIsRunning = NO;
	
	return;
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

#if ONLY_GENERATE_THUMBS_WHEN_NOT_SCROLLING

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self disableThumbnailGeneration];
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		[self enableThumbnailGeneration];
		[self updateThumbnails];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self enableThumbnailGeneration];
	[self updateThumbnails];
}

#endif //ONLY_GENERATE_THUMBS_WHEN_NOT_SCROLLING

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{	
	CGFloat newOffset = self.tableView.contentOffset.y;
	CGFloat oldOffset = _lastTableViewYContentOffset;
	
	if (newOffset > oldOffset)
		_lastTableViewScrollDirection = AssetBrowserScrollDirectionDown;
	else if (newOffset < oldOffset)
		_lastTableViewScrollDirection = AssetBrowserScrollDirectionUp;
	
	_lastTableViewYContentOffset = newOffset;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Get rid of AVAsset and thumbnail caches.
	NSLog(@"%@ memory warning, clearing asset and thumbnail caches", self);
	for (AssetBrowserSource *source in self.assetSources) {
		for (AssetBrowserItem *item in [source assetItems]) {
			[item clearAssetCache];
			[item clearThumbnailCache];
		}
	}
}

- (void)dealloc 
{
	NSLog(@"assetBrowser: dealloc");
	_delegate = nil;
		
	[_assetSources release];
	[_activeAssetSources release];
	
	[super dealloc];
}

@end
