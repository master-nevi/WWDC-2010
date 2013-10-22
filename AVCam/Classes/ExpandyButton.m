/*
     File: ExpandyButton.m
 Abstract: Class that implements the HUD configuration buttons: Flash, Torch, Focus, etc.
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

#import "ExpandyButton.h"
#import <QuartzCore/QuartzCore.h>

// Measurements
const CGFloat width = 64.f;
const CGFloat frameHeight = 32.f;
const CGFloat titleXOrigin = 8.f;
const CGFloat titleYOrigin = 9.f;
const CGFloat titleHeight = 16.f;
const CGFloat titleWidth = 44.f;
const CGFloat buttonHeight = 26.f;
const CGFloat labelHeight = 39.f;
const CGFloat labelXOrigin = 54.f;
const CGFloat labelYOrigin = -3.f;
const CGFloat defaultButtonWidth = 40.f;
const CGFloat fontSize = 14.f;

// HUD Appearance
const CGFloat layerWhite = 1.f;
const CGFloat layerAlpha = .5f;
const CGFloat borderWhite = .0f;
const CGFloat borderAlpha = 1.f;
const CGFloat borderWidth = 1.f;


@interface ExpandyButton ()

@property (nonatomic,assign) BOOL expanded;
@property (nonatomic,assign) CGRect frameExpanded;
@property (nonatomic,assign) CGRect frameShrunk;
@property (nonatomic,assign) CGFloat buttonWidth;
@property (nonatomic,retain) UILabel *titleLabel;
@property (nonatomic,retain) NSArray *labels;

@end

@implementation ExpandyButton

@synthesize expanded = _expanded;
@synthesize frameExpanded = _frameExpanded;
@synthesize frameShrunk = _frameShrunk;
@synthesize buttonWidth = _buttonWidth;
@synthesize titleLabel = _titleLabel;
@synthesize labels = _labels;
@dynamic selectedItem;

- (id)initWithPoint:(CGPoint)point title:(NSString *)title buttonNames:(NSArray *)buttonNames selectedItem:(NSInteger)selectedItem buttonWidth:(CGFloat)buttonWidth
{
    CGRect frameShrunk = CGRectMake(point.x, point.y, width + buttonWidth, frameHeight);
    CGRect frameExpanded = CGRectMake(point.x, point.y, width + buttonWidth * [buttonNames count], frameHeight);
    if ((self = [super initWithFrame:frameShrunk])) {
        [UIView setAnimationsEnabled:NO];
        [self setFrameShrunk:frameShrunk];
        [self setFrameExpanded:frameExpanded];
        [self setButtonWidth:buttonWidth];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleXOrigin, titleYOrigin, titleWidth, titleHeight)];
        [titleLabel setText:title];
        [titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:titleLabel];
        [self setTitleLabel:titleLabel];
        
        NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity:3];
        NSInteger index = 0;
        UILabel *label;
        for (NSString *buttonName in buttonNames) {
            label = [[UILabel alloc] initWithFrame:CGRectMake(labelXOrigin + (buttonWidth * index), labelYOrigin, buttonWidth, buttonHeight)];
            [label setText:buttonName];
            [label setFont:[UIFont systemFontOfSize:fontSize]];
            [label setTextColor:[UIColor blackColor]];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextAlignment:UITextAlignmentCenter];
            [self addSubview:label];
            [labels addObject:label];
            [label release];
            index += 1;
        }
        
        [self setLabels:[labels copy]];
        [labels release];
        
        [self addTarget:self action:@selector(chooseLabel:forEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self setBackgroundColor:[UIColor clearColor]];
        
        CALayer *layer = [self layer];
        [layer setBackgroundColor:[[UIColor colorWithWhite:layerWhite alpha:layerAlpha] CGColor]];
        [layer setBorderWidth:borderWidth];
        [layer setBorderColor:[[UIColor colorWithWhite:borderWhite alpha:borderAlpha] CGColor]];
        [layer setCornerRadius:15.f];
        
        [self setExpanded:YES];
        
        [self setSelectedItem:selectedItem];
        [UIView setAnimationsEnabled:YES];
    }
    return self;    
}

- (id)initWithPoint:(CGPoint)point title:(NSString *)title buttonNames:(NSArray *)buttonNames selectedItem:(NSInteger)selectedItem
{
    return [self initWithPoint:point title:title buttonNames:buttonNames selectedItem:selectedItem buttonWidth:defaultButtonWidth];    
}

- (id)initWithPoint:(CGPoint)point title:(NSString *)title buttonNames:(NSArray *)buttonNames
{
    return [self initWithPoint:point title:title buttonNames:buttonNames selectedItem:0 buttonWidth:defaultButtonWidth];
}

- (void)chooseLabel:(id)sender forEvent:(UIEvent *)event
{
    [UIView beginAnimations:nil context:NULL];
    if ([self expanded] == NO) {
        [self setExpanded:YES];
        
        NSInteger index = 0;
        for (UILabel *label in [self labels]) {
            if (index == [self selectedItem]) {
                [label setFont:[UIFont boldSystemFontOfSize:fontSize]];
            } else {
                [label setTextColor:[UIColor colorWithWhite:0.f alpha:.8f]];
            }
            [label setFrame:CGRectMake(labelXOrigin + ([self buttonWidth] * index), labelYOrigin, [self buttonWidth], labelHeight)];
            index += 1;
        }
        
        [[self layer] setFrame:CGRectMake([self frame].origin.x, [self frame].origin.y, [self frameExpanded].size.width, [self frameExpanded].size.height)];
    } else {
        BOOL inside = NO;
        
        NSInteger index = 0;
        for (UILabel *label in [self labels]) {
            if ([label pointInside:[[[event allTouches] anyObject] locationInView:label] withEvent:event]) {
                [label setFrame:CGRectMake(labelXOrigin, labelYOrigin, [self buttonWidth], labelHeight)];
                inside = YES;
                break;
            }
            index += 1;
        }
        
        if (inside) {
            [self setSelectedItem:index];
        }
    }
    [UIView commitAnimations];
}

- (NSInteger)selectedItem
{
    return _selectedItem;
}

- (void)setSelectedItem:(NSInteger)selectedItem
{
    if (selectedItem < [[self labels] count]) {
        CGRect leftShrink = CGRectMake(labelXOrigin, labelYOrigin, 0.f, labelHeight);
        CGRect rightShrink = CGRectMake(labelXOrigin + [self buttonWidth], labelYOrigin, 0.f, labelHeight);
        CGRect middleExpanded = CGRectMake(labelXOrigin, labelYOrigin, [self buttonWidth], labelHeight);
        NSInteger count = 0;    
        BOOL expanded = [self expanded];
        
        if (expanded) {
            [UIView beginAnimations:nil context:NULL];
        }
        
        for (UILabel *label in [self labels]) {
            if (count < selectedItem) {
                [label setFrame:leftShrink];
                [label setFont:[UIFont systemFontOfSize:fontSize]];
            } else if (count > selectedItem) {
                [label setFrame:rightShrink];
                [label setFont:[UIFont systemFontOfSize:fontSize]];
            } else if (count == selectedItem) {
                [label setFrame:middleExpanded];
                [label setFont:[UIFont systemFontOfSize:fontSize]];
                [label setTextColor:[UIColor blackColor]];
            }
            count += 1;
        }
        
        if (expanded) {
            [[self layer] setFrame:CGRectMake([self frame].origin.x, [self frame].origin.y, [self frameShrunk].size.width, [self frameShrunk].size.height)];
            [UIView commitAnimations];
            [self setExpanded:NO];
        }
        
        if (_selectedItem != selectedItem) {
            _selectedItem = selectedItem;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }        
    }
}

- (void)dealloc {
    [self setTitleLabel:nil];
    [self setLabels:nil];
    [super dealloc];
}


@end
