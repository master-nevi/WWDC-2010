/*
     File: RemindersAppDelegate.m
 Abstract: Application delegate
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

#import "RemindersAppDelegate.h"
#import "RemindersViewController.h"

@implementation RemindersAppDelegate

@synthesize window;
@synthesize viewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

	application.applicationIconBadgeNumber = 0;

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	application.applicationIconBadgeNumber = 0;
}


- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	NSLog(@"Got local notification %@", notification);
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		// We're active, thus no UI was previously displayed to the user, display our own
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Reminder" message:notification.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
	
	// Developers should consider taking the user to the Reminder detail view.
}

- (void)didEnterRegion:(CLRegion *)region {
	UILocalNotification *note = [[UILocalNotification alloc] init];
	note.alertBody=[NSString stringWithFormat:@"Remember to %@?", region.identifier];
	
	// add the region to the payload so it can optionally be handled with application:didReceiveLocalNotification:
	note.userInfo=[NSDictionary dictionaryWithObject:[NSKeyedArchiver archivedDataWithRootObject:region]
											  forKey:@"region"];
	
	[[UIApplication sharedApplication] presentLocalNotificationNow:note];
	[note release];
}

- (void)didExitRegion:(CLRegion *)region {
	UILocalNotification *note = [[UILocalNotification alloc] init];
	note.alertBody=[NSString stringWithFormat:@"Did you remember to %@?", region.identifier];
	
	// add the region to the payload so it can optionally be handled with application:didReceiveLocalNotification:
	note.userInfo=[NSDictionary dictionaryWithObject:[NSKeyedArchiver archivedDataWithRootObject:region]
											  forKey:@"region"];
	
	[[UIApplication sharedApplication] presentLocalNotificationNow:note];
	[note release];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
