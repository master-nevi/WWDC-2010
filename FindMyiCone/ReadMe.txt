Read Me About Process
========================
1.0

Process demonstrates how to use the AVFoundation framework's AVCaptureVideoDataOutput
class to process video frames from the camera, find a pattern, and superimpose a rectangle
over the matching area in an AVCaptureVideoPreviewLayer.

Process runs on iPhone OS 4.0 and later devices with a built-in video camera.

Packing List
------------
The sample contains the following items:

o ReadMe.txt -- This file.
o Process.xcodeproj -- An Xcode project for the sample.
o Classes.[h,m] -- The core Process code.
o main.m -- Creates the app object and the application delegate and sets up the
event cycle.
o *.xib, *.png -- xib files and image resources used by the user interface.

Using the Sample
----------------
Compile, link, and run the sample on a device running iPhone OS 4.0 or later with a built-in video 
camera.  In the app, tap to specify a target color for matching.  Swiping up reveals tuning controls,
and swiping down hides them.

Building the Sample
-------------------
The sample was built using Xcode 3.2.3 on Mac OS X 10.6.3 with the Mac OS X
10.6 SDK.  Build the app for "iPhone Device 4.0" (or later) SDK.  Note that AVFoundation classes do 
NOT work in the simulator.

How It Works
------------

Process makes use of the following AVFoundation AVCapture classes:

AVCaptureSession
AVCaptureDevice
AVCaptureDeviceInput
AVCaptureVideoDataOutput
AVCaptureVideoPreviewLayer

See the AVFoundation documentation for more information.

Credits and Version History
---------------------------
If you find any problems with this sample, please file a bug against it.

<http://developer.apple.com/bugreporter/>

1.0 (June 2010) was the first shipping version.
