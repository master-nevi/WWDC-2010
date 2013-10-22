/* File: ImageBrowserSoftEdgeLayer.m

   Abstract: Implementation file for edge masking layer subclass.

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

#import "ImageBrowserSoftEdgeLayer.h"

#import "ImageBrowserOptions.h"

#define EDGE_SIZE 100

@implementation ImageBrowserSoftEdgeLayer

- (void)layoutSublayers
{
  /* When the layer is being used as a mask the alpha at the edge of the
     layer should be zero and one in the middle. When the layer is
     composited over the scroller the alpha should be one at the edge
     and zero in the middle (in which case we only need the two edge
     layers, not the 'middle' layer as well). */

  BOOL invert_alpha = self.superlayer.mask == self;

  CAGradientLayer *top_edge = nil, *bottom_edge = nil;
  CALayer *middle = nil;

  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  if ([self.sublayers count] == 0)
    {
      /* We're assuming in the non-masking case (invert_alpha = YES)
         that the backdrop created by our superlayer is white. So
         create a white gradient whose alpha varies from opaque to
         transparent, with the opaque edge aligned to the inside of the
         layer. In the case where this layer is being used to mask the
         backdrop (invert_alpha = NO) only the alpha values we create
         are relevant, and in that case we want the opaque gradient
         edge to be on the inside, so that only the edges are masked
         out. */

      NSArray *colors = [NSArray arrayWithObjects:
                         (id)[UIColor whiteColor].CGColor,
                         (id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                         nil];

      CGPoint axis0 = CGPointMake(0.5, 0);
      CGPoint axis1 = CGPointMake(0.5, 1);

      top_edge = [CAGradientLayer layer];
      top_edge.colors = colors;
      top_edge.startPoint = !invert_alpha ? axis0 : axis1;
      top_edge.endPoint = !invert_alpha ? axis1 : axis0;

      bottom_edge = [CAGradientLayer layer];
      bottom_edge.colors = colors;
      bottom_edge.startPoint = !invert_alpha ? axis1 : axis0;
      bottom_edge.endPoint = !invert_alpha ? axis0 : axis1;

      if (invert_alpha)
        {
          middle = [CALayer layer];
          middle.backgroundColor = [UIColor whiteColor].CGColor;
        }

      self.sublayers = [NSArray arrayWithObjects:
                        top_edge, bottom_edge, middle, nil];
    }
  else
    {
      top_edge = [self.sublayers objectAtIndex:0];
      bottom_edge = [self.sublayers objectAtIndex:1];
      middle = invert_alpha ? [self.sublayers objectAtIndex:2] : nil;
    }

  CGRect bounds = self.bounds;

  top_edge.frame = CGRectMake(bounds.origin.x, bounds.origin.y,
                              bounds.size.width, EDGE_SIZE);
  bottom_edge.frame = CGRectMake(bounds.origin.x, bounds.origin.y
                                 + bounds.size.height - EDGE_SIZE,
                                 bounds.size.width, EDGE_SIZE);
  if (invert_alpha)
    middle.frame = CGRectInset(bounds, 0, EDGE_SIZE);

  self.masksToBounds = YES;

  [CATransaction commit];
}

@end
