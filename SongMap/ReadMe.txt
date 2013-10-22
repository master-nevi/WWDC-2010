### SongMap ###

===========================================================================
DESCRIPTION:

SongMap demonstrates the Core Location Framework's significant change location service. Developers should read the Location Awareness Programming Guide and consult the class reference documentation for CLLocationManager, CLLocationManagerDelegate, and CLLocation for detailed information about the Core Location framework. In addition, the iPhone Application Programming Guide has a section under "Executing Code in the Background", titled "Receiving Location Events in the Background", which discusses best practices for receiving location events in the background.

See also the LocateMe sample project which covers the basics of the Core Location Framework.

===========================================================================
BUILD REQUIREMENTS:

iPhone SDK 4.0

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.0

===========================================================================
PACKAGING LIST:

SongMapAppDelegate
The application delegate is responsible for instantiating the managed object context, responding to defaults changes, and, most importantly for this sample, setting up the CLLocationManger.

MainViewController
This controller manages the primary view. It is responsible for monitoring changes to the managed object context, adding additional annotations, and returning annotation views to the map view for display.

SongLocation
SongLocation is a simple NSManagedObject subclass that provides a few utility methods as well as type checking.

FlipsideViewController
The FlipsideViewController is instantiated by the MainViewController and manages the utility view showing user preferences.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
