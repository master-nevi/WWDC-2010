### DocView ###

===========================================================================
DESCRIPTION:

This sample demonstrates how to use UIDocumentInteractionController to obtain information about documents and how to preview them. It also demonstrates the use of UIFileSharingEnabled feature as well as leveraging "kqueue" kernel event notifications to monitor the contents of the app's Documents folder.

In addition it leverages UIDocumentInteractionController's built-in UIGestureRecognizers (i.e. single tap = preview, tap-hold = options menu) by attaching them to the display icon.

FolderWatcher
An object used to help monitor the contents of the "Documents" folder by using "kqueue", a kernel event notification mechanism.
Normally apps would use these UIApplication delegate calls to scan the Documents folder for content changes:
	- (void)applicationDidBecomeActive:(UIApplication *)application;
	- (void)applicationWillResignActive:(UIApplication *)application;
With the FolderWatcher object, rather, you can detect changes without having to unnecessarily scan the Documents folder in numerous places in your code.

DocView also acts as "Rank Alternate" or a so-called "secondary" viewer of the document type public.jpeg and public.image.  In doing so, it can handle the opening of these image files from other applications and just simply previewing them.


===========================================================================
BUILD REQUIREMENTS:

iPhone SDK 3.2


===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 3.2


===========================================================================
PACKAGING LIST:

AppDelegate.{h/m} -
The app delegate class that downloads in the background the
"Top Paid iPhone Apps" RSS feed using NSURLConnection.

RootViewController.{h/m} -
The left side view controller or master view controller containing the UITableView.

DetailViewController.{h/m} -
The view controller representing the right or detail view of the split view controller.

DirectoryWatcher.{h/m} -
Object used to monitor the contents of a given directory by using "kqueue": a kernel event notification mechanism.

TappableView.{h/m} -
The custom view used for attachnig the built-in gesture recognizers.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.