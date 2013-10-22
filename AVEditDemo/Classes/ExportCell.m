
/*
     File: ExportCell.m
 Abstract: UITableViewCell that displays export progress UI. 
 
  Version: 1.1
 
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

#import "ExportCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation ExportCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
		_progressViewHidden = YES;
		_detailTextLabelHidden = NO;
		self.detailTextLabel.textAlignment = UITextAlignmentCenter;
    }
    return self;	
}

- (UIProgressView*)progressView
{
	if(_progressView == nil) {
		_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	}
	return _progressView;
}

- (void)setProgressViewHidden:(BOOL)hidden
{
	[self setProgressViewHidden:hidden animated:NO];
}

- (void)setProgressViewHidden:(BOOL)hidden animated:(BOOL)animated
{
	if (hidden == _progressViewHidden)
		return;
	
	_progressViewHidden = hidden;
	
	UIProgressView *progressView = self.progressView; // Will create one if necessary.
	if (hidden) {
		if (animated) {
			[UIView beginAnimations:nil context:NULL];

			[UIView setAnimationDuration:0.21];
			progressView.alpha = 0.0;
			
			if (!_detailTextLabelHidden) {
				[UIView setAnimationDelay:1.0];
				[UIView setAnimationDuration:1.0];
				self.detailTextLabel.alpha = 1.0;
			}
			[UIView commitAnimations];
		}
		else {
			progressView.alpha = 0.0;
			if (!_detailTextLabelHidden) {
				self.detailTextLabel.alpha = 1.0;
			}
		}
	}
	else {
		if (progressView.superview == nil) {
			BOOL animationsEnabled = [UIView areAnimationsEnabled];
			if (animationsEnabled)
				[UIView setAnimationsEnabled:NO];

			[self.contentView addSubview:progressView];
			[self layoutSubviews];
			
			if (animationsEnabled)
				[UIView setAnimationsEnabled:YES];
		}
		
		if (animated) {
			progressView.alpha = 0.0;
			[UIView beginAnimations:nil context:NULL];
			
			[UIView setAnimationDuration:0.20];
			self.detailTextLabel.alpha = 0.0;
			
			[UIView setAnimationDelay:0.20];
			[UIView setAnimationDuration:0.25];
			progressView.alpha = 1.0;
			
			[UIView commitAnimations];
		}
		else {
			progressView.alpha = 1.0;
			self.detailTextLabel.alpha = 0.0;
		}
	}
	[self setNeedsLayout];
}

- (void)setDetailTextLabelHidden:(BOOL)hidden
{
	[self setDetailTextLabelHidden:hidden animated:NO];
}

- (void)setDetailTextLabelHidden:(BOOL)hidden animated:(BOOL)animated
{
	if (hidden == _detailTextLabelHidden)
		return;
	
	if ( (hidden == NO) && (_progressViewHidden == NO) )
		return;
	
	_detailTextLabelHidden = hidden;
	
	if (hidden) {
		if (animated) {
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.25];
			self.detailTextLabel.alpha = 0.0;			
			[UIView commitAnimations];
		}
		else {
			self.detailTextLabel.alpha = 0.0;
		}
	}
	else {
		if (animated) {
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.25];
			self.detailTextLabel.alpha = 1.0;
			[UIView commitAnimations];
		}
		else {
			self.detailTextLabel.alpha = 1.0;
		}
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect mainTextFrame = self.textLabel.frame;
	CGRect contentViewFrame = self.contentView.frame;
	
	if ( _progressView ) 
	{
		CGRect progressFrame;
		progressFrame.size.height = _progressView.frame.size.height;	
		progressFrame.origin.x = CGRectGetMaxX(mainTextFrame) - 4.0;
		progressFrame.origin.y = ceilf(CGRectGetMidY(self.contentView.bounds) - progressFrame.size.height/2.0);
		progressFrame.size.width = contentViewFrame.size.width - progressFrame.origin.x;
		progressFrame = CGRectInset(progressFrame, 20.0, 0.0);
		_progressView.frame = progressFrame;
	}
	
	CGRect detailTextFrame = self.detailTextLabel.frame;
	detailTextFrame.origin.x = CGRectGetMaxX(mainTextFrame) - 8.0;
	detailTextFrame.size.width = contentViewFrame.size.width - detailTextFrame.origin.x;
	self.detailTextLabel.frame = detailTextFrame;
}

- (void)dealloc {
	[_progressView release];
	
    [super dealloc];
}


@end
