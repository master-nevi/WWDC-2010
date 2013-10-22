/*
    File: CaptureSessionManager.m
Abstract: Configuration and control of video capture.
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


#define BYTES_PER_PIXEL 4
#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 460


static const uint8_t orangeColor[] = {255, 127, 0};


@implementation CaptureSessionManager

@synthesize captureSession;
@synthesize previewLayer;
@synthesize recognizedRect;
@synthesize foundColor;
@synthesize matchThreshold;
@synthesize numMatches;
@synthesize matchesForRecognition;
@dynamic colorReferencePoint;


#pragma mark Accessors

- (CGPoint)colorReferencePoint {
	return colorReferencePoint;
}


- (void)setColorReferencePoint:(CGPoint) newValue {
	colorReferencePoint = newValue;
	shouldGetReferenceColor = YES;
}


#pragma mark Pixelbuffer Processing


// Remove luminance
static inline void normalize( const uint8_t colorIn[], uint8_t colorOut[] ) {

	// Dot product
	int sum = 0;
	for (int i = 0; i < 3; i++)
		sum += colorIn[i] / 3;

	for (int j = 0; j < 3; j++)
		colorOut[j] = (float) ((colorIn[j] / (float) sum) * 255);
}


// Euclidean distance
static inline int distance(uint8_t a[], uint8_t b[], int length) {

	int sum = 0;

	for (int i = 0; i < length; i++)
		sum += (a[i] - b[i]) * (a[i] - b[i]);
	
	return sqrt(sum);
}


static inline BOOL match(uint8_t pixelColor[], uint8_t referenceColor[], unsigned int threshold) {

	return (distance(pixelColor, referenceColor, 3) > threshold) ? NO : YES;
}


- (void)processPixelBuffer: (CVImageBufferRef)pixelBuffer {
	
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	
	int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
	unsigned char *rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
	int64_t accumX = 0, accumY = 0, accumTotal = 0;

	for( int row = 0; row < bufferHeight; row += 8 ) {
		for( int column = 0; column < bufferWidth; column += 8 ) {
			
			unsigned char *pixel = rowBase + (row * bytesPerRow) + (column * BYTES_PER_PIXEL);
			
			uint8_t pixelColor[3];
			normalize(pixel, pixelColor);

			if (shouldGetReferenceColor) {

				// Buffer and display have differing size and orientation
				float normalBufferX = column / (float) bufferWidth;
				float normalBufferY = row / (float) bufferHeight;
				float normalDisplayX = 1.0 - self.colorReferencePoint.x / SCREEN_WIDTH;
				float normalDisplayY =       self.colorReferencePoint.y / SCREEN_HEIGHT;
				float epsilon = 0.025;
				if (fabs(normalDisplayX - normalBufferY) < epsilon && 
					fabs(normalDisplayY - normalBufferX) < epsilon) {

//					unsigned char *pixelBefore = pixel - BYTES_PER_PIXEL;
//					unsigned char *pixelAfter = pixel - BYTES_PER_PIXEL;
					normalize(pixel, referenceColor);
					shouldGetReferenceColor = NO;
					NSLog(@"new r = %d, g = %d, b = %d", pixel[0], pixel[1], pixel[2]);
				}
			}
			
			if (match(pixelColor, referenceColor, matchThreshold)) {
				accumX += column;
				accumY += row;
				accumTotal++;		
			}
		}
	}
	
	self.numMatches = accumTotal;

	foundColor = (accumTotal > self.matchesForRecognition) ? YES : NO;

	// Calculate average x and y for use as recognition rectangle's center
	int centerX = accumX / accumTotal;
	int centerY = accumY / accumTotal;

	CGRect rect = self.recognizedRect;
	rect.origin.x  = SCREEN_WIDTH - ((centerY / (float) bufferHeight) * SCREEN_WIDTH) - rect.size.width / 2;
	rect.origin.y  =                ((centerX / (float) bufferWidth) * SCREEN_HEIGHT) - rect.size.height / 2;
	self.recognizedRect = rect;

	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}


#pragma mark SampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
	
	[self processPixelBuffer:pixelBuffer];
}


#pragma mark Capture Session Configuration

- (void) addVideoPreviewLayer {
	self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}


- (void) addVideoInput {
	
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];	
	if ( videoDevice ) {

		NSError *error;
		AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if ( !error ) {
			if ([self.captureSession canAddInput:videoIn])
				[self.captureSession addInput:videoIn];
			else
				NSLog(@"Couldn't add video input");		
		}
		else
			NSLog(@"Couldn't create video input");
	}
	else
		NSLog(@"Couldn't create video capture device");
}


- (void) addVideoDataOutput {
	
	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
	[videoOut setAlwaysDiscardsLateVideoFrames:YES];
	[videoOut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // BGRA is necessary for manual preview
	dispatch_queue_t my_queue = dispatch_queue_create("com.example.subsystem.taskXYZ", NULL);
	[videoOut setSampleBufferDelegate:self queue:my_queue];
//	[videoOut setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	if ([self.captureSession canAddOutput:videoOut])
		[self.captureSession addOutput:videoOut];
	else
		NSLog(@"Couldn't add video output");
	[videoOut release];
}


- (id) init {
	
	if (self = [super init]) {

		self.captureSession = [[AVCaptureSession alloc] init];
		//self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;

		foundColor = NO;
		shouldGetReferenceColor = NO;
		matchThreshold = 1;
		matchesForRecognition = 3;
		self.colorReferencePoint = CGPointMake(0.0, 0.0);
		self.recognizedRect = CGRectMake(0.0, 0.0, 100.0, 100.0);
		normalize(orangeColor, referenceColor);
	}
	
	return self;
}


- (void)dealloc {

	[self.captureSession stopRunning];

	[self.previewLayer release];
	[self.captureSession release];

	[super dealloc];
}

@end
