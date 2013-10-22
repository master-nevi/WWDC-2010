### HazardMap ###

===========================================================================
DESCRIPTION:

The HazardMap sample demonstrates how to create a custom Map Kit overlay and corresponding view to display USGS earthquake hazard data on top of an MKMapView.

For more information on earthquake hazard data, see http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/.

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2 or later, Mac OS X v10.6 or later, iPhone SDK 4.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.0

===========================================================================
PACKAGING LIST:

HazardMap
	- Custom MKOverlay model class representing USGS Earthquake hazard data.

HazardMapView
	- Custom MKOverlayView class corresponding to the HazardMap model class.  Demonstrates how to draw unprojected gridded data.

HazardMapViewController
	- Implements MKMapView delegate and shows how to display the custom HazardMap overlay on an MKMapView.

UShazard.20081229.pga.5pc50.bin
	- USGS Earthquake Hazard data fetched from http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/2008.US.pga.5pc50.txt.gz.  This file has been compressed from the text version available directly from the USGS using compactgrid.c program included with the HazardMap sample project in order to reduce app launch time.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
