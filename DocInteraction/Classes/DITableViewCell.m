/* 
     File: DITableViewCell.m
 Abstract: The table view cell that handles the document interactions.
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

#import "DITableViewCell.h"
#import "DITableViewController.h"

@implementation DITableViewCell

@synthesize docInteractionController;

-(void)setDocumentName:(NSString*)document extension:(NSString*)extension index:(NSInteger)index tableViewController:(DITableViewController*)tableController
{
    //release everything to make sure we're at a clean state
    [docInteractionController release];
    docInteractionController = nil;
    [tableViewController release];
    tableViewController = nil;
    self.gestureRecognizers = nil;
    self.textLabel.text = @"";
    documentIndex = index;
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:document ofType:extension];
    if (filePath) {
        //setup the documentInteractionController
        NSURL* docURL = [[NSURL alloc] initFileURLWithPath:filePath];
        tableViewController = [tableController retain];
        docInteractionController = [[UIDocumentInteractionController alloc] init];
        docInteractionController.URL = docURL;
        NSString* UTI = docInteractionController.UTI;
        docInteractionController.name = @"MyDoc";
        docInteractionController.UTI = UTI;
        docInteractionController.delegate = self;
        [docURL release];
        
        //easy functionality by just attaching the canned gesture recognizers to the view
        //self.gestureRecognizers = docInteractionController.gestureRecognizers;
        
        //layout the cell
        self.textLabel.text = document;
        NSInteger iconCount = [docInteractionController.icons count];
        if (iconCount > 0) {
            self.imageView.image = [docInteractionController.icons objectAtIndex:iconCount - 1];
        }
        
        //custom gesture recognizer in lieu of using the canned ones
        UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.imageView addGestureRecognizer:longPressGesture];
        self.imageView.userInteractionEnabled = YES;
        [longPressGesture release];
    }
}

-(UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)interactionController
{
    return tableViewController;
}

-(UIView*)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)interactionController
{
    return self;
}

-(CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)interactionController
{
    return CGRectIsEmpty(self.imageView.frame) ? self.bounds : [self convertRect:self.imageView.frame fromView:self.imageView];
}

-(void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)interactionController
{
    self.documentRead = YES;
    [tableViewController setDocumentRead:documentIndex];
}

-(void)documentInteractionController:(UIDocumentInteractionController*)interactionController didEndSendingToApplication:(NSString*)application
{
    self.documentRead = YES;
    [tableViewController setDocumentRead:documentIndex];
}

-(BOOL)documentRead
{
    return documentRead;
}

-(void)setDocumentRead:(BOOL)read
{
    documentRead = read;
    self.accessoryType = documentRead ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)longPressGesture
{
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        [docInteractionController presentOptionsMenuFromRect:self.bounds inView:self animated:YES];
    }
}

@end
