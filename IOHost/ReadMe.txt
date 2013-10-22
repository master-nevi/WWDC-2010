IOHost

===========================================================================
DESCRIPTION:

IOHost demonstrates basic use of Audio Unit Services and related APIs in iPhone OS for hosting audio processing plug-ins, known as audio units. This sample is described in the "Using I/O Units and Audio Processing Graphs" chapter of Audio Unit Hosting Guide for iPhone OS.

The code in IOHost instantiates two system-supplied audio units--the Remote I/O unit (of subtype "kAudioUnitSubType_RemoteIO") and the Multichannel Mixer unit (of subtype kAudioUnitSubType_MultichannelMixer)--and connects them together using an audio processing graph (an AUGraph opaque type). Audio from the microphone enters the input side of the I/O unit, passes through the mixer, and then proceeds through the output side of the I/O unit on its way to the output hardware (typically, the headset jack). To hear the stereo output from the sample, use a headset rather than the built-in (mono) receiver or speaker. 

In this sample, the Multichannel Mixer unit's panning parameter is connected to a slider control on the screen. By moving the slider as you talk, you change the stereo positioning of your voice in the headset.

The sample also demonstrates basic use of the AVAudioSession class for configuring audio behavior.

This sample shows how to:

	* Locate system audio units at runtime, load them, instantiate 
		them, configure them, and connect them.
	* Correctly use audio stream formats in the context of an audio 
		processing graph.
	* Instantiate, open, initialize, and start an audio processing graph.
	* Control a Multichannel Mixer unit through a user interface.

This sample also shows how to:

	* Configure an audio session for simultaneous input and output.
	* Configure an audio session delegate for handling interruptions.
	* Use the audio session shared instance to set hardware sample rate 
		and to set a very short hardware I/O buffer duration.
	* Customize a UISlider object to represent an audio panning 
		control (by using the same color for the slider track on both
		sides of the slider thumb).

This sample does not show how to handle audio hardware route changes or how to perform some other advanced audio session tasks. All of those are described in Audio Session Programming Guide.

Also, because this sample conveys audio from the input hardware straight through to the output hardware, it does not use a render callback function--and so it does not demonstrate how to write one.

===========================================================================
RELATED INFORMATION:

Audio Unit Hosting Guide for iPhone OS, June 2010
Audio Session Programming Guide, January 2010


===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.6.3, Xcode 3.2, iPhone OS 4.0


===========================================================================
RUNTIME REQUIREMENTS:

Simulator: Mac OS X v10.6.3
iPhone: iPhone OS 4.0


===========================================================================
PACKAGING LIST:

IOHostAppDelegate.h
IOHostAppDelegate.m

The IOHostAppDelegate class defines the application delegate object, responsible for instantiating the controller object (defined in the IOHostViewController class) and adding the application's view to the application window.

IOHostViewController.h
IOHostViewController.m

The AudioViewController class defines the controller object for the application. The object helps set up the user interface, responds to and manages user interaction, responds to changes in the state of the playback or recording object, handles interruptions to the application's audio session, and handles various housekeeping duties.

IOHostAudio.h
IOHostAudio.m

The AudioQueueObject class defines a superclass for playback and recording objects, encapsulating the state and behavior that is common to both.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0. New sample application that demonstrates how to host an I/O unit.
 
================================================================================
Copyright (C) 2010 Apple Inc. All rights reserved.