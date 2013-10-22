/*
     File: AVCamViewController.h
 Abstract: View controller code that manages all the buttons in the main view (HUD, Swap, Record, Still, Grav) as well as the device controls and and session properties (Focus, Exposure, Power, Peak, etc.) that are displayed over the live capture window.
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

#import <UIKit/UIKit.h>

@class AVCamCaptureManager, AVCamPreviewView, ExpandyButton, AVCaptureVideoPreviewLayer;

@interface AVCamViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    @private
    AVCamCaptureManager *_captureManager;
    AVCamPreviewView *_videoPreviewView;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    UIView *_adjustingInfoView;
    UIBarButtonItem *_cameraToggleButton;
    UIBarButtonItem *_recordButton;
    UIBarButtonItem *_stillButton;
    UIBarButtonItem *_gravityButton;
    ExpandyButton *_flash;
    ExpandyButton *_torch;
    ExpandyButton *_focus;
    ExpandyButton *_exposure;
    ExpandyButton *_whiteBalance;
    ExpandyButton *_preset;
    ExpandyButton *_videoConnection;
    ExpandyButton *_audioConnection;
    ExpandyButton *_orientation;
    ExpandyButton *_mirroring;
    
    UIView *_adjustingFocus;
    UIView *_adjustingExposure;
    UIView *_adjustingWhiteBalance;
    
    UIView *_statView;
    
    IBOutlet UILabel *_averagePowerLevel;
    IBOutlet UILabel *_peakHoldLevel;
    IBOutlet UILabel *_focusPoint;
    IBOutlet UILabel *_exposurePoint;
    IBOutlet UILabel *_deviceCount;
    IBOutlet UILabel *_recordingDuration;
    IBOutlet UILabel *_fileSize;
    
    NSNumberFormatter *_numberFormatter;
    BOOL _hudHidden;
    CALayer *_focusBox;
    CALayer *_exposeBox;    
}

@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet AVCamPreviewView *videoPreviewView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UIView *adjustingInfoView;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *cameraToggleButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *recordButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *stillButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *gravityButton;
@property (nonatomic,retain) ExpandyButton *flash;
@property (nonatomic,retain) ExpandyButton *torch;
@property (nonatomic,retain) ExpandyButton *focus;
@property (nonatomic,retain) ExpandyButton *exposure;
@property (nonatomic,retain) ExpandyButton *whiteBalance;
@property (nonatomic,retain) ExpandyButton *preset;
@property (nonatomic,retain) ExpandyButton *videoConnection;
@property (nonatomic,retain) ExpandyButton *audioConnection;
@property (nonatomic,retain) ExpandyButton *orientation;
@property (nonatomic,retain) ExpandyButton *mirroring;

@property (nonatomic,retain) IBOutlet UIView *adjustingFocus;
@property (nonatomic,retain) IBOutlet UIView *adjustingExposure;
@property (nonatomic,retain) IBOutlet UIView *adjustingWhiteBalance;

@property (nonatomic,retain) IBOutlet UIView *statView;

@property (nonatomic,retain) IBOutlet UILabel *averagePowerLevel;
@property (nonatomic,retain) IBOutlet UILabel *peakHoldLevel;
@property (nonatomic,retain) IBOutlet UILabel *focusPoint;
@property (nonatomic,retain) IBOutlet UILabel *exposurePoint;
@property (nonatomic,retain) IBOutlet UILabel *deviceCount;
@property (nonatomic,retain) IBOutlet UILabel *recordingDuration;
@property (nonatomic,retain) IBOutlet UILabel *fileSize;

#pragma mark Toolbar Actions
- (IBAction)hudViewToggle:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)still:(id)sender;
- (IBAction)cameraToggle:(id)sender;
- (IBAction)cycleGravity:(id)sender;

#pragma mark HUD Actions
- (void)flashChange:(id)sender;
- (void)torchChange:(id)sender;
- (void)focusChange:(id)sender;
- (void)exposureChange:(id)sender;
- (void)whiteBalanceChange:(id)sender;
- (void)presetChange:(id)sender;
- (void)adjustOrientation:(id)sender;
- (void)adjustMirroring:(id)sender;
@end

