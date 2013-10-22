### AddressBook-PhotoCutouts ###

===========================================================================
DESCRIPTION:

This application shows how you can use the Address Book framework to insert contacts' photos into cutouts.

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2 iPhone OS 4

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2

===========================================================================
PACKAGING LIST:


Model and Model Classes
-----------------------

Cutout.{h,m}
Model class to represent a photo cutout.



Application Configuration
-------------------------

AppDelegate.{h,m}
MainWindow_{iPhone,iPad}.xib
Application delegate that sets up either a root view controller or a split view controller, depending on whether the target OS is for iPhone or iPad.



PhotoBook View Controllers
------------------------

GalleryViewController.{h,m}
Table view controller to manage a table view of cutout photos. 
This is the "topmost" view controller in the PhotoBook stack.


CutoutViewController.{h,m}
View controller to manage both creation and display of cutouts.
When editable, this controller walks the user through the creation process.
When not editable, this controller displays an existing cutout and associated contact information.


PhotoPickerViewController.{h,m}
View controller to manage selection of an image from among several images.


DetailViewController.{h,m}
View controller to manage the detail view of the split view controller.



===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
Fixes issues with opening attachments, matching, and external database changes.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
