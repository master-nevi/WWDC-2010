//
// File:       AlbumContentsViewController.m
//
// Abstract:   View controller to manaage displaying the contents of an album.
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

#import "AlbumContentsViewController.h"

#import "AlbumContentsTableViewCell.h"
#import "PhotoDisplayViewController.h"

@implementation AlbumContentsViewController

@synthesize assetsGroup;
@synthesize tmpCell;


- (void)awakeFromNib {
    lastSelectedRow = NSNotFound;
}


#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    if (!assets) {
        assets = [[NSMutableArray alloc] init];
    } else {
        [assets removeAllObjects];
    }
    
    ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if (result) {
            [assets addObject:result];
        }
    };

    ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
    [assetsGroup setAssetsFilter:onlyPhotosFilter];
    [assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
    
}

- (void)viewDidAppear:(BOOL)animated {
    if (lastSelectedRow != NSNotFound) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:lastSelectedRow inSection:0];
        AlbumContentsTableViewCell *selectedCell = (AlbumContentsTableViewCell *)[(UITableView *)self.view cellForRowAtIndexPath:selectedIndexPath];
        [selectedCell clearSelection];
        
        lastSelectedRow = NSNotFound;
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return ceil((float)assets.count / 4); // there are four photos per row.
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    AlbumContentsTableViewCell *cell = (AlbumContentsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"AlbumContentsTableViewCell" owner:self options:nil];
        cell = tmpCell;
        tmpCell = nil;
    }
    
    cell.rowNumber = indexPath.row;
    cell.selectionDelegate = self;
    
    // Configure the cell...
    NSUInteger firstPhotoInCell = indexPath.row * 4;
    NSUInteger lastPhotoInCell  = firstPhotoInCell + 4;
    
    if (assets.count <= firstPhotoInCell) {
        NSLog(@"We are out of range, asking to start with photo %d but we only have %d", firstPhotoInCell, assets.count);
        return nil;
    }
    
    NSUInteger currentPhotoIndex = 0;
    NSUInteger lastPhotoIndex = MIN(lastPhotoInCell, assets.count);
    for (firstPhotoInCell ; firstPhotoInCell + currentPhotoIndex < lastPhotoIndex ; currentPhotoIndex++) {
        
        ALAsset *asset = [assets objectAtIndex:firstPhotoInCell + currentPhotoIndex];
        CGImageRef thumbnailImageRef = [asset thumbnail];
        UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
        
        switch (currentPhotoIndex) {
            case 0:
                [cell photo1].image = thumbnail;
                break;
            case 1:
                [cell photo2].image = thumbnail;
                break;
            case 2:
                [cell photo3].image = thumbnail;
                break;
            case 3:
                [cell photo4].image = thumbnail;
                break;
            default:
                break;
        }
    }
    
    return cell;
}


#pragma mark -
#pragma mark AlbumContentsTableViewCellSelectionDelegate

- (void)albumContentsTableViewCell:(AlbumContentsTableViewCell *)cell selectedPhotoAtIndex:(NSUInteger)index {
    
    PhotoDisplayViewController *photoViewController = [[PhotoDisplayViewController alloc] initWithNibName:@"PhotoDisplayViewController" bundle:nil];
    
    lastSelectedRow = cell.rowNumber;
    
    [photoViewController setAsset:[assets objectAtIndex:(cell.rowNumber * 4) + index]];
    [[self navigationController] pushViewController:photoViewController animated:YES];
    [photoViewController release];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    self.assetsGroup = nil;
    [assets release];
    
    [super dealloc];
}

@end

