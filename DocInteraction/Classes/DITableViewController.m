/* 
     File: DITableViewController.m
 Abstract: The table view that display docs of different types.
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

#import "DITableViewController.h"
#import "DITableViewCell.h"

#define NUM_DOCS 4
#define ROW_HEIGHT 80

static NSString* documents[] = {@"Text Document", @"Image Document", @"PDF Document", @"HTML Document"};
static NSString* documentExtensions[] = {@"txt", @"jpg", @"pdf", @"html"};

@implementation DITableViewController

-(id)initWithStyle:(UITableViewStyle)style
{
    if ((self = [super initWithStyle:style])) {
        rowInfo = malloc(sizeof(RowInfo) * NUM_DOCS);
        for (int i = 0; i < NUM_DOCS; i++) {
            rowInfo[i].documentRead = NO;
        }
    }
    
    return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_DOCS;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"regularCell";
    DITableViewCell* cell = (DITableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[[DITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
    }
    
    NSInteger section = indexPath.section;
    [cell setDocumentName:documents[section] extension:documentExtensions[section] index:section tableViewController:self];
    cell.documentRead = rowInfo[indexPath.section].documentRead;
    
    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return ROW_HEIGHT;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // three ways to present a preview:
    // 1. don't implement this method and simply attach the canned gestureRecognizers to the cell
    // 2. don't use canned gesture recognizers and simply call presentPreviewAnimated: to get a preview for the document associated with this cell
    // 3. use the QLPreviewController to give the user preview access to the document associated with this cell and the documents for other cells also
    
    //[((DITableViewCell*)[tableView cellForRowAtIndexPath:indexPath]).docInteractionController presentPreviewAnimated:YES];
    
    QLPreviewController* previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    previewController.delegate = self;
    previewController.currentPreviewItemIndex = indexPath.section;
    [self presentModalViewController:previewController animated:YES];
    [previewController release];
}

-(void)setDocumentRead:(NSInteger)documentIndex
{
    rowInfo[documentIndex].documentRead = YES;
}

-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController*)previewController
{
    return NUM_DOCS;
}

-(id)previewController:(QLPreviewController*)previewController previewItemAtIndex:(NSInteger)index
{
    NSString* filePath = [[NSBundle mainBundle] pathForResource:documents[index] ofType:documentExtensions[index]];
    NSURL* url = nil;
    if (filePath) {
        //set our tableView cells as read when we display their preview items
        rowInfo[index].documentRead = YES;
        [(DITableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]] setDocumentRead:YES];
        url = [NSURL fileURLWithPath:filePath];
    }
    
    return url;
}

@end
