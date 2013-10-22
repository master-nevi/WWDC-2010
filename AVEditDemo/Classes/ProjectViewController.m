
/*
     File: ProjectViewController.m
 Abstract: Root view controller which provides editing UI. 
 
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

#import "ProjectViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AssetBrowserController.h"
#import "SimpleEditor.h"

#import "PlayerViewController.h"
#import "ThumbnailViewController.h"

#import "TimeSliderCell.h"
#import "ExportCell.h"
#import "TitleEditingCell.h"

#import <AVFoundation/AVVideoComposition.h>

@interface ProjectViewController () <AssetBrowserControllerDelegate, TimeSliderCellDelegate, TitleEditingCellDelegate>

- (void)updateCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)beginExport;
- (void)exportDidFinish:(AVAssetExportSession*)session;

@end

@implementation ProjectViewController

// We really only 2x longer than the transition duration, but give a little extra leeway just in case.
// This value multiplied by the transition duration specifies the minimum duration for the clip.
#define TRANSITION_LEEWAY_MULTIPLIER 2.01
// If I put this at 2.0 and trim the clips as close as they will go then the videoComposition fails.

enum {
	kClip1Section,
	kClip2Section,
	kClip3Section,
	kProjectSection,
	kCommentarySection,
	kTransitionsSection,
	kTitlesSection
};

UIImage *getImageWithRoundedUpperLeftCorner(UIImage *image, CGFloat radius)
{
	CGSize imageSize = [image size];
	CGRect imageBounds = CGRectZero;
	imageBounds.size = imageSize;
	
	UIGraphicsBeginImageContext(imageSize);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextClearRect(ctx, imageBounds);
	
	CGContextMoveToPoint(ctx, CGRectGetMinX(imageBounds) + radius, CGRectGetMinY(imageBounds));
	CGContextAddArc(ctx, CGRectGetMinX(imageBounds) + radius, CGRectGetMinY(imageBounds) + radius, radius, M_PI, 3 * M_PI / 2, 0);
	CGContextMoveToPoint(ctx, CGRectGetMinX(imageBounds), CGRectGetMinY(imageBounds) + radius);
	CGContextAddLineToPoint(ctx, CGRectGetMinX(imageBounds), CGRectGetMaxY(imageBounds));
	CGContextAddLineToPoint(ctx, CGRectGetMaxX(imageBounds), CGRectGetMaxY(imageBounds));
	CGContextAddLineToPoint(ctx, CGRectGetMaxX(imageBounds), CGRectGetMinY(imageBounds));
	CGContextAddLineToPoint(ctx, CGRectGetMinX(imageBounds) + radius, CGRectGetMinY(imageBounds));
	
	CGContextClip(ctx);
	
	[image drawInRect:imageBounds];
	
	UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return roundedImage;
}

@synthesize assetBrowser = _assetBrowser;
@synthesize editor = _editor;
@synthesize clips = _clips, clipTimeRanges = _clipTimeRanges, clipThumbnails = _clipThumbnails;
@synthesize commentary = _commentary, commentaryThumbnail = _commentaryThumbnail;
@synthesize titleText = _titleText;

- (id)initWithStyle:(UITableViewStyle)style 
{
    if ((self = [super initWithStyle:style])) 
	{
		_editor = [[SimpleEditor alloc] init];
		
		_clips = [[NSMutableArray alloc] initWithCapacity:3];
		_clipTimeRanges = [[NSMutableArray alloc] initWithCapacity:3];
		_clipThumbnails = [[NSMutableArray alloc] initWithCapacity:3];
		NSUInteger idx;
		for (idx = 0; idx < 3; idx++) {
			[_clips addObject:[NSNull null]];
			[_clipTimeRanges addObject:[NSNull null]];
			[_clipThumbnails addObject:[NSNull null]];
		}
		_currentlyChoosingClipForSection = -1;

		_commentaryStartTime = 0.0;
		
		// Defaults for the transition settings.
		_transitionType = SimpleEditorTransitionTypeCrossFade;
		_transitionDuration = 1.0;
		
		_titleText = @"";
		
		UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
		self.navigationItem.backBarButtonItem = [backButton autorelease];
    }
    return self;
}

- (NSArray*)indexPathsForSection:(NSUInteger)section inRange:(NSRange)range
{
	NSUInteger idx;
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:0];
	for (idx = range.location; idx < range.location + range.length; idx++) {
		[indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
	}
	return [[indexPaths copy] autorelease];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

	self.tableView.rowHeight = 49.0; // 1 pixel is for the divider, we want our thumbnails to have an even height.
	self.title = @"AVEditDemo";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	// Recover from the player's status bar transition.
	UIApplication *app = [UIApplication sharedApplication];
	if ([app statusBarStyle] != UIStatusBarStyleDefault) {
		[app setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	}
	if ([self.navigationController.navigationBar barStyle] != UIBarStyleDefault) {
		[self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
	}
	
	// Do deferred index path insertions.
	if (_indexPathsToInsert) 
	{	
		NSUInteger section = [[_indexPathsToInsert objectAtIndex:0] section];
		NSIndexPath *indexPathWithThumb = [NSIndexPath indexPathForRow:0 inSection:section];
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPathWithThumb];
		[self updateCell:cell forRowAtIndexPath:indexPathWithThumb];
		
		[self performSelector:@selector(insertIndexPaths:) withObject:_indexPathsToInsert afterDelay:0.33];
		
		[_indexPathsToInsert release];
		_indexPathsToInsert = nil;
	}
}

- (void)viewDidAppear:(BOOL)animated {
    // Don't call super so that it doesn't flash the scroll indicator.
}

#pragma mark -
#pragma mark Editor Sync

- (void)synchronizeEditorClipsWithOurClips
{
	NSMutableArray *validClips = [NSMutableArray arrayWithCapacity:3];
	for (AVURLAsset *asset in self.clips) {
		if (! [asset isKindOfClass:[NSNull class]]) {
			[validClips addObject:asset];
		}
	}
	self.editor.clips = [[validClips copy] autorelease];
}

- (void)synchronizeEditorClipTimeRangesWithOurClipTimeRanges
{
	NSMutableArray *validClipTimeRanges = [NSMutableArray arrayWithCapacity:3];
	for (NSValue *timeRange in self.clipTimeRanges) {
		if (! [timeRange isKindOfClass:[NSNull class]]) {
			[validClipTimeRanges addObject:timeRange];
		}
	}
	self.editor.clipTimeRanges = [[validClipTimeRanges copy] autorelease];
}

- (void)synchronizeWithEditor
{
	// Clips
	[self synchronizeEditorClipsWithOurClips];
	[self synchronizeEditorClipTimeRangesWithOurClipTimeRanges];
	
	// Commentary
	self.editor.commentary = _commentaryEnabled ? self.commentary : nil;
	CMTime commentaryStartTime = (_commentaryEnabled && self.commentary) ? CMTimeMakeWithSeconds(_commentaryStartTime, 600) : kCMTimeInvalid;
	self.editor.commentaryStartTime = commentaryStartTime;
	
	// Transitions
	CMTime transitionDuration = _transitionsEnabled ? CMTimeMakeWithSeconds(_transitionDuration, 600) : kCMTimeInvalid;
	self.editor.transitionDuration = transitionDuration;
	self.editor.transitionType = _transitionsEnabled ? _transitionType : SimpleEditorTransitionTypeNone;
	
	// Titles
	self.editor.titleText = _titlesEnabled ? self.titleText : nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kTitlesSection+1; // The titles section is the last section.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if ( (section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section) ) {
		AVURLAsset *asset = [self.clips objectAtIndex:section];
		return ([asset isKindOfClass:[NSNull class]]) ? 1 : 3;
	}
	else if ( section == kProjectSection ) {
		return 3;
	}
	else if ( section == kCommentarySection) {
		return _commentaryEnabled ? 3 : 1;
	}
	else if ( section == kTransitionsSection ) {
		return _transitionsEnabled ? 4 : 1;
	}
	else if ( section == kTitlesSection ) {
		return _titlesEnabled ? 2 : 1;
	}
	else {
		return 0;
	}
}

- (void)updateCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	cell.imageView.image = nil;
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	// Configure the cell.
	if ( (section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section) ) {
		AVURLAsset *clip = [self.clips objectAtIndex:section];
		if (row == 0) {
			if ([clip isKindOfClass:[NSNull class]]) {
				cell.textLabel.text = [NSString stringWithFormat:@"Clip %i", section+1];
			}
			else {
				cell.imageView.image = [self.clipThumbnails objectAtIndex:section];
				cell.textLabel.text = [[clip.URL lastPathComponent] stringByDeletingPathExtension];
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else {
			TimeSliderCell *timeCell = (TimeSliderCell*)cell;
			timeCell.sliderXInset = 60.0;
			timeCell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
			
			NSValue *timeRangeValue = [self.clipTimeRanges objectAtIndex:section];
			CMTimeRange timeRange = [timeRangeValue CMTimeRangeValue];
			CMTime startTime = timeRange.start;
			CMTime endTime = CMTimeAdd(timeRange.start, timeRange.duration);
			
			timeCell.textLabel.text = (row == 1) ? @"Start" : @" End";
			timeCell.flipSlider = (row == 1) ? NO : YES;
			timeCell.duration = CMTimeGetSeconds(clip.duration);
			float newTimeValue = CMTimeGetSeconds( ( row == 1) ? startTime : endTime );
			timeCell.timeValue = newTimeValue;
			if (row == 1) {
				timeCell.minimumTime = 0.0;
				
				float maxTime = CMTimeGetSeconds(endTime);
				if (_transitionsEnabled)
					maxTime -= TRANSITION_LEEWAY_MULTIPLIER*_transitionDuration; // Need extra time 
				timeCell.maximumTime = maxTime;
			}
			else {
				float minTime = CMTimeGetSeconds(startTime);
				if (_transitionsEnabled)
					minTime += TRANSITION_LEEWAY_MULTIPLIER*_transitionDuration;
				timeCell.minimumTime = minTime;
				
				timeCell.maximumTime = timeCell.duration;
			}
		}
	}
	else if ( section == kProjectSection ) {
		if (row == 0) {
			cell.textLabel.text = @"Play";
		}
		else if (row == 1) {
			cell.textLabel.text = @"View Thumbnails";
		}
		else {
			cell.textLabel.text = @"Export";
			ExportCell *exportCell = (ExportCell*)cell;
			[exportCell setProgressViewHidden:_exporting ? NO : YES];
			[exportCell setDetailTextLabelHidden:_showSavedVideoToAssestsLibrary ? NO : YES];
		}
	}
	else if ( section == kCommentarySection ) {
		if (row == 0) {
			cell.textLabel.text = @"Commentary";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			UISwitch *toggleSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
			toggleSwitch.on = _commentaryEnabled;
			[toggleSwitch addTarget:self action:@selector(toggleCommentaryEnabled:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = toggleSwitch;
		}
		else if (row == 1) {
			if (self.commentary == nil) {
				cell.textLabel.text = @"Audio Clip";
			}
			else {				
				cell.imageView.image = self.commentaryThumbnail;
				cell.textLabel.text = [[self.commentary.URL lastPathComponent] stringByDeletingPathExtension];
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	
		}
		else if (row == 2) {
			TimeSliderCell *timeCell = (TimeSliderCell*)cell;
			timeCell.textLabel.text = @"Start";
			timeCell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
			timeCell.sliderXInset = 64.0;
			timeCell.flipSlider = NO;
			timeCell.minimumTime = 0.0;
			BOOL userHasSelectedClips = NO;
			for (AVURLAsset *clip in self.clips) {
				if (! [clip isKindOfClass:[NSNull class]]) {
					userHasSelectedClips = YES;
					break;
				}
			}
			// Don't want to use 0.0 (div by 0), 1.0 is arbitrary.
			timeCell.duration = (self.commentary && userHasSelectedClips) ? self.projectDuration : 1.0;
			timeCell.maximumTime = (self.commentary && userHasSelectedClips) ? timeCell.duration : 0.0;
			timeCell.timeValue = _commentaryStartTime;
		}
	}
	else if ( section == kTransitionsSection ) {
		if (row == 0) {
			cell.textLabel.text = @"Transitions";
			
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			UISwitch *toggleSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
			toggleSwitch.on = _transitionsEnabled;
			[toggleSwitch addTarget:self action:@selector(toggleTransitionsEnabled:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = toggleSwitch;
		}
		else if (row == 1) {
			TimeSliderCell *timeCell = (TimeSliderCell*)cell;
			timeCell.textLabel.text = @"Length";
			timeCell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
			timeCell.sliderXInset = 72.0;
			timeCell.flipSlider = NO;
			timeCell.minimumTime = 0.0;
			timeCell.duration = 4.0;
			timeCell.maximumTime = timeCell.duration;
			timeCell.timeValue = _transitionDuration;
		}
		else if (row == 2) {
			cell.textLabel.text = @"Cross Fade";
			if (_transitionType == SimpleEditorTransitionTypeCrossFade)
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else if (row == 3) {
			cell.textLabel.text = @"Push";
			if (_transitionType == SimpleEditorTransitionTypePush)
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else if ( section == kTitlesSection ) {
		if (row == 0) {
			cell.textLabel.text = @"Title";
			
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			UISwitch *toggleSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
			toggleSwitch.on = _titlesEnabled;
			[toggleSwitch addTarget:self action:@selector(toggleTitlesEnabled:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = toggleSwitch;
		}
		else {
			TitleEditingCell *editingCell = (TitleEditingCell*)cell;
			editingCell.titleText = self.titleText;
		}
	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *NormalCellIdentifier = @"Cell";
    static NSString *TimeSliderCellIdentifier = @"TimeCell";
    static NSString *ExportCellIdentifier = @"ExportCell";
    static NSString *TitleEditingCellIdentifier = @"TitleCell";
	
    NSString *cellID = nil;
	
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	
	if ( ((section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section)) && ((row == 1) || (row == 2)) 
		|| ((section == kCommentarySection) && (row == 2))
		|| ((section == kTransitionsSection) && (row == 1)) )
	{
		cellID = TimeSliderCellIdentifier;
	}
	else if ( (section == kProjectSection) && (row == 2) ) {
		cellID = ExportCellIdentifier;
	}
	else if ( (section == kTitlesSection) && (row == 1) ) {
		cellID = TitleEditingCellIdentifier;
	}
	else {
		cellID = NormalCellIdentifier;
	}
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil)
	{	
		if ( cellID == TimeSliderCellIdentifier ) {
			cell = (UITableViewCell*)[[[TimeSliderCell alloc] initWithReuseIdentifier:cellID] autorelease];
			[(TimeSliderCell*)cell setDelegate:self];
		}
		else if ( cellID == ExportCellIdentifier ) {
			cell = (UITableViewCell*)[[[ExportCell alloc] initWithReuseIdentifier:cellID] autorelease];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
			cell.detailTextLabel.text = @"Video saved to Camera Roll";
		}
		else if ( cellID == TitleEditingCellIdentifier ) {
			cell = (UITableViewCell*)[[[TitleEditingCell alloc] initWithReuseIdentifier:cellID] autorelease];
			[(TitleEditingCell*)cell setDelegate:self];
		}
		else {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
			cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
		}
    }
	
	if (cellID == NormalCellIdentifier) {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	
	[self updateCell:cell forRowAtIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{	
	NSString *title = nil;
	
	if ( section == kClip1Section ) {
		title = @"Clips";
	}
	else if ( section  == kProjectSection ) {
		title = @"Project";
	}
	else if ( section == kCommentarySection ) {
		title = @"Options";
	}

	return title;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	
	// Use AssetBrowser for rows which allow clip selection.
	if ( (((section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section)) && (row == 0)) 
		|| ((section == kCommentarySection) && (row == 1)) ) {
		if (! self.assetBrowser) 
		{			
			AssetBrowserController *browser = [[[AssetBrowserController alloc] initWithSourceType:AssetBrowserSourceTypeFileSharing] autorelease];
			browser.delegate = self;
			self.assetBrowser = [[[UINavigationController alloc] initWithRootViewController:browser] autorelease];
			[self.assetBrowser.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
		}
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
		_currentlyChoosingClipForSection = section;
		[self presentModalViewController:self.assetBrowser animated:YES];
	}
	else if ( section == kProjectSection ) 
	{
		BOOL userHasSelectedClips = NO;
		for (AVURLAsset *clip in self.clips) {
			if (! [clip isKindOfClass:[NSNull class]]) {
				userHasSelectedClips = YES;
				break;
			}
		}
		if (! userHasSelectedClips) {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			return;
		}
		
		// Synchronize changes with the editor.
		[self synchronizeWithEditor];
		
		if (row == 0) {
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
			[[self.navigationController navigationBar] setBarStyle:UIBarStyleBlackTranslucent];
			
			PlayerViewController *playerController = [[[PlayerViewController alloc] initWithEditor:self.editor] autorelease];
			[self.navigationController pushViewController:playerController animated:YES];
		}
		else if (row == 1) {
			ThumbnailViewController *thumbnailController = [[[ThumbnailViewController alloc] initWithEditor:self.editor] autorelease];
			[self.navigationController pushViewController:thumbnailController animated:YES];
			
		}
		else {			
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			if (_exporting) {
				return;
			}
			[self beginExport];
		}
	}
	else {
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		
		if (section == kTransitionsSection) {
			if ( (row == 2) || (row == 3) ) {
				NSUInteger newTransitionType = (row == 2) ? SimpleEditorTransitionTypeCrossFade : SimpleEditorTransitionTypePush;
				if (newTransitionType != _transitionType) {
					_transitionType = newTransitionType;
					NSRange range = {2,2};
					for (NSIndexPath *path in [self indexPathsForSection:section inRange:range]) {
						UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
						[self updateCell:cell forRowAtIndexPath:path];
					}
				}
			}
		}
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
	
	if ( ((section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section)) && (row == 0) ) {
		AVURLAsset *clip = [self.clips objectAtIndex:section];
		if (! [clip isKindOfClass:[NSNull class]]) {
			style = UITableViewCellEditingStyleDelete;
		}
	}
	return style;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return @"Remove";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{   
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;

	if (editingStyle == UITableViewCellEditingStyleDelete) {
		if ( ((section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section)) && (row == 0) ) {
			[self.clips replaceObjectAtIndex:indexPath.section withObject:[NSNull null]];
			[self.clipTimeRanges replaceObjectAtIndex:indexPath.section withObject:[NSNull null]];
			[self.clipThumbnails replaceObjectAtIndex:indexPath.section withObject:[NSNull null]];
			
			NSRange range = {1, 2};
			NSArray *indexPathsToDelete = [self indexPathsForSection:section inRange:range];
			[self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];

			NSIndexPath *indexPathToReload = [NSIndexPath indexPathForRow:0 inSection:section];
			[self performSelector:@selector(reloadIndexPath:) withObject:indexPathToReload afterDelay:0.0];
		}		
	}
}

- (void)reloadIndexPath:(NSIndexPath*)path
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
	[self updateCell:cell forRowAtIndexPath:path];
	[cell layoutIfNeeded];
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Export

- (void)beginExport
{
	_exporting = YES;
	_showSavedVideoToAssestsLibrary = NO;
	
	NSIndexPath *exportCellIndexPath = [NSIndexPath indexPathForRow:2 inSection:kProjectSection];
	ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
	cell.progressView.progress = 0.0;
	[cell setProgressViewHidden:NO animated:YES];
	[self updateCell:cell forRowAtIndexPath:exportCellIndexPath];
	
	[self.editor buildCompositionObjectsForPlayback:NO];
	AVAssetExportSession *session = [self.editor assetExportSessionWithPreset:AVAssetExportPresetHighestQuality];

	NSString *filePath = nil;
	NSUInteger count = 0;
	do {
		filePath = NSTemporaryDirectory();
		
		NSString *numberString = count > 0 ? [NSString stringWithFormat:@"-%i", count] : @"";
		filePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Output-%@.mov", numberString]];
		count++;
	} while([[NSFileManager defaultManager] fileExistsAtPath:filePath]);      
	
	session.outputURL = [NSURL fileURLWithPath:filePath];
	session.outputFileType = AVFileTypeQuickTimeMovie;
	
	[session exportAsynchronouslyWithCompletionHandler:^
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self exportDidFinish:session];
		});
	}];
	
	NSArray *modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil];
	[self performSelector:@selector(updateProgress:) withObject:session afterDelay:0.5 inModes:modes];
}

- (void)updateProgress:(AVAssetExportSession*)session
{
	if (session.status == AVAssetExportSessionStatusExporting) {
		NSIndexPath *exportCellIndexPath = [NSIndexPath indexPathForRow:2 inSection:kProjectSection];
		ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
		cell.progressView.progress = session.progress;	
		
		NSArray *modes = [[[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil] autorelease];
		[self performSelector:@selector(updateProgress:) withObject:session afterDelay:0.5 inModes:modes];
	}
}

- (void)exportDidFinish:(AVAssetExportSession*)session
{
	NSURL *outputURL = session.outputURL;
	
	_exporting = NO;
	NSIndexPath *exportCellIndexPath = [NSIndexPath indexPathForRow:2 inSection:kProjectSection];
	ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
	cell.progressView.progress = 1.0;
	[cell setProgressViewHidden:YES animated:YES];
	[self updateCell:cell forRowAtIndexPath:exportCellIndexPath];
	
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
		[library writeVideoAtPathToSavedPhotosAlbum:outputURL
									completionBlock:^(NSURL *assetURL, NSError *error){
										dispatch_async(dispatch_get_main_queue(), ^{
											if (error) {
												NSLog(@"writeVideoToAssestsLibrary failed: %@", error);
												UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
																									message:[error localizedRecoverySuggestion]
																								   delegate:nil
																						  cancelButtonTitle:@"OK"
																						  otherButtonTitles:nil];
												[alertView show];
												[alertView release];
											}
											else {
												_showSavedVideoToAssestsLibrary = YES;
												ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
												[cell setDetailTextLabelHidden:NO animated:YES];
												[self updateCell:cell forRowAtIndexPath:exportCellIndexPath];
												NSArray *modes = [[[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil] autorelease];
												[self performSelector:@selector(hideCameraRollText) withObject:nil afterDelay:5.0 inModes:modes];
											}
										});
										
									}];
	}
	[library release];
}

- (void)hideCameraRollText
{	
	NSIndexPath *exportCellIndexPath = [NSIndexPath indexPathForRow:2 inSection:kProjectSection];
	ExportCell *cell = (ExportCell*)[self.tableView cellForRowAtIndexPath:exportCellIndexPath];
	_showSavedVideoToAssestsLibrary = NO;
	[cell setDetailTextLabelHidden:YES animated:YES];
}

#pragma mark -
#pragma mark Commentary

- (void)toggleCommentaryEnabled:(UISwitch*)sender
{
	if (_commentaryEnabled == sender.on) 
		return;
	_commentaryEnabled = sender.on;
	
	NSRange range = {1, 2};
	NSArray *indexPathsToInsertOrDeleted = [self indexPathsForSection:kCommentarySection inRange:range];
	
	if (_commentaryEnabled) {
		[self.tableView insertRowsAtIndexPaths:indexPathsToInsertOrDeleted withRowAnimation:UITableViewRowAnimationTop];
		[self.tableView scrollToRowAtIndexPath:[indexPathsToInsertOrDeleted lastObject] atScrollPosition:UITableViewScrollPositionNone animated:YES];
	}
	else {
		[self.tableView deleteRowsAtIndexPaths:indexPathsToInsertOrDeleted withRowAnimation:UITableViewRowAnimationTop];
	}
}

#pragma mark -
#pragma mark Transitions

// Includes the impact of clip overlap due to transitions.
- (float)projectDuration
{
	NSMutableArray *validClipTimeRanges = [NSMutableArray arrayWithCapacity:3];
	for (NSValue *timeRangeValue in self.clipTimeRanges) {
		if (! [timeRangeValue isKindOfClass:[NSNull class]]) {
			[validClipTimeRanges addObject:timeRangeValue];
		}
	}
	
	CMTime projectDuration = kCMTimeZero;
	NSUInteger idx = 0;
	NSUInteger clipCount = [validClipTimeRanges count];
	for (NSValue *timeRangeValue in validClipTimeRanges) {
		CMTime clipDuration = [timeRangeValue CMTimeRangeValue].duration;
		projectDuration = CMTimeAdd(projectDuration, clipDuration);
		if (_transitionsEnabled && (idx != (clipCount-1)) ) {
			CMTime amountTrimmedByTransition = CMTimeMakeWithSeconds(_transitionDuration, 600);
			if ( CMTIME_COMPARE_INLINE(amountTrimmedByTransition, >, clipDuration) ) {
				amountTrimmedByTransition = clipDuration;
			}
			projectDuration = CMTimeSubtract(projectDuration, amountTrimmedByTransition);
		}
		idx++;
	}
	return CMTimeGetSeconds(projectDuration);
}

- (void)constrainClipTimeRangesBasedOnTransitionDuration
{
	if (_transitionsEnabled) {
		// Constrain self.clipTimeRanges, and tell the clip sections to reload if they are visible.
		NSUInteger idx;
		for (idx = 0; idx < [self.clipTimeRanges count]; idx++) {
			NSValue *timeRangeValue = [self.clipTimeRanges objectAtIndex:idx];
			if (! [timeRangeValue isKindOfClass:[NSNull class]]) {
				CMTimeRange timeRange = [timeRangeValue CMTimeRangeValue];
				CMTime minDuration = CMTimeMakeWithSeconds(TRANSITION_LEEWAY_MULTIPLIER*_transitionDuration, 600);
				if ( CMTIME_COMPARE_INLINE(timeRange.duration, <, minDuration) ) {
					timeRange.duration = minDuration;
					CMTime assetDuration = [(AVURLAsset*)[self.clips objectAtIndex:idx] duration];
					if ( CMTIME_COMPARE_INLINE(timeRange.duration, >, assetDuration) ) {
						CMTime differenceToMakeUp = CMTimeSubtract(timeRange.duration, assetDuration);
						timeRange.start = CMTimeSubtract(timeRange.start, differenceToMakeUp);
						if ( CMTIME_COMPARE_INLINE(timeRange.start, <, kCMTimeZero) ) {
							timeRange.start = kCMTimeZero;
							timeRange.duration = assetDuration;
						}
					}
				}
				[self.clipTimeRanges replaceObjectAtIndex:idx withObject:[NSValue valueWithCMTimeRange:timeRange]];
			}
		}
	}
	for (NSIndexPath *visibleIndexPath in [self.tableView indexPathsForVisibleRows]) {
		NSUInteger section = visibleIndexPath.section;
		
		if ( (section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section) ) {
			UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:visibleIndexPath];
			[self updateCell:cell forRowAtIndexPath:visibleIndexPath];
		}
	}
}

- (void)constrainCommentaryStartTimeBasedOnProjectDuration
{
	// update commentary start time if visible
	NSIndexPath *commentaryStartTimeIndexPath = [NSIndexPath indexPathForRow:2 inSection:kCommentarySection];
	if ([[self.tableView indexPathsForVisibleRows] containsObject:commentaryStartTimeIndexPath]) {
		TimeSliderCell *commentaryStartTimeCell = (TimeSliderCell*)[self.tableView cellForRowAtIndexPath:commentaryStartTimeIndexPath];
		[self updateCell:commentaryStartTimeCell forRowAtIndexPath:commentaryStartTimeIndexPath];
		_commentaryStartTime = commentaryStartTimeCell.timeValue;
	}
}

- (void)toggleTransitionsEnabled:(UISwitch*)sender
{
	if (_transitionsEnabled== sender.on) 
		return;
	_transitionsEnabled = sender.on;
	
	NSRange range = {1, 3};
	NSArray *indexPathsToInsertOrDeleted = [self indexPathsForSection:kTransitionsSection inRange:range];
	
	if (_transitionsEnabled) {
		[self.tableView insertRowsAtIndexPaths:indexPathsToInsertOrDeleted withRowAnimation:UITableViewRowAnimationTop];
		[self.tableView scrollToRowAtIndexPath:[indexPathsToInsertOrDeleted lastObject] atScrollPosition:UITableViewScrollPositionNone animated:YES];
	}
	else {
		[self.tableView deleteRowsAtIndexPaths:indexPathsToInsertOrDeleted withRowAnimation:UITableViewRowAnimationTop];
	}
	[self constrainClipTimeRangesBasedOnTransitionDuration];
	[self constrainCommentaryStartTimeBasedOnProjectDuration];
}


#pragma mark -
#pragma mark Titles

- (void)toggleTitlesEnabled:(UISwitch*)sender
{
	if (_titlesEnabled == sender.on) 
		return;
	_titlesEnabled = sender.on;
	
	NSRange range = {1, 1};
	NSArray *indexPathsToInsertOrDeleted = [self indexPathsForSection:kTitlesSection inRange:range];
	
	if (_titlesEnabled) {
		[self.tableView insertRowsAtIndexPaths:indexPathsToInsertOrDeleted withRowAnimation:UITableViewRowAnimationTop];
		[self.tableView scrollToRowAtIndexPath:[indexPathsToInsertOrDeleted lastObject] atScrollPosition:UITableViewScrollPositionNone animated:YES];
	}
	else {
		[self.tableView deleteRowsAtIndexPaths:indexPathsToInsertOrDeleted withRowAnimation:UITableViewRowAnimationTop];		
	}
}

#pragma mark -
#pragma mark AssetBrowser Delegate

- (void)assetBrowser:(AssetBrowserController *)assetBrowser didChooseAssets:(NSArray *)assets
{
	AssetBrowserItem *assetItem = [assets objectAtIndex:0];
	AVURLAsset *asset = (AVURLAsset*)assetItem.asset;
	BOOL animateInRows = NO;
	NSArray *indexPathsToInsert = nil;
	
	UIImage *assetThumbnail = [assetItem thumbnailImage];
	
	CGFloat screenScale = [[UIScreen mainScreen] scale];
	if (assetThumbnail == nil) {
		if (assetItem.canGenerateThumbnailImage) {
			CGFloat targetAspectRatio = 3.0/2.0;
			CGFloat targetHeight = self.tableView.rowHeight-1.0; //1 point is used for the divider line
			targetHeight *= screenScale;
			CGSize targetSize = CGSizeMake(targetHeight*targetAspectRatio, targetHeight);
			
			[assetItem generateThumbnailWithSize:targetSize fillMode:AssetBrowserItemFillModeCrop];
			assetThumbnail = [assetItem thumbnailImage];
		}
		else {
			assetThumbnail = [assetItem placeHolderImage];
		}
	}
	
	if (_currentlyChoosingClipForSection == kCommentarySection) {
		self.commentary = asset;
		self.commentaryThumbnail = assetThumbnail;
		[self.tableView reloadData];
	}
	else {
		animateInRows = [[self.clips objectAtIndex:_currentlyChoosingClipForSection] isKindOfClass:[NSNull class]];
		[self.clips replaceObjectAtIndex:_currentlyChoosingClipForSection withObject:asset];
		CMTimeRange timeRange = kCMTimeRangeZero;
		timeRange.duration = asset.duration;
		NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
		[self.clipTimeRanges replaceObjectAtIndex:_currentlyChoosingClipForSection withObject:timeRangeValue];
		
		CGFloat radius = 13.0*screenScale;
		assetThumbnail = getImageWithRoundedUpperLeftCorner(assetThumbnail, radius);
		[self.clipThumbnails replaceObjectAtIndex:_currentlyChoosingClipForSection withObject:assetThumbnail];
		
		NSRange range = {1,2};
		indexPathsToInsert = [self indexPathsForSection:_currentlyChoosingClipForSection inRange:range];
	}
	_currentlyChoosingClipForSection = -1;
	
	if (animateInRows) {
		// This signals viewWillAppear that it needs to insert some index paths.
		_indexPathsToInsert = [indexPathsToInsert retain];
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	}
	else {
		[self.tableView reloadData];
	}
	[self dismissModalViewControllerAnimated:YES];
}

- (void)insertIndexPaths:(NSArray*)indexPaths
{
	[self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
	[self.tableView scrollToRowAtIndexPath:[indexPaths lastObject] atScrollPosition:UITableViewScrollPositionNone animated:YES];
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)assetBrowserDidCancel:(AssetBrowserController *)assetBrowser
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark TimeSliderCell Delegate

- (void)sliderCellTimeValueDidChange:(TimeSliderCell*)cell
{
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	
	// Update the selected time range.
    if ( (section == kClip1Section) || (section == kClip2Section) || (section == kClip3Section) ) {
		NSValue *timeRangeValue = [self.clipTimeRanges objectAtIndex:section];
		CMTimeRange timeRange = [timeRangeValue CMTimeRangeValue];
		
		CMTime startTime = timeRange.start;
		CMTime endTime = CMTimeAdd(timeRange.start, timeRange.duration);
		if (row == 1) {
			startTime = CMTimeMakeWithSeconds(cell.timeValue, 600);
		}
		else {
			endTime = CMTimeMakeWithSeconds(cell.timeValue, 600);
		}
		
		timeRange.start = startTime;
		timeRange.duration = CMTimeSubtract(endTime, startTime);
		
		timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
		[self.clipTimeRanges replaceObjectAtIndex:section withObject:timeRangeValue];
				
		[self constrainCommentaryStartTimeBasedOnProjectDuration];
	}
	else if ((section == kCommentarySection) && (row == 2)) {
		_commentaryStartTime = cell.timeValue;
	}
	else if ((section == kTransitionsSection) && (row == 1)) {
		_transitionDuration = cell.timeValue;
		[self constrainClipTimeRangesBasedOnTransitionDuration];
		[self constrainCommentaryStartTimeBasedOnProjectDuration];
	}
	
	[self updateCell:cell forRowAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark TitleEditingCell Delegate

- (void)titleEditingCellDidFinishEditing:(TitleEditingCell*)cell
{
	self.titleText = cell.titleText;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	self.assetBrowser = nil;
}

- (void)dealloc 
{
	if (_assetBrowser) {
		_assetBrowser.delegate = nil;
		[_assetBrowser release];
	}
	[_editor release];
	
	[_clips release];
	[_clipTimeRanges release];
	[_clipThumbnails release];
	
	[_commentary release];
	[_commentaryThumbnail release];
	
    [super dealloc];
}

@end
