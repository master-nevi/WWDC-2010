Read Me About PinchyPreview
========================
1.0

PinchyPreview demonstrates how to use the AVFoundation framework's AVCaptureVideoPreviewLayer
class.  Using UIGestureRecognizers and shake-detection code, the preview reacts to user input.
Buttons in the MainControllerView's UI demonstrate how the layer's orientation property interacts
with the layer's surrounding view when following the view's UIInterfaceOrientation (or not).

PinchyPreview runs on iPhone OS 4.0 and later devices with a built-in video camera.

Packing List
------------
The sample contains the following items:

o ReadMe.txt -- This file.
o PinchyPreview.xcodeproj -- An Xcode project for the sample.
o Classes.[h,m] -- The core PinchyPreview code.
o main.m -- Creates the app object and the application delegate and sets up the
event cycle.
o *.xib, *.png -- xib files and image resources used by the user interface.

Using the Sample
----------------
Compile, link, and run the sample on a device running iPhone OS 4.0 or later with a built-in video 
camera.  In the app, use the Start button to start the AVCaptureSession running, then:

Pinch or pull to scale the preview layer.
Touch-drag to move the preview layer.
Twist with two fingers to rotate the preview layer.
Tap the preview layer to cycle through the 3 supported videoGravity modes:
	AVLayerVideoGravityResizeAspect
	AVLayerVideoGravityResizeAspectFill
	AVLayerVideoGravityResizeAspect
Shake to return the preview layer to its default size and position.
Use the lock/unlock UIView orientation and lock/unlock PreviewLayer orientation buttons to experiment
with the interactions between the preview layer and its parent view when autorotating the parent and
setting (or neglecting to set) the preview layer's "orientation" property.

Building the Sample
-------------------
The sample was built using Xcode 3.2.3 on Mac OS X 10.6.3 with the Mac OS X
10.6 SDK.  Build the app for "iPhone Device 4.0" (or later) SDK.  Note that AVFoundation classes do 
NOT work in the simulator.

How It Works
------------

PinchyPreview makes use of the following AVFoundation AVCapture classes:

AVCaptureSession
AVCaptureVideoPreviewLayer

See the AVFoundation documentation for more information.

It also shows how to use:

UITapGestureRecognizer - to cycle through AVCaptureVideoPreviewLayer's supported videoGravity modes
UIPinchGestureRecognizer - to scale the preview layer
UIPanGestureRecognizer - to move the preview layer within its super layer
UIRotationGestureRecognizer - to rotate the preview layer
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event; - to detect a shake and reset the preview layer

Credits and Version History
---------------------------
If you find any problems with this sample, please file a bug against it.

<http://developer.apple.com/bugreporter/>

1.0 (June 2010) was the first shipping version.
