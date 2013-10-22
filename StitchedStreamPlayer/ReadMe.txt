
### StitchedStreamPlayer ###

===========================================================================
DESCRIPTION:

A simple AVFoundation demonstration of how timed metadata can be used to identify different content in a stream, supporting a custom seek UI.

This sample expects the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries.

In this example, the metadata payload is either a list of ads ("ad-list") or an ad record ("url"). Each ad in the list of ads is specified by a start-time and end-time pair of values. Each ad record is specified by a URL which points to the ad video to play.

The ID3 key
AVMetadataID3MetadataKeyGeneralEncapsulatedObject is used to identify the metadata in the stream.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X 10.5.6, Xcode 3.1.3, iPhone OS 3.0

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6.3, iPhone OS 4.0

===========================================================================
PACKAGING LIST:

TBD

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0 - First Release

===========================================================================
Copyright (C) 2008-2010 Apple Inc. All rights reserved.