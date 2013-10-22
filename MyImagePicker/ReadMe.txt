MyImagePicker
======================

Demonstrates how to use the AssetsLibrary framework to create a UI similar to the UIImagePicker.


Build Requirements
------------------
iPhone SDK 4.0 or later


Runtime Requirements
--------------------
iPhone OS 4.0 or later


Using the Sample
----------------
Open the project, build it and run it on a device where the camera roll and iTunes synced images will be available.


Packaging List
--------------



AssetsDataIsInaccessibleViewController.{h,m}
 - View controller displayed when enumerating asset groups fails.

AlbumContentsTableViewCell.{h,m}
- Table view cell that displays four photo thumbnails in a row.

AlbumContentsViewController.{h,m}
- View controller to manage displaying the contents of an album.

MyImagePickerAppDelegate.{h,m}
- Default application delegate created by Xcode.

PhotoDisplayViewController.{h,m}
- View controller to manage displaying a photo.

RootViewController.{h,m}
- Main view controller for the application which is in charge of displaying the list of albums.

TapDetectingImageView.{h,m}
- UIImageView subclass that responds to taps and notifies its delegate.
           (Borrowed from the TapToZoom sample application)

ThumbnailImageView.{h,m}
- View that responds to taps and highlights the selected thumbnail.


Changes from Previous Versions
1.0 - First release


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.

Copyright (C) 2010, Apple Inc.