//     File: GCConfig.m
// Abstract: A simple wrapper around NSDictionary to carry command information
//  Version: 1.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2010 Apple Inc. All Rights Reserved.
// 

#import "GCConfig.h"

@implementation GCConfig
@synthesize config;
@synthesize commands;

static GCConfig *sharedInstance = nil;

+ (GCConfig *)sharedConfig
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[GCConfig alloc] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"%@ is undefined", key);
}

- (id)valueForKey:(id)key
{
	return [config valueForKey: key];
}

- (void)setValue:(id)value forCommand:(NSString *)command
{
	if (value && command && command.length) {
		NSDictionary *callback = (NSDictionary *)[commands objectForKey: command];
		
		if (callback && value) {
			id observer = [callback objectForKey: @"observer"];
			NSString *method = (NSString *)[callback objectForKey: @"method"];
			SEL selector = NSSelectorFromString(method);
			if (selector && observer) {
				[observer performSelector: selector
							   withObject: value];
			}
		}
		
		[config setObject: value
				   forKey: command];
		
	}
}

- (void)addObserver:(NSObject *)observer forCommand:(NSString *)command withCallback:(id)method
{
	if (command && command.length && method) {
		NSDictionary *callback = [NSDictionary dictionaryWithObjectsAndKeys: observer, @"observer", method, @"method", nil];
		[self.commands setObject: callback
						  forKey: command];
	}
}

- (id)init
{
	[self setConfig: [NSMutableDictionary dictionaryWithCapacity: 10]];
	[self setCommands: [NSMutableDictionary dictionaryWithCapacity: 10]];

	return [super init];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

- (void)dealloc {
	[config release];
	
	[super dealloc];
}

@end
