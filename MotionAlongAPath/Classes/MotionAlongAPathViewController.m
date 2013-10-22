//
// File:       MotionAlongAPathViewController.m
//
// Abstract:   We'll animate the blue rectangle (_thumbnail) in this UIViewController subclass
//
// Version:    1.0
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2010 Apple Inc. All Rights Reserved.
//

#import "MotionAlongAPathViewController.h"

#import <QuartzCore/QuartzCore.h>

#define PICTURE_X 160
#define PICTURE_Y 210

#define TRASH_X 620
#define TRASH_Y 900

@implementation MainView

- (void)dealloc
{
    if (_path)
        CFRelease(_path);
    [super dealloc];
}

- (void)setPath:(CGPathRef)path
{
    if (path != _path) {
        if (_path)
            CFRelease(_path);
        _path = CFRetain(path);
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    if (!_path)
        return;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);    
    CGContextAddPath(ctx, _path);
    
    CGContextSetLineWidth(ctx, 2);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextDrawPath(ctx, kCGPathStroke);    
}

@end

@implementation MotionAlongAPathViewController

- (void)thumbnailPressed:(id)sender
{
    // This is the naive approach...
    /*
     [UIView beginAnimations:@"MoveAnimation" context:nil];
     [UIView setAnimationDuration:1.0];
     [_thumbnail setCenter:CGPointMake(TRASH_X, TRASH_Y)];
     [_thumbnail setTransform:CGAffineTransformMakeScale(0.1, 0.1)];
     [_thumbnail setAlpha:0.5];
     [UIView commitAnimations];
     */
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, PICTURE_X, PICTURE_Y);
    CGPathAddQuadCurveToPoint(path, NULL, TRASH_X, PICTURE_Y, TRASH_X, TRASH_Y);
    
    // Uncomment this to draw the path the thumbnail will fallow
    // [_mainView setPath:path];
    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.path = path;
    pathAnimation.duration = 1.0;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D t = CATransform3DMakeScale(0.1, 0.1, 1.0);
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:t];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.toValue = [NSNumber numberWithFloat:0.5f];    
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = [NSArray arrayWithObjects:pathAnimation, scaleAnimation, alphaAnimation, nil];
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animationGroup.duration = 1.0;
    
    [_thumbnail.layer addAnimation:animationGroup forKey:nil];
    
    CFRelease(path);
}

- (void)loadView {

    if (!_mainView) {
        CGRect frame = [[UIScreen mainScreen] applicationFrame];
        _mainView = [[MainView alloc] initWithFrame:frame];
        [_mainView setBackgroundColor:[UIColor whiteColor]];
        [_mainView setOpaque:YES];
        
        _trash = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 160, 160)];
        [_trash setBackgroundColor:[UIColor darkGrayColor]];
        [_trash setCenter:CGPointMake(TRASH_X, TRASH_Y)];
        [_mainView addSubview:_trash];
        
        _thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        [_thumbnail setBackgroundColor:[UIColor blueColor]];
        [_thumbnail setCenter:CGPointMake(PICTURE_X, PICTURE_Y)];
        [_mainView addSubview:_thumbnail];

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thumbnailPressed:)];
        [_thumbnail addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];
        [_thumbnail setUserInteractionEnabled:YES];
                
    }
    self.view = _mainView;
}

- (void)dealloc {
    [_mainView release];
    [_thumbnail release];
    [_trash release];
    
    [super dealloc];
}

@end

