
This is sample code for the "Core Animation in Practice, Part 2"
session of WWDC 2010. It requires an iPad and the iPhone OS 3.2 SDK.

Edit the Classes/ImageBrowserOptions.h file to toggle the various ways
in which the app can be configured to illustrate the relative
performance of different ways of implementing the same underlying UI -
a scrolling list of image thumbnails.

Important Note
==============

This sample project requires a set of image files to be added to the
project. Copy 10-30 roughly screen-sized (1024x768) images to the
Resources/Images directory, then add them to the Xcode project's "Copy
Images" build phase (of the ImageBrowser target). Note, by default
Xcode may add them to the "Copy Resources" build phase, which is not
what is needed.

