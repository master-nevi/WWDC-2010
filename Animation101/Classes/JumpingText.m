//
//  JumpingText.m
//  Animation101
//
/*
     File: JumpingText.m
 Abstract: Creates and manages a CATextLayer for each character in a sentence.
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

#import "JumpingText.h"
#import <QuartzCore/QuartzCore.h>

@implementation JumpingText
@synthesize topOfString;

-(void) dealloc
{    
    CALayer* letter;
    for(letter in letters)
    {
        [letter removeFromSuperlayer];
    }
    [letters release];
    [super dealloc];
}
    
-(void) addTextLayersTo:(CALayer*) layer
{
    // If necessary, create container for the text layers
    if(!letters)
    {
        letters = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    CALayer* letter;
    for(letter in letters)
    {
        [letter removeFromSuperlayer];
    }
    
    [letters removeAllObjects];
    
    CGFontRef font = CGFontCreateWithFontName(CFSTR("Courier"));
    NSString* text = @"The quick brown fox";
    CGFloat fontSize = 28;
    // We are using a mono-spaced font, so
    CGFloat textWidth = [text length]*fontSize;
    // We want to center the text
    CGFloat xStart= CGRectGetMidX(layer.bounds)-textWidth/2.0;
    NSUInteger i;
    for(i=0;i<1;++i)
    {
        CGPoint pos = CGPointMake(xStart,CGRectGetMaxY(layer.bounds)-50);
        NSUInteger k;
        for(k=0;k<text.length;++k)
        {
            CATextLayer* letter = [[CATextLayer alloc] init];
            [letters addObject:letter];

            letter.foregroundColor = [UIColor blueColor].CGColor;
            letter.bounds = CGRectMake(0, 0, fontSize, fontSize);
            letter.position = pos;
            letter.font = font;
            letter.fontSize = fontSize;
            letter.string = [text substringWithRange:NSMakeRange(k, 1)];
            [layer addSublayer:letter];
            [letter release];
            pos.x+=fontSize;
        }
    }
    CGFontRelease(font);
    topOfString = CGRectGetMaxY(layer.bounds)-50;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
    return [letters countByEnumeratingWithState:state objects:stackbuf count:len];
}

-(void) removeTextLayers
{
    CALayer* l;
    for(l in letters)
    {
        [l removeFromSuperlayer];
    }
}

@end
