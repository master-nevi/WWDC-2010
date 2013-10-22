/*
    File: EAGLView.h
Abstract: View to display OpenGL ES teapot, along with UI controls to adjust various motion properties.
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
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <CoreMotion/CoreMotion.h>

#import "matrix.h"
#import "AccelerometerFilter.h"

@interface EAGLView : UIView
{    
@private
	BOOL animating;
	NSInteger animationFrameInterval;
	CADisplayLink *displayLink;
	EAGLContext *context;
	GLuint viewRenderbuffer, viewFramebuffer;
	GLuint depthRenderbuffer;
	GLint backingWidth;
	GLint backingHeight;
	
	mat4f_t projectionMatrix;
	mat4f_t modelViewMatrix;
	
	struct {
		// Handle to a program object
		GLuint prog;

		// Attributes
		GLint position;
		GLint normal;

		// Uniforms
		GLint mvpMatrix;
		GLint modelViewMatrix;
		GLint lightDirection;
		GLint lightHalfPlane;
		GLint lightAmbientColor;
		GLint lightDiffuseColor;
		GLint lightSpecularColor;
		GLint materialAmbientColor;
		GLint materialDiffuseColor;
		GLint materialSpecularColor;
		GLint materialSpecularExponent;
	} glHandles;
	
	CMMotionManager *motionManager;
	
	// YES when we're only using the accelerometer, NO when we're using device motion
	BOOL accelMode;
			
	// Low-pass filter for raw accelerometer data
	// Only used the accelMode==YES	
	LowpassFilter *gravityLpf;
	
	// High-pass filter for raw accelerometer data
	// Only used the accelMode==YES	
	HighpassFilter *userAccelerationHpf;
	LowpassFilter *userAccelerationHpfLpf;

	
	// referenceAttitude
	// Only used when accelMode==NO
	CMAttitude *referenceAttitude;
	
	// Whether translation based on user acceleration is enabled
	// Only used when accelMode==NO
	BOOL translationEnabled;
	
	// Low-pass filter for user acceleration
	// Only used when accelMode==NO
	LowpassFilter *userAccelerationLpf;
	
	
	IBOutlet UISegmentedControl *modeControl;
	IBOutlet UILabel *gravityFilterLabel;
	IBOutlet UISlider *gravityFilterSlider;
	IBOutlet UIButton *resetButton;
	IBOutlet UILabel *translationLabel;
	IBOutlet UISwitch *translationSwitch;	
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void) updateControls;
- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView:(id)sender;
- (void) createFramebuffer;
- (void) destroyFramebuffer;
- (void) initializeGL;

- (IBAction)onModeControlValueChanged:(UISegmentedControl *)sender;
- (IBAction)onResetButton:(UIButton *)sender;
- (IBAction)onGravityFilterValueChanged:(UISlider *)sender;
- (IBAction)onTranslationValueChanged:(UISwitch *)sender;

@end
