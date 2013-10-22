//
// File:       AlbumContentsTableViewCell.m
//
// Abstract:   Table view cell that displays four photo thumbnails in a row.
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

#import "AlbumContentsTableViewCell.h"
#import "ThumbnailImageView.h"

@implementation AlbumContentsTableViewCell

@synthesize rowNumber;
@synthesize selectionDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


- (void)awakeFromNib {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    photo1.delegate = self;
    photo2.delegate = self;
    photo3.delegate = self;
    photo4.delegate = self;
}

- (UIImageView *)photo1 {
    return photo1;
}

- (UIImageView *)photo2 {
    return photo2;
}

- (UIImageView *)photo3 {
    return photo3;
}

- (UIImageView *)photo4 {
    return photo4;
}

- (void)clearSelection {
    [photo1 clearSelection];
    [photo2 clearSelection];
    [photo3 clearSelection];
    [photo4 clearSelection];
}

- (void)thumbnailImageViewWasSelected:(ThumbnailImageView *)thumbnailImageView {
    NSUInteger selectedPhotoIndex = 0;
    if (thumbnailImageView == photo1) {
        selectedPhotoIndex = 0;
    } else if (thumbnailImageView == photo2) {
        selectedPhotoIndex = 1;
    } else if (thumbnailImageView == photo3) {
        selectedPhotoIndex = 2;
    } else if (thumbnailImageView == photo4) {
        selectedPhotoIndex = 3;
    }
    [selectionDelegate albumContentsTableViewCell:self selectedPhotoAtIndex:selectedPhotoIndex];
}

@end
