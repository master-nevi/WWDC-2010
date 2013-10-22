### Touches_GestureRecognizers ###

================================================================================
DESCRIPTION:

The Touches_GestureRecognizers sample application demonstrates how to handle touch events using UIGestureRecognizer introduced in iPhone OS 4.0. It shows how to handle touches, including multiple touches that move multiple objects.  After the application launches, three colored pieces appear onscreen that the user can move independently. Touches cause up to three lines of text to be displayed at the top of the screen.
 
================================================================================
BUILD REQUIREMENTS:

iPhone SDK 4.0

================================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.0 or later.

================================================================================
PACKAGING LIST:

Main.m
The main entry point for the Touches application.

TouchesAppDelegate.h
TouchesAppDelegate.m
The UIApplication  delegate. On start up, this object receives the applicationDidFinishLaunching: delegate message and creates an instance of MyView, which in turn brings up the user interface.

MyView.h
MyView.m
This view implements custom methods that respond to user gestures using UIGestureRecognizer. MyView animates and moves pieces onscreen in response to touch events. 

================================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
