/*
     File: RootViewController.m 
 Abstract: The left side view controller or master view controller.
  
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

#import "RootViewController.h"
#import "DetailViewController.h"

static NSString *textDocName        = @"TextDoc.txt";
static NSString *imageDocName       = @"ImageDoc.jpg";
static NSString *pagesDocName       = @"PagesDoc.pages";
static NSString *spreadsheetDocName = @"SpreadsheetDoc.numbers";
static NSString *keynoteDocName     = @"KeynoteDoc.key";

@implementation RootViewController

@synthesize detailViewController, docURLs, docWatcher;


#pragma mark -
#pragma mark File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
	[self.docURLs removeAllObjects];    // clear out the old docs and start over
	
	NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];

	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator])
	{
		NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
		
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory && [curFileName isEqualToString: @"Inbox"]))
        {
            [self.docURLs addObject:fileURL];
        }
	}
	
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle


- (BOOL)copyMissingFile:(NSString *)sourcePath toPath:(NSString *)destPath
{
	BOOL retVal = YES; // If the file already exists, we'll return success…
    
	NSString* finalLocation = [destPath stringByAppendingPathComponent:[sourcePath lastPathComponent]];
	if (![[NSFileManager defaultManager] fileExistsAtPath:finalLocation])
    {
        retVal = [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:finalLocation error:NULL];
    }
	return retVal;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
  
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
	self.docURLs = [NSMutableArray array];

	BOOL filesPresent = YES;
    
	// check for our existing documents and copy them if necessary
	NSString* docPath = [[NSBundle mainBundle] pathForResource:textDocName ofType: NULL];
	filesPresent|= [self copyMissingFile: docPath toPath: [self applicationDocumentsDirectory]];

	docPath = [[NSBundle mainBundle] pathForResource:imageDocName ofType: NULL];
	filesPresent|= [self copyMissingFile: docPath toPath: [self applicationDocumentsDirectory]];
	
	docPath = [[NSBundle mainBundle] pathForResource:pagesDocName ofType: NULL];
	filesPresent|= [self copyMissingFile: docPath toPath: [self applicationDocumentsDirectory]];
	
	docPath = [[NSBundle mainBundle] pathForResource:spreadsheetDocName ofType: NULL];
	filesPresent|= [self copyMissingFile: docPath toPath: [self applicationDocumentsDirectory]];
	
	docPath = [[NSBundle mainBundle] pathForResource:keynoteDocName ofType: NULL];
	filesPresent|= [self copyMissingFile: docPath toPath: [self applicationDocumentsDirectory]];
	
	//If this fails, one of the expected files did not copy, and does not exist in the expected location.
	assert(filesPresent);
	
	// start monitoring the document directory…
	self.docWatcher = [DirectoryWatcher watchFolderWithPath: [self applicationDocumentsDirectory] delegate: self];
  	// scan for existing documents
	[self directoryDidChange:self.docWatcher];
	
    // set the current document point to first document
    detailViewController.detailItem = [docURLs objectAtIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // in case our detail view has any popover sheets open, dismiss them
    [self.detailViewController dismissAnySheets];

    // select the proper document in the table
    NSInteger rowToSelect = 0;
    NSURL *url;
    for (url in docURLs)
    {
        if (url == detailViewController.detailItem)
        {
            NSIndexPath *selectionIndexPath = [NSIndexPath indexPathForRow:rowToSelect inSection:0];
            [self.tableView selectRowAtIndexPath:selectionIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
            break;
        }
        rowToSelect++;
    }
}


#pragma mark -
#pragma mark UIViewController support

// Ensure that the view controller supports rotation and that the split view can therefore
// show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    // return the number of sections
    return 1;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section
    return [docURLs count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [[[self.docURLs objectAtIndex:indexPath.row] absoluteString] lastPathComponent];
	
    return cell;
}


#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // when a row is selected, set the detail view controller's detail item to the item associated with the selected row
    detailViewController.detailItem = [self.docURLs objectAtIndex:indexPath.row];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    // releases the view if it doesn't have a superview
    [super didReceiveMemoryWarning];
    
    // relinquish ownership any cached data, images, etc. that aren't in use
    //
}

- (void)viewDidUnload
{
    // relinquish ownership of anything that can be recreated in viewDidLoad or on demand
    //
    self.detailViewController = nil;
    self.docURLs = nil;
}

- (void)dealloc
{
    [detailViewController release];
    [docURLs release];
    
    [super dealloc];
}

@end

