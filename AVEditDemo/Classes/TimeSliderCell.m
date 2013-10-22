
/*
     File: TimeSliderCell.m
 Abstract: Table view cell to display a time slider with a label. 
 
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

#import "TimeSliderCell.h"



@interface LimitedSlider : UISlider
{
	float _largestValue;
	float _smallestValue;
}

// The largest and smallest values the slider knob is limited to.
@property (nonatomic) float smallestValue;
@property (nonatomic) float largestValue;

@end

@implementation LimitedSlider

- (id)initWithFrame:(CGRect)frame
{
	_smallestValue = 0.0;
	_largestValue = 1.0;
	
	self = [super initWithFrame:frame];
	return self;
}

- (float)smallestValue
{
	return _smallestValue;
}

- (void)setSmallestValue:(float)minValue
{
	_smallestValue = minValue;
	if (self.value < _smallestValue) {
		self.value = _smallestValue;
	}	
}

- (float)largestValue
{
	return _largestValue;
}

- (void)setLargestValue:(float)maxValue
{
	_largestValue = maxValue;
	if (self.value > maxValue) {
		self.value = maxValue;
	}
}

- (void)setValue:(float)value
{
	if ((value > _largestValue)) {
		[super setValue:_largestValue];
	}
	else if (value < _smallestValue) {
		[super setValue:_smallestValue];
	}
	else {
		[super setValue:value];
	}
}

- (void)setValue:(float)value animated:(BOOL)animated
{
	if ((value > _largestValue)) {
		[super setValue:_largestValue animated:animated];
	}
	else if (value < _smallestValue) {
		[super setValue:_smallestValue animated:animated];
	}
	else {
		[super setValue:value animated:animated];
	}
}

@end


@interface TimeSliderCell ()
@property (nonatomic, retain) LimitedSlider *slider;
@end


@implementation TimeSliderCell

@synthesize slider = _slider;
@synthesize sliderXInset = _sliderXInset;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization

- (id)initWithReuseIdentifier:(NSString *)identifier
{	
	if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier]) 
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		self.slider = [[[LimitedSlider alloc] initWithFrame:CGRectZero] autorelease];
		[self.slider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
		self.sliderXInset = 60.0;
		
		[self.contentView addSubview:self.slider];
	}
	
	return self;
}

- (BOOL)flipSlider
{
	return _flipSlider;
}

- (void)setFlipSlider:(BOOL)flip
{
	if (flip != _flipSlider) {
		_flipSlider = flip;
		CGAffineTransform transform = flip ? CGAffineTransformMakeScale(-1.0, 1.0) : CGAffineTransformIdentity;
		self.slider.transform = transform;
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGSize contentSize = self.contentView.bounds.size;
	CGSize sizeToFitIn = CGRectInset(self.contentView.bounds, self.sliderXInset, 0.0).size;
	
	CGRect sliderRect = CGRectZero;
	sliderRect.size = [self.slider sizeThatFits:sizeToFitIn];

	sliderRect.origin.x = 0.5*(contentSize.width - sliderRect.size.width);
	sliderRect.origin.x = roundf(sliderRect.origin.x);	
	
	sliderRect.origin.y = 0.5*(contentSize.height - sliderRect.size.height);
	sliderRect.origin.y = roundf(sliderRect.origin.y);
	self.slider.frame = sliderRect;
}

- (void)updateTimeLabel
{
	float timeInSeconds = [self timeValue];
	
	if (timeInSeconds < 60.0) {
		self.detailTextLabel.text = [NSString stringWithFormat:@"%.1fs", [self timeValue]];
	}
	else {
		self.detailTextLabel.text = [NSString stringWithFormat:@"%.1fm", timeInSeconds/60.0];
	}
}

- (void)sliderValueChanged
{
	[self updateTimeLabel];
	if (self.delegate) {
		[self.delegate sliderCellTimeValueDidChange:self];
	}
}

- (float)duration
{
	return _duration;
}

- (void)setDuration:(float)duration
{
	if (_duration != duration) {
		_duration = duration;
		[self updateTimeLabel];
	}
}

- (float)timeValue
{
	float sliderValue = self.slider.value;
	if (_flipSlider) {
		sliderValue = 1.0 - sliderValue;
	}
	return _duration*sliderValue;
}

- (void)setTimeValue:(float)value
{
	float sliderValue = value/_duration;
	if (_flipSlider) {
		sliderValue = 1.0 - sliderValue;
	}
	self.slider.value = sliderValue;
	[self updateTimeLabel];
}

- (float)minimumTime
{
	float minValue; 
	if (_flipSlider) {
		minValue = 1.0 - [self.slider largestValue];
	}
	else {
		minValue = [self.slider smallestValue];
	}
	return minValue*_duration;
}

- (void)setMinimumTime:(float)minTime
{
	float normalizedMinTime = minTime/_duration;
	if (_flipSlider) {
		normalizedMinTime = 1.0 - normalizedMinTime;
		[self.slider setLargestValue:normalizedMinTime];
	}
	else {
		[self.slider setSmallestValue:normalizedMinTime];
	}
	[self updateTimeLabel];
}

- (float)maximumTime
{
	float maxValue = [self.slider largestValue];
	if (_flipSlider) {
		maxValue = 1.0 - maxValue;
	}
	
	return maxValue*_duration;
}

- (void)setMaximumTime:(float)maxTime
{
	float normalizedMaxTime = maxTime/_duration;
	if (_flipSlider) {
		normalizedMaxTime = 1.0 - normalizedMaxTime;
		[self.slider setSmallestValue:normalizedMaxTime];
	}
	else {
		[self.slider setLargestValue:normalizedMaxTime];
	}
	[self updateTimeLabel];
}

- (void)dealloc 
{
	self.slider = nil;
	[super dealloc];
}

@end
