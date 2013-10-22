//
// File:       PlantAppDelegate.m
//
// Abstract:   Our UIApplication subclass is where we'll swap views in our transition animations.
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
#import "PlantViewController.h"
#import "PlantCareView.h"

@implementation PlantAppDelegate

@synthesize window;
@synthesize viewController;

/*
 Show the back of the app
 */
- (void)showBack:(id)sender
{        
    [UIView transitionFromView:plantFrontView
                        toView:plantBackView
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    completion:nil];
}

/*
 Show the front of the app
 */
- (void)showFront:(id)sender
{       
    // Remember: In your apps use the transitionFromView:toView: API symmetrically. The below use of the transitionWithView: API is simply illustrative.
    
    [plantBackView removeFromSuperview];
    [viewController.view addSubview:plantFrontView];
    
    [UIView transitionWithView:viewController.view
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{} 
                    completion:nil];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    [[UIApplication sharedApplication] setDelegate:self];
    
    [self setupBackView];
    plantFrontView = [[PlantCareView alloc] initWithFrame:viewController.view.bounds];
    [viewController.view addSubview:plantFrontView];
    
    // Set this so that the background of the transition is black 
    [window setBackgroundColor:[UIColor blackColor]]; 
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)setupBackView
{
    UIColor *backgroundColor = [UIColor lightGrayColor];
    CGRect bounds = viewController.view.bounds;
    
    plantBackView = [[UIView alloc] initWithFrame:bounds];
    [plantBackView setBackgroundColor:backgroundColor];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [doneButton setFrame:CGRectMake(20, 20, 100, 45)];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(showFront:) forControlEvents:UIControlEventTouchUpInside];
    [plantBackView addSubview:doneButton];
    
    UILabel *infoLabel = [[[UILabel alloc] init] autorelease];
    [infoLabel setBounds:CGRectMake(0, 0, 320, 320)];
    [infoLabel setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [infoLabel setText:@"iPlant, WWDC 2010"];
    [infoLabel setFont:[UIFont fontWithName:@"Helvetica" size:25]];
    [infoLabel setTextAlignment:UITextAlignmentCenter];
    [infoLabel setBackgroundColor:backgroundColor];
    
    [plantBackView addSubview:infoLabel];
}

- (void)dealloc 
{
    [plantFrontView release];
    [plantBackView release];
    [viewController release];
    [window release];
    [super dealloc];
}

@end
