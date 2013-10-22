### Touches ###

================================================================================
DESCRIPTION:

The Touches sample includes two packages. 

"Touches_Classic" demonstrates how to handle touches using UIResponder's: touches began, touches moved, and touches ended.

"Touches_GestureRecognizers" demonstrates how to use UIGestureRecognizers introduced in iPhone OS 4.0 to handle touch events.

================================================================================
BUILD REQUIREMENTS:

iPhone SDK 4.0

================================================================================
RUNTIME REQUIREMENTS:

Touches_Classic: iPhone OS 3.1.3 or later.
Touches_GestureRecognizers: iPhone OS 4.0 or later.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.9
-Added UIGestureRecognizers. Upgraded for 4.0 SDK. 

Version 1.8
-Now uses nibs for view creation. Status bar is now displayed on launch. Project updated to use the iPhone 3.0 SDK.

Version 1.7
-Updated for and tested with iPhone OS 2.0. First public release.

Version 1.6
-Updated the application description to match previous changes to the code.
-Edited comments in some of the source files.
-There are no code changes in the version.	

Version 1.5
-Changed the status bar to black to match the background of the application.
-Changed the text layout on the screen; revised the wording.
-Updated the build and runtime requirements.

Version 1.4
-Updated for Beta 5.
-Removed the code for displaying swipe information. This information is no longer available in a touch object.
-Implemented touchesCanceled:withEvent

Version 1.3
-Updated for Beta 4.
-Touches is now built on the Cocoa Touch Application template in Xcode. The application now uses a xib file for setting up the interface. The code that performed window setup was removed. The GestureView is in the xib file, so that view is now initialized through initWithCoder:
-Added code signing settings.
-Fixed text spacing to account for the origin of the superview frame.

Version 1.2
-Added an application icon. 
-Added a Default.png image.
-There are no code changes in this version.

Version 1.1 
-Updated for Beta 2.
-Updated the code to use the locationInView: method of UITouch, which was recently added to 
replace the locationInView property.

================================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
