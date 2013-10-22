//
//  Suits.m
//  Animation101
//
/*
     File: Cards.m
 Abstract: Creates a Spade pip CASHapeLayer
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

#import "Cards.h"

@implementation Cards

+(CAShapeLayer*) spadePip
{    
    CAShapeLayer* spade = [[CAShapeLayer alloc] init];
    spade.bounds = CGRectMake(0, 0, 48, 64);
    
    CGMutablePathRef path = CGPathCreateMutable();
     
    CGPoint p1, p2, p3;
    p1 = CGPointMake(24,15);
    p2 = CGPointMake(4,10);
    p3 = CGPointMake(4,30);
    
    CGPathMoveToPoint(path, NULL,24,4);
    
    CGPathAddCurveToPoint(path, NULL,p1.x,p1.y,p2.x,p2.y,p3.x,p3.y);
 
    p1 = CGPointMake(4,40);
    p2 = CGPointMake(14,50);
    p3 = CGPointMake(22,40);
    CGPathAddCurveToPoint(path, NULL,p1.x,p1.y,p2.x,p2.y,p3.x,p3.y);
    
    p3 = CGPointMake(9,60);
    CGPathAddLineToPoint(path, NULL,p3.x,p3.y);
    p3 = CGPointMake(39,60);
    CGPathAddLineToPoint(path, NULL,p3.x,p3.y);
    p3 = CGPointMake(26,40);
    CGPathAddLineToPoint(path, NULL,p3.x,p3.y);
    
    // Now reverse the two curves above
    p2 = CGPointMake(44,40);
    p1 = CGPointMake(34,50);
    p3 = CGPointMake(44,30);
    CGPathAddCurveToPoint(path, NULL,p1.x,p1.y,p2.x,p2.y,p3.x,p3.y);

    p2 = CGPointMake(24,15);
    p1 = CGPointMake(44,10);
    p3 = CGPointMake(24,2);
    CGPathAddCurveToPoint(path, NULL,p1.x,p1.y,p2.x,p2.y,p3.x,p3.y);
    
    CGPathCloseSubpath(path);
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGFloat components[4] = {0.1, 0.1, 0.1, 0.98};
    CGColorRef almostBlack = CGColorCreate(space,components);
    
    spade.fillColor = almostBlack;
    spade.path  = path;
    CGPathRelease(path);
    CGColorSpaceRelease(space);
    CGColorRelease(almostBlack);
    
    return [spade autorelease];
}
@end
