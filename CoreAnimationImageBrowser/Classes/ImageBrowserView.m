/* File: ImageBrowserView.m

   Abstract: Image browser scroll view implementation file.

   Version: 1.0

   Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
   Apple Inc. ("Apple") in consideration of your agreement to the
   following terms, and your use, installation, modification or
   redistribution of this Apple software constitutes acceptance of
   these terms.  If you do not agree with these terms, please do not
   use, install, modify or redistribute this Apple software.

   In consideration of your agreement to abide by the following terms,
   and subject to these terms, Apple grants you a personal,
   non-exclusive license, under Apple's copyrights in this original
   Apple software (the "Apple Software"), to use, reproduce, modify and
   redistribute the Apple Software, with or without modifications, in
   source and/or binary forms; provided that if you redistribute the
   Apple Software in its entirety and without modifications, you must
   retain this notice and the following text and disclaimers in all
   such redistributions of the Apple Software.  Neither the name,
   trademarks, service marks or logos of Apple Inc.  may be used to
   endorse or promote products derived from the Apple Software without
   specific prior written permission from Apple.  Except as expressly
   stated in this notice, no other rights or licenses, express or
   implied, are granted by Apple herein, including but not limited to
   any patent rights that may be infringed by your derivative works or
   by other works in which the Apple Software may be incorporated.

   The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
   MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT
   LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE
   APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH
   YOUR PRODUCTS.

   IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
   INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE
   USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE
   SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
   (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE
   HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   Copyright (C) 2010 Apple Inc. All Rights Reserved. */

#import "ImageBrowserView.h"

#import "ImageBrowserAppDelegate.h"
#import "ImageBrowserItemView.h"
#import "ImageBrowserSoftEdgeLayer.h"
#import "ImageBrowserOptions.h"
#import "ImageBrowserViewController.h"

#import <QuartzCore/QuartzCore.h>

#define ITEM_BORDER 20
#define ITEM_SPACING 20
#define ITEM_WIDTH 300
#define ITEM_HEIGHT 225

@implementation ImageBrowserView

@synthesize controller = _controller;

- (void)dealloc
{
  [_imageURLs release];
  [_itemViews release];
  [super dealloc];
}

- (void)viewDidLoad
{
}

- (NSArray *)imageURLs
{
  return _imageURLs;
}

- (void)setImageURLs:(NSArray *)array
{
  if (_imageURLs != array)
    {
      [_imageURLs release];
      _imageURLs = [array copy];
      [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
  NSInteger i, j, item_count, old_view_count;
  NSURL *url;
  ImageBrowserItemView *view;
  NSMutableArray *old_views;
  CGFloat x, y;
  CGRect bounds, frame;

  item_count = [_imageURLs count];
  old_views = _itemViews;
  _itemViews = [[NSMutableArray alloc] init];
  old_view_count = [old_views count];
  bounds = [self bounds];

  if (_lastWidth != bounds.size.width)
    {
      _lastWidth = bounds.size.width;
      _itemSize = CGSizeMake (ITEM_WIDTH, ITEM_HEIGHT);
    }

  x = ITEM_BORDER;
  y = ITEM_BORDER;

  for (i = 0; i < item_count; i++)
    {
      frame = CGRectMake (x, y, _itemSize.width, _itemSize.height);
      url = [_imageURLs objectAtIndex:i];

      for (j = 0; j < old_view_count; j++)
        {
          view = [old_views objectAtIndex:j];
          if ([[view imageURL] isEqual:url])
            {
              [view setFrame:frame];
              [old_views removeObjectAtIndex:j];
              old_view_count--;
              goto got_view;
            }
        }

      view = [ImageBrowserItemView itemViewWithFrame:frame imageURL:url];
      view.opaque = OPAQUE_ITEM_VIEWS ? YES : NO;

      [self addSubview:view];

    got_view:
      [_itemViews addObject:view];

      x += _itemSize.width + ITEM_SPACING;
      if (x + _itemSize.width + ITEM_BORDER > bounds.size.width)
        {
          x = ITEM_BORDER;
          y += _itemSize.height + ITEM_SPACING;
        }
    }

  if (x > ITEM_BORDER)
    y += _itemSize.height + ITEM_BORDER;

  [self setContentSize:CGSizeMake (bounds.size.width, y)];

  for (view in old_views)
    [view removeFromSuperview];
  [old_views release];

#if SOFT_SCROLLER_EDGES != 0
  if (_softEdgeLayer == nil)
    _softEdgeLayer = [ImageBrowserSoftEdgeLayer layer];

  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  if (SOFT_SCROLLER_EDGES == 1)
    self.layer.mask = _softEdgeLayer;
  else
    [self.layer addSublayer:_softEdgeLayer];

  _softEdgeLayer.frame = self.bounds;

  [CATransaction commit];
#endif
}

@end
