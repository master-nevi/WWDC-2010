### Breadcrumb ###

===========================================================================
DESCRIPTION:

The Breadcrumb sample demonstrates how to draw a path using a Map Kit overlay that follows the user's location.  The included CrumbPath and CrumbPathView overlay and overlay view classes can be used for any path of points that are expected to change over time.

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2 or later, Mac OS X v10.6 or later, iPhone SDK 4.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.0

===========================================================================
PACKAGING LIST:

CrumbPath
    - Implements a mutable path of locations.

CrumbPathView
    - MKOverlayView subclass that renders a CrumbPath.  Demonstrates the best way to create and render a list of points as a path in an MKOverlayView.
    
BreadcrumbViewController
    - Uses MKMapView delegate messages to track the user location and update the displayed path of the user on an MKMapView.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
