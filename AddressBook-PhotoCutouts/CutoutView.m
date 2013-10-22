/*
     File: CutoutView.m
 Abstract: Displays an image within a scroll view, allowing the user to move and scale it beneath a "cutout" overlay. When editing is disabled, displays only the image, without allowing interaction.
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

#import "CutoutView.h"

#define kMinimumZoomFactorFromStart 0.5
#define kThumbnailWidth 55.0
#define kThumbnailHeight 55.0

@interface CutoutView ()
@property (nonatomic, assign) BOOL overlayFaded;

- (void)updateImageViews;
- (void)updateViewsForZoomAndDrag;
@end

@implementation CutoutView

@synthesize backgroundView;
@synthesize foregroundView;
@synthesize scrollView;
@synthesize personPhotoView;
@synthesize photoButton;

@synthesize allowsEditing;
@synthesize cutoutImage;
@synthesize personImage;

@synthesize overlayFaded;

- (void)dealloc {
    [cutoutImage release];
    [personImage release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self updateImageViews];
    [self updateViewsForZoomAndDrag];
    
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.backgroundColor = [UIColor clearColor];
    
    // On the iPad, this should fit the full image in the view; on the iPhone, it should just fill the screen
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.personPhotoView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.personPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (void)setCutoutImage:(UIImage *)newCutoutImage {
	if (newCutoutImage != cutoutImage) {
        [cutoutImage release];
        cutoutImage = [newCutoutImage retain];
        
        [self updateImageViews];
    }
}

- (void)setPersonImage:(UIImage *)newPersonImage {
	if (newPersonImage != personImage) {
        [personImage release];
        personImage = [newPersonImage retain];
        
        [self updateImageViews];
        [self updateViewsForZoomAndDrag];
    }
}

- (void)setAllowsEditing:(BOOL)newAllowsEditing {
	if (newAllowsEditing != allowsEditing) {
        allowsEditing = newAllowsEditing;
        
        [self updateImageViews];
    }
}

- (void)updateImageViews {
	if (allowsEditing) {
		foregroundView.image = self.cutoutImage;
		foregroundView.contentMode = UIViewContentModeScaleAspectFill;
		backgroundView.image = self.cutoutImage;
		personPhotoView.image = self.personImage;
		scrollView.userInteractionEnabled = YES;
        photoButton.enabled = (self.personImage == nil);
		self.backgroundColor = [UIColor whiteColor];
		self.opaque = YES;
	} else {
		foregroundView.image = self.personImage;
		foregroundView.contentMode = UIViewContentModeCenter;
		backgroundView.image = nil;
		personPhotoView.image = nil;
		scrollView.userInteractionEnabled = NO;
        photoButton.enabled = YES;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}
}

- (void)updateViewsForZoomAndDrag {
    if (self.allowsEditing && self.personImage) {
        CGSize imageSize = self.personImage.size;
        CGSize viewSize = self.bounds.size;
        
        // To start with, we'd like the image to show at its actual size, unless it's really big,
        // in which case we just want it to fill the window.
        float startingZoomScale = 1.0;
        float zoomScaleToFillWindow = MAX(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
        if (zoomScaleToFillWindow < startingZoomScale) {
            startingZoomScale = zoomScaleToFillWindow;
        }
        
        self.scrollView.minimumZoomScale = startingZoomScale * kMinimumZoomFactorFromStart;
        
        // Let the user zoom in to fill the window, unless the image is even bigger.
        // If it's bigger, let the user zoom out to the actual size of the image.
        self.scrollView.maximumZoomScale = MAX(zoomScaleToFillWindow, 1.0);
        
        self.scrollView.zoomScale = startingZoomScale;
        CGFloat imageWidthOnScreen = startingZoomScale * imageSize.width;
        CGFloat imageHeightOnScreen = startingZoomScale * imageSize.height;
        self.personPhotoView.frame = CGRectMake(0, 0, imageWidthOnScreen, imageHeightOnScreen);
        self.scrollView.contentSize = CGSizeMake(imageWidthOnScreen, imageHeightOnScreen);
        
        self.scrollView.contentOffset = CGPointMake((imageWidthOnScreen - viewSize.width) / 2.0, (imageHeightOnScreen - viewSize.height) / 2.0);
        
        // Don't let more than half of the image go off-screen.  Also gets updated when the user zooms the picture.
        CGFloat verticalInset = viewSize.height - 0.5 * imageHeightOnScreen;
        CGFloat horizontalInset = viewSize.width - 0.5 * imageWidthOnScreen;
        self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
        self.overlayFaded = YES;
    }
}

- (void)getCurrentImage:(UIImage **)outImage currentThumbnail:(UIImage **)outThumbnail {
    CGSize cutoutSize = self.bounds.size;
    
    UIGraphicsBeginImageContext(cutoutSize);
    
    foregroundView.alpha = 1;
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    foregroundView.alpha = 0.8;
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (outImage) {
        *outImage = image;
    }
    
    if (outThumbnail) {
        // Create a 55x55 thumbnail of the image so that the gallery isn't loading the whole thing for every row.
        UIGraphicsBeginImageContext(CGSizeMake(kThumbnailWidth, kThumbnailHeight));
        
        // Get a scaling factor so we can fit to the thumbnail's width.
        CGFloat thumbScaleFactor = kThumbnailWidth / cutoutSize.width;
        [image drawInRect:CGRectMake(0, 0, kThumbnailWidth, cutoutSize.height * thumbScaleFactor)];
        
        UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
		
        *outThumbnail = thumbImage;
    }
}

#pragma mark -
#pragma mark Moving and scaling

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scroll
{
	return personPhotoView;
}

// Fade the overlay out when dragging or zooming the underlying photo...

- (void)scrollViewWillBeginDragging:(UIScrollView *)scroll
{
	self.overlayFaded = YES;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scroll withView:(UIView *)view
{
	self.overlayFaded = YES;
}

// ...and back in when dragging or zooming ends.

- (void)scrollViewDidEndDragging:(UIScrollView *)scroll willDecelerate:(BOOL)decelerate
{
	self.overlayFaded = NO;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scroll withView:(UIView *)zoomedView atScale:(float)scale
{
    // Don't let more than half of the image go off screen.
    CGFloat verticalInset = scroll.frame.size.height - 0.5 * zoomedView.frame.size.height;
    CGFloat horizontalInset = scroll.frame.size.width - 0.5 * zoomedView.frame.size.width;
    scroll.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
	self.overlayFaded = NO;
}

- (void)setOverlayFaded:(BOOL)faded
{
	if (overlayFaded != faded) {
		[UIView beginAnimations:nil context:nil];
		if (faded) {
			foregroundView.alpha = 0.4;
		} else {
			foregroundView.alpha = 0.8;
		}
		[UIView commitAnimations];
		
		overlayFaded = faded;
	}
}

@end
