### KMLViewer ###

===========================================================================
DESCRIPTION:

The KMLViewer sample application demonstrates how to use Map Kit's Annotations and Overlays to display KML files on top of an MKMapView.

Information on the KML file format can be found at http://code.google.com/apis/kml/documentation/

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2, Mac OS X v10.6 or later, iPhone SDK 4.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.0

===========================================================================
PACKAGING LIST:

KMLParser
	- A simple NSXMLParser based parser for KML files.  Creates both model objects for annotations and overlays as well as styled views for model and overlay views.

KMLViewerViewController
	- Demonstrates usage of the KMLParser class in conjunction with an MKMapView.

route.kml
	- A KML file describing a bicycling route between Cupertino and Palo Alto, exported from maps.google.com.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
