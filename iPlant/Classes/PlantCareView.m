//
// File:       PlantCareView.m
//
// Abstract:   This UIView subclass takes care of showing most of our animatable UI
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

#import "PlantAppDelegate.h"
#import "PlantCareView.h"
#import "RoboGardener.h"


@implementation PlantCareView

/*  
 Called when a vegetable button is pressed.
 */
- (void)setSelectedVeg:(id)sender
{    
    [selectedVegetableIcon setAlpha:0.0];
    
    [UIView animateWithDuration:0.4
                     animations: ^{
                         float angle = [self spinnerAngleForVegetable:sender];
                         [vegetableSpinner setTransform:CGAffineTransformMakeRotation(angle)];
                     } 
                     completion:^(BOOL finished) {
                         [selectedVegetableIcon setAlpha:1.0];
                     }];
}

/*
 Tell the robot to water the selected plant.
 */
- (void)startWateringProcedure:(id)sender
{
    RoboGardener *robot = [[[RoboGardener alloc] init] autorelease];
    [robot waterPlant];
    
    [UIView animateWithDuration:0.4
                     animations: ^{
                         [volumeLabel setAlpha:0.0];
                     } 
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.6
                                          animations: ^{
                                              float newWaterLevel = [robot waterLevel];
                                              
                                              [volumeLabel setText:[NSString stringWithFormat:@"%0.f%%",newWaterLevel]];
                                              [volumeLabel setAlpha:1.0];
                                              [waterView setFrame:RectForWaterWithLevel(newWaterLevel)]; 
                                          }];
                     }];
}

/*
 Create and setup all the buttons
 */
- (void)setupVegetableButtons
{
    carrotButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(vegetableSpinner.frame)/2.0 - 37, 0, 74, 74)];
    [self assembleVegetableButton:carrotButton];
    
    radishButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(vegetableSpinner.frame)/2.0 - 37, 74, 74)];
    [self assembleVegetableButton:radishButton];
    
    onionButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(vegetableSpinner.frame)/2.0 - 37, CGRectGetHeight(vegetableSpinner.frame) - 74, 74, 74)];
    [self assembleVegetableButton:onionButton];
    
    sproutButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(vegetableSpinner.frame) - 74, CGRectGetHeight(vegetableSpinner.frame)/2.0 - 37, 74, 74)];
    [self assembleVegetableButton:sproutButton];
}

/*
 Factory to create a given button
 */
- (void)assembleVegetableButton:(UIButton *)button
{
    button.transform = CGAffineTransformMakeRotation(-[self spinnerAngleForVegetable:button]);
    [button setImage:[self imageForVeg:button] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(setSelectedVeg:) forControlEvents:UIControlEventTouchUpInside];
    [button setShowsTouchWhenHighlighted:YES];
    [vegetableSpinner addSubview:button];
}

/*
 Returns the unselected icon of a given vegetable
 */
- (UIImage *)selectedImageForVeg:(id)sender
{
    if (sender == carrotButton) {
        return [UIImage imageNamed:@"carrot.png"];
    } else if (sender == radishButton) {
        return [UIImage imageNamed:@"radish.png"];
    } else if (sender == onionButton) {
        return [UIImage imageNamed:@"onion.png"];
    } else if (sender == sproutButton) {
        return [UIImage imageNamed:@"sprout.png"];
    }
    return nil;
}

/*
 Returns the selected icon of a given vegetable 
 */
- (UIImage *)imageForVeg:(UIButton *)button
{
    if (button == carrotButton) {
        return [UIImage imageNamed:@"ucarrot.png"];
    } else if (button == radishButton) {
        return [UIImage imageNamed:@"uradish.png"];
    } else if (button == onionButton) {
        return [UIImage imageNamed:@"uonion.png"];
    } else if (button == sproutButton) {
        return [UIImage imageNamed:@"usprout.png"];
    }
    return nil;
}

/*
 Returns the angle for a given selected vegetable
 */
- (float)spinnerAngleForVegetable:(id)sender
{
    selectedVegetableIcon.image = [self selectedImageForVeg:sender];
    
    float angle = 0.0;
    if (sender == carrotButton) {
        angle = 0.0;
    } else if (sender == radishButton) {
        angle = 90.0;
    } else if (sender == onionButton) {
        angle = 180.0;
    } else if (sender == sproutButton) {
        angle = -90.0;
    }
    return radians(angle);
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
        
        self.clipsToBounds = YES;
        
        vegetableSpinner = [[UIView alloc] initWithFrame:CGRectMake(28, 167, 259, 259)];
        [vegetableSpinner setBackgroundColor:[UIColor clearColor]];
        
        UIImageView *waterBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lcd.png"]];
        [self addSubview:waterBackground];
        [waterBackground release];
        
        waterView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"water.png"]];
        [waterView setFrame:RectForWaterWithLevel(100)];
        [self addSubview:waterView];
        
        volumeLabel = [self newWaterLabel];
        [self addSubview:volumeLabel];
        
        UIImageView *foreground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flat.png"]];
        [self addSubview:foreground];
        [foreground release];
        
        [self setupVegetableButtons];
        
        [self addSubview:vegetableSpinner];
        
        UIImageView *cover = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WheelCover.png"]];
        [self addSubview:cover];
        [cover release];
        
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoButton setFrame:CGRectMake(280, 420, 40, 40)];
        [infoButton addTarget:(PlantAppDelegate *)[[UIApplication sharedApplication] delegate] action:@selector(showBack:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:infoButton];
        
        selectedVegetableIcon = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(vegetableSpinner.frame) + (CGRectGetWidth(vegetableSpinner.frame)/2.0 - 37), CGRectGetMinY(vegetableSpinner.frame), 74, 74)];
        [selectedVegetableIcon setImage:[UIImage imageNamed:@"carrot.png"]];
        [self addSubview:selectedVegetableIcon];
        
        UIButton *waterPlantButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [waterPlantButton setImage:[UIImage imageNamed:@"drips.png"] forState:UIControlStateNormal];
        [waterPlantButton setFrame:CGRectMake(CGRectGetWidth(frame)/2.0 - 85.0/2.0 - 2,CGRectGetHeight(frame)/2.0 - 85.0/2.0 + 70,85,85)];
        [waterPlantButton addTarget:self action:@selector(startWateringProcedure:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:waterPlantButton];
    }
    return self;
}

/*
 Create and setup the water label
 */
- (UILabel *)newWaterLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, 280, 135)];
    [label setText:@"100%"];
    [label setFont:[UIFont fontWithName:@"Helvetica" size:50]];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    return label;
}

- (void)dealloc 
{    
    [waterView release];
    [selectedVegetableIcon release];
    [volumeLabel release];
    [carrotButton release];
    [radishButton release];
    [onionButton release];
    [sproutButton release];
    [vegetableSpinner release];
    
    [super dealloc];
}


@end

/*
 Returns a rect for the waters frame at a given level
 */
CGRect RectForWaterWithLevel(float level)
{
    return CGRectMake(17, 10 + (140 * ((100 - level)/100.0)), 285, 140 * (level/100.0));
}
