/*
     File: PhotoViewController.m
 Abstract: Configures and displays the paging scroll view and handles tiling and page configuration.
  Version: 1.0
 
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

#import "PhotoViewController.h"
#import "ImageScrollView.h"

@implementation PhotoViewController

#pragma mark -
#pragma mark View loading and unloading

- (void)loadView 
{    
    // Step 1: make the outer paging scroll view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    pagingScrollView.pagingEnabled = YES;
    pagingScrollView.backgroundColor = [UIColor blackColor];
    pagingScrollView.showsVerticalScrollIndicator = NO;
    pagingScrollView.showsHorizontalScrollIndicator = NO;
    pagingScrollView.contentSize = CGSizeMake(pagingScrollViewFrame.size.width * [self imageCount],
                                              pagingScrollViewFrame.size.height);
    pagingScrollView.delegate = self;
    self.view = pagingScrollView;
    
    // Step 2: prepare to tile content
    recycledPages = [[NSMutableSet alloc] init];
    visiblePages  = [[NSMutableSet alloc] init];
    [self tilePages];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [pagingScrollView release];
    pagingScrollView = nil;
    [recycledPages release];
    recycledPages = nil;
    [visiblePages release];
    visiblePages = nil;
}

- (void)dealloc
{
    [pagingScrollView release];
    [super dealloc];
}


#pragma mark -
#pragma mark Tiling and page configuration

- (void)tilePages 
{
    // Calculate which pages are visible
    CGRect visibleBounds = pagingScrollView.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self imageCount] - 1);

    // Recycle no-longer-visible pages 
    for (ImageScrollView *page in visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            [recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [visiblePages minusSet:recycledPages];
    
    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            ImageScrollView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[[ImageScrollView alloc] init] autorelease];
            }
            [self configurePage:page forIndex:index];
            [pagingScrollView addSubview:page];
            [visiblePages addObject:page];
        }
    }    
}

- (ImageScrollView *)dequeueRecycledPage
{
    ImageScrollView *page = [recycledPages anyObject];
    if (page) {
        [[page retain] autorelease];
        [recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (ImageScrollView *page in visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (void)configurePage:(ImageScrollView *)page forIndex:(NSUInteger)index
{
    page.index = index;
    page.frame = [self frameForPageAtIndex:index];
    
    // Use tiled images
    [page displayTiledImageNamed:[self imageNameAtIndex:index]
                            size:[self imageSizeAtIndex:index]];
    
    // To use full images instead of tiled images, replace the "displayTiledImageNamed:" call
    // above by the following line:
    // [page displayImage:[self imageAtIndex:index]];
}


#pragma mark -
#pragma mark ScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePages];
}


#pragma mark -
#pragma mark  Frame calculations
#define PADDING  10

- (CGRect)frameForPagingScrollView {
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    CGRect pageFrame = pagingScrollViewFrame;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (pagingScrollViewFrame.size.width * index) + PADDING;
    return pageFrame;
}


#pragma mark -
#pragma mark Image wrangling

- (NSArray *)imageData {
    static NSArray *__imageData = nil; // only load the imageData array once
    if (__imageData == nil) {
        // read the filenames/sizes out of a plist in the app bundle
        NSString *path = [[NSBundle mainBundle] pathForResource:@"ImageData" ofType:@"plist"];
        NSData *plistData = [NSData dataWithContentsOfFile:path];
        NSString *error; NSPropertyListFormat format;
        __imageData = [[NSPropertyListSerialization propertyListFromData:plistData
                                                        mutabilityOption:NSPropertyListImmutable
                                                                  format:&format
                                                        errorDescription:&error]
                       retain];
        if (!__imageData) {
            NSLog(@"Failed to read image names. Error: %@", error);
            [error release];
        }
    }
    return __imageData;
}

- (UIImage *)imageAtIndex:(NSUInteger)index {
    // use "imageWithContentsOfFile:" instead of "imageNamed:" here to avoid caching our images
    NSString *imageName = [self imageNameAtIndex:index];
    NSString *path = [[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"];
    return [UIImage imageWithContentsOfFile:path];    
}

- (NSString *)imageNameAtIndex:(NSUInteger)index {
    NSString *name = nil;
    if (index < [self imageCount]) {
        NSDictionary *data = [[self imageData] objectAtIndex:index];
        name = [data valueForKey:@"name"];
    }
    return name;
}

- (CGSize)imageSizeAtIndex:(NSUInteger)index {
    CGSize size = CGSizeZero;
    if (index < [self imageCount]) {
        NSDictionary *data = [[self imageData] objectAtIndex:index];
        size.width = [[data valueForKey:@"width"] floatValue];
        size.height = [[data valueForKey:@"height"] floatValue];
    }
    return size;
}

- (NSUInteger)imageCount {
    static NSUInteger __count = NSNotFound;  // only count the images once
    if (__count == NSNotFound) {
        __count = [[self imageData] count];
    }
    return __count;
}


@end
