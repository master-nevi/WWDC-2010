/*
     File: PhotoPickerView.m
 Abstract: Presents a series of images, in a paged view (like Safari on the iPhone's), and calls a delegate method when the user selects an image.
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

#import <QuartzCore/QuartzCore.h>

#import "PhotoPickerView.h"

@interface PhotoPickerView ()
@property(nonatomic, retain) NSArray *photoViews;
@end

@interface PhotoPickerView (Private)
- (void)setupPages;
- (void)photoTapped:(UIButton *)sender;
@end

@implementation PhotoPickerView

@synthesize scrollView;
@synthesize pageControl;
@synthesize photoContainer;
@synthesize photoViews;
@synthesize delegate;

@synthesize photos;

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	if (self) {
		
		backgroundLayer = [CAGradientLayer layer];
		CGColorRef topColor = [UIColor colorWithRed:0.57 green:0.63 blue:0.68 alpha:1.0].CGColor;
		CGColorRef bottomColor = [UIColor colorWithRed:0.31 green:0.40 blue:0.47 alpha:1.0].CGColor;
		backgroundLayer.colors = [NSArray arrayWithObjects:(id)topColor, (id)bottomColor, nil];
		
		[self.layer insertSublayer:backgroundLayer atIndex:0];
	}
	
	return self;
}

- (void)dealloc {
    [photos release];
    
    [super dealloc];
}

- (void)setPhotos:(NSArray *)newPhotos
{
    if (![photos isEqualToArray:newPhotos]) {
        [photos release];
        photos = [newPhotos retain];
        
        [self setupPages];
        [self setNeedsLayout];
    }
}

- (void)setupPages
{
	for (UIImageView *photoView in self.photoViews) {
		[photoView removeFromSuperview];
	}
	
	NSUInteger numPhotos = [self.photos count];
	
	pageControl.numberOfPages = numPhotos;
	
	NSMutableArray *newPhotoViews = [NSMutableArray arrayWithCapacity:numPhotos];
	
	for (NSUInteger i = 0; i < numPhotos; i++) {
		UIView *photoFrame = [[UIView alloc] initWithFrame:CGRectZero];
		photoFrame.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		photoFrame.layer.shadowOpacity = 0.4;
		photoFrame.layer.shadowOffset = CGSizeMake(0,2);
		photoFrame.layer.shadowRadius = 3;
		
		UIImageView *photoView = [[UIImageView alloc] initWithFrame:CGRectZero];
		photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		photoView.image = [self.photos objectAtIndex:i];
		photoView.contentMode = UIViewContentModeScaleAspectFill;
		photoView.clipsToBounds = YES;
		
		// This makes the image appear smoother when it's scaled down, on hardware that supports it
		photoView.layer.minificationFilter = kCAFilterTrilinear;
		
		[photoFrame addSubview:photoView];
		[photoView release];
		
		UIButton *photoButton = [[UIButton alloc] initWithFrame:photoView.bounds];
		photoButton.tag = i;
		photoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		[photoButton addTarget:self action:@selector(photoTapped:) forControlEvents:UIControlEventTouchUpInside];
		[photoFrame addSubview:photoButton];
		[photoButton release];
		
		[newPhotoViews addObject:photoFrame];
		
		[photoContainer addSubview:photoFrame];
		[photoFrame release];
	}
	
	self.photoViews = newPhotoViews;
}

- (void)photoTapped:(UIButton *)sender
{
	int photoIndex = sender.tag;
	
	if (photoIndex == pageControl.currentPage) {
        [delegate photoPickerView:self didSelectPhotoAtIndex:photoIndex];
	}
}

- (IBAction)selectPage:(UIPageControl *)sender
{
	[self.scrollView setContentOffset:CGPointMake(sender.currentPage * self.scrollView.bounds.size.width, 0) animated:YES];
}

- (void)layoutSubviews {
	backgroundLayer.frame = self.layer.bounds;
    
    CGSize mainViewSize = self.bounds.size;
	self.scrollView.frame = CGRectMake(mainViewSize.width * .1375, 0, mainViewSize.width * 0.725, mainViewSize.height - 36); // 36 = height of page view control; other numbers = basically arbitrary
	CGSize scrollViewSize = self.scrollView.bounds.size;
	
    NSUInteger numPhotos = [self.photos count];
    
	photoContainer.frame = CGRectMake(0, 0, scrollViewSize.width * numPhotos, scrollViewSize.height);
    self.scrollView.contentSize = photoContainer.bounds.size;
	
	CGSize photoSize = CGSizeMake(mainViewSize.width * 0.6, mainViewSize.height * 0.6);
    
    for (NSUInteger i = 0; i < numPhotos; i++) {
        UIView *photoView = [self.photoViews objectAtIndex:i];
        photoView.frame = CGRectMake(0, 0, photoSize.width, photoSize.height);
        photoView.center = CGPointMake(scrollViewSize.width/2 + i * scrollViewSize.width, scrollViewSize.height/2);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scroll {
	
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
	int page = scrollView.contentOffset.x / scroll.bounds.size.width;
	pageControl.currentPage = page;
}


@end
