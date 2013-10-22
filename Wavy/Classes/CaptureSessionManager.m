/*
    File: CaptureSessionManager.m
Abstract: Configuration and control of audio capture.
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


#import "CaptureSessionManager.h"


#define SINT16_MAX 32767.0


// Category on AVCaptureOutput for getting connections
@interface AVCaptureOutput (AVCaptureOutputUtilities)
- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType;
@end

@implementation AVCaptureOutput (AVCaptureOutputUtilities)

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType {

	for ( AVCaptureConnection *connection in self.connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return [[connection retain] autorelease];
			}
		}
	}

	return nil;
}

@end


@implementation CaptureSessionManager

@synthesize currentAudioLevel;
@synthesize audioMultiplier;
@synthesize lastAudioSample;
@synthesize audioDisplayDelegate;
@synthesize captureSession;


- (BOOL)isRunning {
	return captureSession.isRunning;
}


- (void)stopSession {
	[captureSession stopRunning];
}


- (void)startSession {
	[captureSession startRunning];
}


// Returns array member with greatest absolute value
- (SInt16) maxValueInArray: (SInt16[]) values ofSize: (unsigned int) size {

	SInt16 max = 0;

	for (int i = 0; i < size; i++)
		if (abs(values[i]) > max)
			max = values[i];
	
	return max;
}

- (void) displayAudioDataInSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	
	CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
	NSUInteger channelIndex = 0;

	CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
	size_t audioBlockBufferOffset = (channelIndex * numSamples * sizeof(SInt16));
	size_t lengthAtOffset = 0;
	size_t totalLength = 0;
	SInt16 *samples = NULL;
	CMBlockBufferGetDataPointer(audioBlockBuffer, audioBlockBufferOffset, &lengthAtOffset, &totalLength, (char **)(&samples));
	
	int numSamplesToRead = 1;
	for (int i = 0; i < numSamplesToRead; i++) {
				
		SInt16 subSet[numSamples / numSamplesToRead];
		for (int j = 0; j < numSamples / numSamplesToRead; j++)
			 subSet[j] = samples[(i * (numSamples / numSamplesToRead)) + j];

		self.lastAudioSample = [self maxValueInArray: subSet ofSize: numSamples / numSamplesToRead];
		
		double scaledSample = (double) ((self.lastAudioSample / SINT16_MAX));

		[audioDisplayDelegate addX:scaledSample];
	}
}


#pragma mark SampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
		[self displayAudioDataInSampleBuffer:sampleBuffer];
}


#pragma mark Capture Session

- (void) addAudioInput {
	
	AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	if	(audioDevice) {
		
		NSError *error;
		AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		if ( !error ) {
			if ([self.captureSession canAddInput:audioIn])
				[self.captureSession addInput:audioIn];
			else
				NSLog(@"Couldn't add audio input");		
		}
		else
			NSLog(@"Couldn't create audio input");
	}
	else
		NSLog(@"Couldn't create audio capture device");
}


- (void) addAudioDataOutput {
	
	AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
	[audioOut setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	if ([self.captureSession canAddOutput:audioOut]) {
		[self.captureSession addOutput:audioOut];
		audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
	}
	else
		NSLog(@"Couldn't add audio output");
	[audioOut release];
}


- (id) init {
	
	if (self = [super init])
		self.captureSession = [[AVCaptureSession alloc] init];
	
	return self;
}


- (void)dealloc {

	[self.captureSession stopRunning];
	[self.captureSession release];

	[super dealloc];
}

@end
