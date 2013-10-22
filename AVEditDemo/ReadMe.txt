### AVEditDemo ###

===========================================================================
DESCRIPTION:

This sample demonstrates the editing features of AV Foundation. It illustrates how to:
- Extract images from a movie using AVAssetImageGenerator
- Export and trim a movie using AVAssetExportSession
- Combine clips from multiple movies using AVComposition
- Adjust the volume of audio tracks using AVAudioMix
- Add video transitions using AVVideoComposition
- Incorporate Core Animation in movies for playback using AVSynchronizedLayer, and for export using AVVideoCompositionCoreAnimationTool

===========================================================================
BUILD REQUIREMENTS:

Xcode 3.2.3 or later; Mac OS X v10.6.3 or later; iPhone OS v4.0 or later.

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS v4.0 or later

===========================================================================
PACKAGING LIST:

SimpleEditor.{h,m}
Demonstrates construction of AVComposition, AVAudioMix, and AVVideoComposition.


AssetBrowserController.{h,m}
A view controller for asset selection.


AssetBrowserItem.{h,m}
Represents an asset in AssetBrowserController.


AssetBrowserSource.{h,m}
A source for AssetBrowserController to find assets in.


PlayerView.{h,m}
UIView for an AVPlayerLayer.


PlayerViewController.{h,m}
View controller for composition playback.


ProjectViewController.{h,m}
Root view controller which provides editing UI.


ThumbnailViewController.{h,m}
View controller for thumbnail view.


TimeSliderCell.{h,m}
Table view cell to display a time slider with a label.


TitleEditingCell.{h,m}
Table view cell containing a text editing field.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
Set the audio session category to AVAudioSessionCategoryPlayback when the application launches.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.
