//
//  RootView.m
//  Animation101
//
/*
     File: RootView.m
 Abstract: The Root view. The view hosts two layers: a playing card and a ball. The JumpingText class is responsibe for creating CATextLayers. The BallDelegate is used to detect the end of one of the ball animations.
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

#import "RootView.h"
#import <QuartzCore/QuartzCore.h>

#import "Cards.h"
#import "JumpingText.h"
#import "BallDelegate.h"

static CGPoint midPoint(CGRect r)
{
    return CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
}
// Positive random number in this range
static CGFloat randomNumber(CGFloat min, CGFloat max) {
    return (((CGFloat)random())/((CGFloat) RAND_MAX))*(max-min)+min;
}

static CATransform3D CATransform3DMakePerspective(CGFloat z)
{
    CATransform3D t = CATransform3DIdentity;
    t.m34 = - 1. / z;
    return t;
}

@implementation RootView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // for demo purposes, use viewState
         viewState = 0;
 
        // Add perspective for the rotation
        
        self.layer.sublayerTransform = CATransform3DMakePerspective(-900);
        
        // Now add the sub layers

        // Add the card layer
        spadeAce = [CALayer layer];
        [spadeAce retain];
        // The properties of the card:
        spadeAce.bounds = CGRectMake(0, 0, 190, 280);
        // Center it in the view
        spadeAce.position = CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds));
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGFloat components[4] = {0.4, 0.8, 1, 0.6};
        CGColorRef cardBackColor = CGColorCreate(space,components);
        spadeAce.backgroundColor = cardBackColor;
        CGColorRelease(cardBackColor);
        spadeAce.opaque = NO;
        // The card has a dark gray border with rounded corners
        spadeAce.borderWidth = 5;
        spadeAce.borderColor = [UIColor darkGrayColor].CGColor;
        spadeAce.cornerRadius = 5.0;
    
        [self.layer addSublayer:spadeAce];
        
        // Add the pips
        CAShapeLayer* centerPip = [Cards spadePip];
        centerPip.position = midPoint(spadeAce.bounds);
        [spadeAce addSublayer:centerPip];
        
        CGFloat components1[4] = {0.1, 0.1, 0.1, 0.98};
        CGColorRef almostBlack = CGColorCreate(space,components1);
        CGColorSpaceRelease(space);
        // Top pip
        CATextLayer* A = [[CATextLayer alloc] init];
        A.string = @"A";
        A.bounds = CGRectMake(0, 0, 30, 24);
        A.foregroundColor = almostBlack;
        A.position = CGPointMake(26,20);
        A.fontSize = 26;
        [spadeAce addSublayer:A];
        [A release];
        CGColorRelease(almostBlack);
        
        CAShapeLayer* indexTop = [Cards spadePip];
        indexTop.position = CGPointMake(20, 44);
        indexTop.transform = CATransform3DMakeScale(0.5, 0.5, 1);
        [spadeAce addSublayer:indexTop];

        // Bottom pip
        A = [[CATextLayer alloc] init];
        A.string = @"A";
        A.bounds = CGRectMake(0, 0, 30, 24);
        A.foregroundColor = almostBlack;
        A.position = CGPointMake(CGRectGetMaxX(spadeAce.bounds)-26, CGRectGetMaxY(spadeAce.bounds)-20);
        A.transform = CATransform3DMakeRotation( M_PI, 0, 0, 1);
        A.fontSize = 26;
        [spadeAce addSublayer:A];
        [A release];

        CATransform3D transform = CATransform3DMakeScale(0.5, 0.5, 1);
        transform = CATransform3DRotate(transform, M_PI, 0, 0, 1);
       
        CAShapeLayer* indexBottom = [Cards spadePip];
        indexBottom.position = CGPointMake(CGRectGetMaxX(spadeAce.bounds)-20, CGRectGetMaxY(spadeAce.bounds)-44);
        indexBottom.transform =transform;
        
        [spadeAce addSublayer:indexBottom];
        
        // Create a ball, position it offscreen
        ball = [[CALayer alloc] init];
        ball.bounds = CGRectMake(0, 0, 60, 60);
        ball.position = CGPointMake(CGRectGetMidX(self.bounds), -60);
        ballDelegate = [[BallDelegate alloc] init];
        ballDelegate.parent = self;
        ball.delegate = ballDelegate;
        [ball setNeedsDisplay];
        [self.layer addSublayer:ball];
        
        // Jumping text:
        jumping = [[JumpingText alloc] init];
        
        // Recognize a tap gesture to cycle through the animations
        UITapGestureRecognizer* recognizeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
        [self addGestureRecognizer:recognizeTap];
        [recognizeTap release];
    }
    return self;
}

-(void) dealloc
{
    [spadeAce release];
    [jumping release];
    [ballDelegate release];
    [super dealloc];
}

- (void)scatterLetters {
    // This animation sends the letters scattering in random directions,
    // and then fading away.
    // An animation group is added to each letter layer.
    // The group is up of two basic animations: one to move and one to fade.
    // We use the CAMediaTiming protocol to delay the fade by 2 seconds.
        
    CGFloat animationTime = 5;
    // Delayed fade
    CABasicAnimation* fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = [NSNumber numberWithFloat:1];
    fade.toValue = [NSNumber numberWithFloat:0];
    fade.duration = animationTime-2;
    fade.beginTime = 2;
    CALayer* letter;
    for(letter in jumping)
    {
        CGFloat x = randomNumber(0, CGRectGetMaxX(self.bounds));
        CGFloat y = randomNumber(0, CGRectGetMaxY(self.bounds));
        CABasicAnimation* move = [CABasicAnimation animationWithKeyPath:@"position"];
        move.toValue = [NSValue valueWithCGPoint:CGPointMake(x, y)];
        move.duration = animationTime;
        CAAnimationGroup* moveAndVanish = [CAAnimationGroup animation];
        moveAndVanish.animations = [NSArray arrayWithObjects:fade,move,nil];
        moveAndVanish.duration = animationTime;
        moveAndVanish.removedOnCompletion = NO;
        moveAndVanish.fillMode = kCAFillModeForwards;
        [letter addAnimation:moveAndVanish forKey:nil];
    }
}

- (void)tapRecognized:(UIGestureRecognizer *)gestureRecognizer {
    // The first time a click occurs, rotate the card.
    if(viewState==0) {
        [CATransaction setAnimationDuration:3];
        spadeAce.transform = CATransform3DMakeRotation(1.2, -1, -1, 0);
        ++viewState;
    } else if (viewState == 1) {
        // An implicit animation to send the card back
        [CATransaction setAnimationDuration:1];
        spadeAce.transform = CATransform3DIdentity;
         ++viewState;
    } else if (viewState == 2){
        // Add some CATextLayers
        spadeAce.opacity = 0;
        [jumping addTextLayersTo:self.layer];
        ++viewState;
    } else if (viewState==3) {
        // Lets go bowling!
        CABasicAnimation* move = [CABasicAnimation animationWithKeyPath:@"position.y"];
        move.duration = 2;
        // Take the radius of the ball into account when computing the strike point
        move.toValue = [NSNumber numberWithFloat:[jumping topOfString]-CGRectGetHeight(ball.bounds)/2];
        move.delegate = ballDelegate;
        [ball addAnimation:move forKey:@"bowl"];
        ++viewState;
    } else if (viewState==4) {
        [jumping removeTextLayers];
        // A bouncing ball that uses linear timing.
        // KeyFrame animation
        ball.position = CGPointMake(20, 20);
        CAKeyframeAnimation* bounce = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        bounce.duration = 4;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, 20, 20);
        CGPathAddLineToPoint(path, NULL, CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)-20);
        CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.bounds)-20, 20);
        bounce.path = path;
        CGPathRelease(path);
        bounce.autoreverses = YES;
        bounce.repeatCount = HUGE_VALF;
        [ball addAnimation:bounce forKey:@"bounce"];
        ++viewState;
    }  else {
        [jumping removeTextLayers];
    
        CGPoint p = CGPointMake(CGRectGetMidX(self.bounds), -30);
        // Kill the bounce animation
        CABasicAnimation* stop = [CABasicAnimation animationWithKeyPath:@"position"];
        stop.toValue    = [NSValue valueWithCGPoint:p];
        [ball addAnimation:stop forKey:@"bounce"];
        // Move the ball of the screen
        ball.position = p;
        spadeAce.opacity = 1;
        viewState = 0;
    }
}

@end
