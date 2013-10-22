MyImagePicker
======================

Demonstrates how to use the AssetsLibrary framework to create an application that displays images to the user using a visual interface that is completely different than the one provided by the system with UIImagePicker.


Build Requirements
------------------
iPhone SDK 4.0 or later


Runtime Requirements
--------------------
iPhone OS 4.0 or later


Using the Sample
----------------
Open the project, build it and run it on a device where iTunes Events have been synced. Events are the only ones displayed by the applications, not Faces, Albums or Saved Photos.


Packaging List
--------------



FavoriteAssets.{h,m}
 - Class used to manage a group of asset URLs as those marked as favorites by the user.

ApplicationConstants.{h,m}
 - Constants used across the application.

AssetsDataIsInaccessibleViewController.{h,m}
 - View controller displayed when enumerating asset groups fails.

AssetsGroupsTableViewCell.{h,m}
 - View that responds to taps and highlights the selected thumbnail.

AssetsList.{h,m}
 - Class used to provide a common interface to ALAssetGroup and NSArray based lists of assets.

AssetsListProtocols.h
 - Protocols used for working with AssetsList objects.

AssetViewController.{h,m}
 - View controller for displaying an asset.

CrumbPath.{h,m}
 - MKOverlay model class representing a path that changes over time.

CrumbPathView.{h,m}
 - MKOverlay view representing a path that changes over time.

FavoriteAssets.{h,m}
 - Class used to manage a group of asset URLs as those marked as favorites by the user.

MapAnnotation.{h,m}
 - Class to link assets to pin annotation on the MKMapView.

MapViewController.{h,m}
 - View controller for the map view that shows all the photos in a given asset group.

MetadataViewController.{h,m}
 - View controller for the metadata view of a given asset representation.

PhotosByLocationAppDelegate.{h,m}
 - Default application delegate implementation created by Xcode.

PosterImageView.{h,m}
 - View that responds to taps and highlights the selected thumbnail.

RootViewController.{h,m}
 - Main view controller for the application. It manages a list of albums.

TapDetectingImageView.{h,m}
 - UIImageView subclass that responds to taps and notifies its delegate.
           (Borrowed from the TapToZoom sample application)


Changes from Previous Versions
1.0 - First release


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.

Copyright (C) 2010, Apple Inc.