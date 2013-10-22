/*
     File: AVCamCaptureManager.h
 Abstract: Code that calls the AVCapture classes to implement the camera-specific features in the app such as recording, still image, camera exposure, white balance and so on.
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

enum {
    AVCamMirroringOff   = 1,
    AVCamMirroringOn    = 2,
    AVCamMirroringAuto  = 3
};
typedef NSInteger AVCamMirroringMode;

@protocol AVCamCaptureManagerDelegate
@optional
- (void) captureStillImageFailedWithError:(NSError *)error;
- (void) acquiringDeviceLockFailedWithError:(NSError *)error;
- (void) cannotWriteToAssetLibrary;
- (void) assetLibraryError:(NSError *)error forURL:(NSURL *)assetURL;
- (void) someOtherError:(NSError *)error;
- (void) recordingBegan;
- (void) recordingFinished;
- (void) deviceCountChanged;
@end

@interface AVCamCaptureManager : NSObject {
@private
    // Capture Session
    AVCaptureSession *_session;
    AVCaptureVideoOrientation _orientation;
    AVCamMirroringMode _mirroringMode;
    
    // Devic Inputs
    AVCaptureDeviceInput *_videoInput;
    AVCaptureDeviceInput *_audioInput;
    
    // Capture Outputs
    AVCaptureMovieFileOutput *_movieFileOutput;
    AVCaptureStillImageOutput *_stillImageOutput;
    
    // Identifiers for connect/disconnect notifications
    id _deviceConnectedObserver;
    id _deviceDisconnectedObserver;
    
    // Identifier for background completion of recording
    UIBackgroundTaskIdentifier _backgroundRecordingID; 
    
    // Capture Manager delegate
    id <AVCamCaptureManagerDelegate> _delegate;
}

@property (nonatomic,readonly,retain) AVCaptureSession *session;
@property (nonatomic,assign) AVCaptureVideoOrientation orientation;
@property (nonatomic,readonly,retain) AVCaptureAudioChannel *audioChannel;
@property (nonatomic,assign) NSString *sessionPreset;
@property (nonatomic,assign) AVCamMirroringMode mirroringMode;
@property (nonatomic,readonly,retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic,readonly,retain) AVCaptureDeviceInput *audioInput;
@property (nonatomic,assign) AVCaptureFlashMode flashMode;
@property (nonatomic,assign) AVCaptureTorchMode torchMode;
@property (nonatomic,assign) AVCaptureFocusMode focusMode;
@property (nonatomic,assign) AVCaptureExposureMode exposureMode;
@property (nonatomic,assign) AVCaptureWhiteBalanceMode whiteBalanceMode;
@property (nonatomic,readonly,retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic,assign) id <AVCamCaptureManagerDelegate> delegate;
@property (nonatomic,readonly,getter=isRecording) BOOL recording;

- (BOOL) setupSessionWithPreset:(NSString *)sessionPreset error:(NSError **)error;
- (void) startRecording;
- (void) stopRecording;
- (void) captureStillImage;
- (BOOL) cameraToggle;
- (NSUInteger) cameraCount;
- (NSUInteger) micCount;
- (BOOL) hasFlash;
- (BOOL) hasTorch;
- (BOOL) hasFocus;
- (BOOL) hasExposure;
- (BOOL) hasWhiteBalance;
- (void) focusAtPoint:(CGPoint)point;
- (void) exposureAtPoint:(CGPoint)point;
- (void) setConnectionWithMediaType:(NSString *)mediaType enabled:(BOOL)enabled;
- (BOOL) supportsMirroring;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end
