/* File: ImageBrowserItemLayer.m

   Abstract: Implementation of thumbnail view's backing layer.

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

#import "ImageBrowserItemLayer.h"

#import "ImageBrowserOptions.h"

@interface ImageBrowserItemLayer ()
- (UIImage *)loadImage;
- (UIImage *)loadImageInForeground;
- (void)loadImageInBackground;
@end

@implementation ImageBrowserItemLayer

@dynamic imageURL;
@dynamic image;

static BOOL _imageThreadRunning;
static NSMutableArray *_imageQueue;

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

#if DOWNSAMPLE_IMAGES
  self.needsDisplayOnBoundsChange = YES;
#else
  self.contentsGravity = kCAGravityResizeAspect;
  self.shadowOpacity = .5;
  self.shadowRadius = 5;
  self.shadowOffset = CGSizeMake (0, 6);
# if USE_SHADOW_PATH
  self.shadowPath = [UIBezierPath bezierPath].CGPath;
# endif
#endif

  return self;
}

- (void)didChangeValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"imageURL"])
    {
      self.image = nil;
      [self loadImage];
    }
  else if ([key isEqualToString:@"image"])
    {
#if !DOWNSAMPLE_IMAGES
      self.contents = (id) self.image.CGImage;
      [self setNeedsLayout];
#else
      [self setNeedsDisplay];
#endif
    }

  [super didChangeValueForKey:key];
}

- (UIImage *)loadImage
{
  UIImage *image;

  /* In case we're being called from the background thread. */

  [CATransaction lock];
  image = [[self.image retain] autorelease];
  [CATransaction unlock];

  if (image == nil)
    {
#if !USE_IMAGE_THREAD
      image = [self loadImageInForeground];
#else
      [self loadImageInBackground];
#endif
    }

  return image;
}

- (void)layoutSublayers
{
#if USE_SHADOW_PATH && !DOWNSAMPLE_IMAGES
  UIImage *image = [self loadImage];

  if (image != nil)
    {
      CGSize s = image.size;
      CGRect r = self.bounds;
      CGFloat scale = MIN (r.size.width / s.width, r.size.height / s.height);
      s.width *= scale; s.height *= scale;
      r.origin.x += (r.size.width - s.width) * .5;
      r.size.width = s.width;
      r.origin.y += (r.size.height - s.height) * .5;
      r.size.height = s.height;

      self.shadowPath = [UIBezierPath bezierPathWithRect:r].CGPath;
    }
#endif
}

#if DOWNSAMPLE_IMAGES
- (void)drawInContext:(CGContextRef)ctx
{
  CGRect bounds = self.bounds;
  UIImage *image;

  if (self.opaque)
    {
      CGContextSetGrayFillColor (ctx, 1, 1);
      CGContextFillRect (ctx, bounds);
    }

  CGColorRef color = [[UIColor colorWithWhite:0 alpha:.5] CGColor];
  CGContextSetShadowWithColor (ctx, CGSizeMake (0, 6), 10, color);

  image = [self loadImage];

  if (image != nil)
    {
      CGSize s = image.size;
      CGRect r = CGRectInset (bounds, 8, 8);
      CGFloat scale = MIN (r.size.width / s.width, r.size.height / s.height);
      s.width *= scale; s.height *= scale;
      r.origin.x += (r.size.width - s.width) * .5;
      r.size.width = s.width;
      r.origin.y += (r.size.height - s.height) * .5;
      r.size.height = s.height;

      CGContextSaveGState (ctx);
      CGContextTranslateCTM (ctx, 0, bounds.size.height);
      CGContextScaleCTM (ctx, 1, -1);
      CGContextDrawImage (ctx, r, image.CGImage);
      CGContextRestoreGState (ctx);
    }
}
#endif /* DOWNSAMPLE_IMAGES */

- (UIImage *)loadImageInForeground
{
  self.image = [UIImage imageWithContentsOfFile:[self.imageURL path]];

  [CATransaction lock];
  UIImage *image = [[self.image retain] autorelease];
  [CATransaction unlock];

  return image;
}

- (void)loadImageInBackground
{
  if (self.imageURL != nil)
    {
      [CATransaction lock];

      if (!_imageQueue)
        _imageQueue = [[NSMutableArray alloc] init];

      if ([_imageQueue indexOfObjectIdenticalTo:self] == NSNotFound)
        {
          [_imageQueue addObject:self];

          if (!_imageThreadRunning)
            {
              [NSThread detachNewThreadSelector:@selector(imageThread:)
               toTarget:[self class] withObject:nil];
              _imageThreadRunning = YES;
            }
        }

      [CATransaction unlock];
    }
}

+ (void)imageThread:(id)unused
{
  [CATransaction lock];

  while ([_imageQueue count] != 0)
    {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

      ImageBrowserItemLayer *layer = [_imageQueue objectAtIndex:0];

      [CATransaction unlock];
      [layer loadImageInForeground];
      [CATransaction flush];
      [CATransaction lock];

      NSInteger idx = [_imageQueue indexOfObjectIdenticalTo:layer];
      if (idx != NSNotFound)
        [_imageQueue removeObjectAtIndex:idx];

      [pool drain];
    }

  _imageThreadRunning = NO;
  [CATransaction unlock];
}

@end
