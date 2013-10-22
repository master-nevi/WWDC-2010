/*
     File: Avatar.m
 Abstract: Creates a layer tree containing a skeleton, and animates the movement.
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

#import "Avatar.h"
#import <QuartzCore/QuartzCore.h>

@implementation Avatar
@synthesize layer=avatar;

- (id)init
{
	if (self = [super init])
	{
		//Create the base layer
		avatar = [[CALayer alloc] init];
		avatar.bounds = CGRectMake(0, 0, 200, 400);
		
		//Create the head
		head = [CAShapeLayer layer];
		UIImage* headImage = [UIImage imageNamed:@"head.png"];
		head.contents = (id) headImage.CGImage;
		CGSize sz = headImage.size;
		head.bounds = CGRectMake(0,0,sz.width,sz.height);
		head.position = CGPointMake(CGRectGetMidX(avatar.bounds)-50, 0);
		//Add the head to the base layer
		[avatar addSublayer:head];
		
		
		//Scale to be applied to all bones to make the size proportionate to the head
		const CGFloat boneScale = 0.65;
		CATransform3D scale = CATransform3DMakeScale(boneScale , boneScale, 1);
		
		
		//Create the humerus
		humerus = [CALayer layer];
		UIImage* skelHumerus = [UIImage imageNamed:@"Humerus.png"];
		humerus.contents = (id) skelHumerus.CGImage;
		sz = skelHumerus.size;
		humerus.bounds = CGRectMake(0,0,sz.width,sz.height);
		humerus.position = CGPointMake(CGRectGetMidX(avatar.bounds)+60, 180);
		//set the anchorpoint to physical joint location
		humerus.anchorPoint = CGPointMake(0, 1);
		humerus.transform = scale;
		//Add the humerus to the base layer
		[avatar addSublayer:humerus];
		
		//Create the Radius/Ulna
		radiusUlna = [CALayer layer];
		UIImage* skelRadUlna = [UIImage imageNamed:@"RadUlna.png"];
		radiusUlna.contents = (id) skelRadUlna.CGImage;
		sz = skelRadUlna.size;
		radiusUlna.bounds = CGRectMake(0,0,sz.width,sz.height);
		radiusUlna.transform = CATransform3DMakeRotation(0.3, 0, 0, 1);
		radiusUlna.position = CGPointMake(CGRectGetMaxX(humerus.bounds)-10, 90);
		//set the anchorpoint to physical joint location
		radiusUlna.anchorPoint = CGPointMake(0, 0.5);
		//add this layer as a sublayer to the humerus
		[humerus addSublayer:radiusUlna];
		
		
		hand = [CALayer layer];
		UIImage* skelhand = [UIImage imageNamed:@"Hand.png"];
		hand.contents = (id) skelhand.CGImage;
		hand.bounds = CGRectMake(0,0,180,100);
		hand.position = CGPointMake(CGRectGetMaxX(radiusUlna.bounds)-15, CGRectGetMidY(radiusUlna.bounds)-10);
		//set the anchorpoint to physical joint location
		hand.anchorPoint = CGPointMake(0, 0.5);
		CATransform3D t2 = CATransform3DMakeScale(0.8, 0.8, 1);
		t2 = CATransform3DRotate(t2, 0.3, 0, 0, 1);
		hand.transform = t2;
		//add this layer as a sublayer to the radius/ulna
		[radiusUlna addSublayer:hand];
		
		//Scale the entire avatar to fit on the screen
		avatar.transform = CATransform3DMakeScale(0.7, 0.7, 1);
	}
	
    return self;
}

-(void) wave
{
	//Create the head bob animation
    CAKeyframeAnimation* bob = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D r[3] = {CATransform3DMakeRotation(0.0, 0, 0, 1),
							CATransform3DMakeRotation(-0.2, 0, 0, 1),
							CATransform3DMakeRotation(0.2, 0, 0, 1) };
    bob.values = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:r[0]],
                  [NSValue valueWithCATransform3D:r[1]],[NSValue valueWithCATransform3D:r[0]],
                  [NSValue valueWithCATransform3D:r[2]],
                  [NSValue valueWithCATransform3D:r[0]],
                  nil];
    bob.repeatCount = HUGE_VAL;
    bob.duration = 1.75;
    bob.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [head addAnimation:bob forKey:nil];
    
	//Create the first rotation animation (the humerus)
    CABasicAnimation* r1 = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D rot1 = CATransform3DMakeRotation(-0.5, 0, 0, 1);
    rot1 = CATransform3DConcat(rot1, humerus.transform);
    r1.toValue = [NSValue valueWithCATransform3D:rot1];
    r1.autoreverses = YES;
    r1.repeatCount = HUGE_VAL;
    r1.duration = 2.5;
    r1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [humerus addAnimation:r1 forKey:nil];
    
	//Create the second rotation animation (the radius/ulna)
    CABasicAnimation* r2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D rot2 = CATransform3DMakeRotation(-0.7, 0, 0, 1);
    rot2 = CATransform3DConcat(rot2, radiusUlna.transform);
    r2.toValue = [NSValue valueWithCATransform3D:rot2];
    r2.autoreverses = YES;
    r2.repeatCount = HUGE_VAL;
    r2.duration = 2.5;
    r2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [radiusUlna addAnimation:r2 forKey:nil];
    
	//Create the third rotation animation (the hand)
    CABasicAnimation* r3 = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D rot3 = CATransform3DMakeRotation(-0.9, 0, 0, 1);
    rot3 = CATransform3DConcat(rot3, hand.transform);
    r3.toValue = [NSValue valueWithCATransform3D:rot3];
    r3.autoreverses = YES;
    r3.repeatCount = HUGE_VAL;
    r3.duration = 2.5;
    r3.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [hand addAnimation:r3 forKey:nil];
}
@end
