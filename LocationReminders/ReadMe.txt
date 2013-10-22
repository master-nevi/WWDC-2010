### LocationReminders ###

===========================================================================
DESCRIPTION:

Reminders demonstrates the Core Location Framework's region monitoring
service. Developers should read the Location Awareness Programming Guide and
consult the class reference documentation for CLLocationManager,
CLLocationManagerDelegate, and CLLocation for detailed information about the
Core Location framework. In addition, the iPhone Application Programming Guide
has a section under "Executing Code in the Background", titled "Receiving
Location Events in the Background", which discusses best practices for receiving
location events in the background.

See also the LocateMe sample project which covers the basics of the Core
Location Framework.
===========================================================================
BUILD REQUIREMENTS:

iPhone SDK 4.0

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.0

===========================================================================
PACKAGING LIST:

RegionManager
Singleton class to manage region monitoring interations with a CLLocationManger

ReminderAnnotation
Implements MKOverlay protocol and is used as both an annotation and an overlay

ReminderAnnotationDetail
View controller for editing Reminder details

ReminderCircleView
Overlay view that draws a circle

RemindersAppDelegate
The application delegate

RemindersViewController
The main view controller consisting primarily of an MKMapView overlaid with annotations

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
