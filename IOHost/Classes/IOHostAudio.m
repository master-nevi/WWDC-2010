/*
    File: IOHostAudio.m
Abstract: Audio object: Handles all audio tasks for the application.
 Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

#import "IOHostAudio.h"


@implementation IOHostAudio

@synthesize graphSampleRate;	// The sample rate to use throughout the audio processing graph
@synthesize ioBufferDuration;	// The hardware I/O buffer duration
@synthesize ioUnit;				// The Remote I/O unit: Handles input/output, from/to device hardware
@synthesize mixerUnit;			// The Multichannel Mixer unit: Provides stereo panning


- (id) init {

    self = [super init];

	// If object initialization fails, return immediately.
    if (!self) {
       return nil;
    }
	
	// Check whether audio input is available; this app works only if it is.
	BOOL audioInputAvailable = [[AVAudioSession sharedInstance] inputIsAvailable];
	
	if (!audioInputAvailable) {
		// In a shipping application, you should handle the condition that audio input 
		//	is not available.
	}

	// Configure the audio session.
	[self setupAudioSession];
	
	// Set up the audio processing graph.
	[self configureAndInitializeAudioProcessingGraph];

	// Start the audio processing graph. For simplicity in this sample project, there's
	//	no user interface for "start" or "stop";  audio runs while the application runs.
	[self startAUGraph];

	return self;
}

- (void) dealloc {	
	
	[self stopAUGraph];
	[super dealloc];
}


# pragma mark -
# pragma mark General Audio Setup

- (void) setupAudioSession {

	// Specify that this object is the delegate of the audio session, so that
	//	this object's endInterruption method will be invoked when needed.
	[[AVAudioSession sharedInstance] setDelegate: self];


	// Assign the PlayAndRecord category to the audio session. This category 
	//	supports audio input and output.
	NSError *setCategoryError = nil;
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord
										   error: &setCategoryError];

	// Request a short hardware I/O buffer duration.
	self.ioBufferDuration	= 0.005;
	
	NSError *setBufferDurationError = nil;
	[[AVAudioSession sharedInstance] setPreferredIOBufferDuration: ioBufferDuration
															error: &setBufferDurationError];

	// In case you want to know the actual hardware I/O buffer duration, this is how you obtain
	//	the value.
	/*
    UInt32 bufferDurationSize = sizeof (Float32);
	OSStatus result = AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareIOBufferDuration, &bufferDurationSize, &ioBufferDuration);
	if (result) {[self printErrorMessage: @"Couldn't get hardware I/O buffer duration" withStatus: result]; return;}
	*/

	// Request the desired hardware sample rate.
	self.graphSampleRate	= 44100.0;	// Hertz
	
	NSError *setHardwareSampleRateError = nil;
	[[AVAudioSession sharedInstance] setPreferredHardwareSampleRate: graphSampleRate
															  error: &setHardwareSampleRateError];
	
	// Activate the audio session
	NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive: YES
										 error: &activationError];

	// Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
	self.graphSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
}


#pragma mark -
#pragma mark Audio Processing Graph Setup

// This (rather long) method performs all the work needed to set up the audio 
//	processing graph:

	// 1. Instantiate and open an audio processing graph
	// 2. Obtain the audio unit nodes for the graph
	// 3. Configure the I/O unit
	//		• enable input; output is enabled by default
	//		• install the render callback function
	//		• configure the stream format for the output scope of the I/O unit input bus
	// 4. Configure the Multichannel Mixer unit
	//		• specify the number of input buses
	//		• specify the output sample rate
	//		• specify the maximum frames-per-slice
	// 5. Initialize the audio processing graph
	
- (void) configureAndInitializeAudioProcessingGraph {
    NSLog (@"Configuring and then initializing audio processing graph");

	OSStatus result	= noErr;

//............................................................................
// Create a new audio processing graph.
	result = NewAUGraph (&processingGraph);

	if (result) {[self printErrorMessage: @"NewAUGraph" withStatus: result]; return;}

//............................................................................
// Specify the audio unit component descriptions for the audio units to be
//	added to the graph.

    // I/O unit
	AudioComponentDescription ioUnitDescription;
	ioUnitDescription.componentType				= kAudioUnitType_Output;
	ioUnitDescription.componentSubType			= kAudioUnitSubType_RemoteIO;
	ioUnitDescription.componentManufacturer		= kAudioUnitManufacturer_Apple;
	ioUnitDescription.componentFlags			= 0;
	ioUnitDescription.componentFlagsMask		= 0;
    
    // Multichannel Mixer unit
	AudioComponentDescription mixerUnitDescription;
	mixerUnitDescription.componentType			= kAudioUnitType_Mixer;
	mixerUnitDescription.componentSubType		= kAudioUnitSubType_MultiChannelMixer;
	mixerUnitDescription.componentManufacturer	= kAudioUnitManufacturer_Apple;
	mixerUnitDescription.componentFlags			= 0;
	mixerUnitDescription.componentFlagsMask		= 0;


//............................................................................
// Add nodes to the audio processing graph.
    NSLog (@"Adding nodes to audio processing graph");

    AUNode ioNode;												// this one node is used twice, and separately, 
																//	for the I/O unit's input bus and output bus
	AUNode mixerNode;											// this node is for the Multichannel Mixer unit

	// Add the I/O unit node to the audio processing graph.
	//		An audio processing graph must contain exactly one I/O unit, but 
	//		this sample needs to use the input side as well as the output side. 
	//		To do this, connect the single I/O node in two different ways; one 
	//		for input, one for output, as shown later.
	result =	AUGraphAddNode (
					processingGraph,
					&ioUnitDescription,
					&ioNode
				);
	
	if (result) {[self printErrorMessage: @"AUGraphNewNode failed for I/O unit node" withStatus: result]; return;}

	// Add the Multichannel Mixer unit node to audio processing graph.
	result =	AUGraphAddNode (
					processingGraph,
					&mixerUnitDescription,
					&mixerNode
				);

	if (result) {[self printErrorMessage: @"AUGraphNewNode failed for Multichannel Mixer unit" withStatus: result]; return;}


//............................................................................
// Open the audio processing graph

	// Following this call, the audio units are instantiated but not initialized
	//	(no resource allocation occurs and the audio units are not in a state to
	//	process audio).
	result = AUGraphOpen (processingGraph);
	
	if (result) {[self printErrorMessage: @"AUGraphOpen" withStatus: result]; return;}


//............................................................................
// Obtain the audio unit instances from their corresponding nodes, so you can
//	then configure them

	// Obtain the I/O unit instance from the corresponding node.
	result =	AUGraphNodeInfo (
					processingGraph,
					ioNode,
					NULL,
					&ioUnit
				);
	
	if (result) {[self printErrorMessage: @"AUGraphNodeInfo - I/O unit" withStatus: result]; return;}
	
	// Obtain the Multichannel Mixer unit instance from the corresponding node.
	result =	AUGraphNodeInfo (
					processingGraph,
					mixerNode,
					NULL,
					&mixerUnit
				);
	
	if (result) {[self printErrorMessage: @"AUGraphNodeInfo - Multichannel Mixer unit" withStatus: result]; return;}
	
	
//............................................................................
// I/O Unit Setup

	AudioUnitElement ioUnitInputBus = 1;
	
	// Enable input for the I/O unit, which is disabled by default. (Output is
	//	enabled by default, so there's no need to explicitly enable it.)
	UInt32 enableInput = 1;
	
	AudioUnitSetProperty (
		ioUnit,
		kAudioOutputUnitProperty_EnableIO,
		kAudioUnitScope_Input,
		ioUnitInputBus,
		&enableInput,
		sizeof (enableInput)
	);


	// Specify the stream format for output side of the I/O unit's 
	//	input bus (bus 1). For a description of these fields, see 
	//	AudioStreamBasicDescription in Core Audio Data Types Reference.
	//
	// Instead of explicitly setting the fields in the ASBD as is done 
	//	here, you can use the SetAUCanonical method from the Core Audio 
	//	"Examples" folder. Refer to:
	//		/Developer/Examples/CoreAudio/PublicUtility/CAStreamBasicDescription.h

	// The AudioUnitSampleType data type is the recommended type for sample data in audio
	//	units
	int bytesPerSample = sizeof (AudioUnitSampleType);
	
	// Declare an ASBD and initialize its fields to 0. You later apply this
	//	stream format to the output scope of the input element of the I/O unit
    AudioStreamBasicDescription	ioInputStreamFormat = {0}; 

	ioInputStreamFormat.mFormatID			= kAudioFormatLinearPCM;
	ioInputStreamFormat.mFormatFlags		= kAudioFormatFlagsAudioUnitCanonical;
	ioInputStreamFormat.mBytesPerPacket		= bytesPerSample;
	ioInputStreamFormat.mBytesPerFrame		= bytesPerSample;
	ioInputStreamFormat.mFramesPerPacket	= 1;
	ioInputStreamFormat.mBitsPerChannel		= 8 * bytesPerSample;
	ioInputStreamFormat.mChannelsPerFrame	= 1;
	ioInputStreamFormat.mSampleRate			= graphSampleRate;

	NSLog (@"The stream format for the output scope of the I/O unit input element:");
	[self printASBD: ioInputStreamFormat];
	
	// Apply the input stream format to the output scope of the I/O unit's input bus.
	NSLog (@"Setting kAudioUnitProperty_StreamFormat for the I/O unit input bus's output scope");
	result =	AudioUnitSetProperty (
					ioUnit,
					kAudioUnitProperty_StreamFormat,
					kAudioUnitScope_Output,
					ioUnitInputBus,
					&ioInputStreamFormat,
					sizeof (ioInputStreamFormat)
				);

	if (result) {[self printErrorMessage: @"AudioUnitSetProperty (set I/O unit input stream format)" withStatus: result]; return;}

	// There's no need to specify the stream format for the input scope of the I/O unit's output element.
	//	Upon graph initialization, that format gets set according to the Multichannel Mixer unit's output 
	//	stream format.


//............................................................................
// Multichannel Mixer Unit Setup

	// Configure the Multichannel Mixer unit input scope to have one bus.
	UInt32 inputBusCount			= 1; 

    NSLog (@"Setting Multichannel Mixer unit input bus count to: %lu", inputBusCount);
    result =	AudioUnitSetProperty (
					mixerUnit,
					kAudioUnitProperty_ElementCount,
					kAudioUnitScope_Input,
					0, // always use 0 here
					&inputBusCount,
					sizeof (inputBusCount)
				);

	if (result) {[self printErrorMessage: @"AudioUnitSetProperty (set Multichannel Mixer unit bus count)" withStatus: result]; return;}


	// Apply the same sample rate to the output of the mixer unit
	NSLog (@"Setting kAudioUnitProperty_SampleRate for the Multichannel Mixer unit output scope");
	result =	AudioUnitSetProperty (
					mixerUnit,
					kAudioUnitProperty_SampleRate,
					kAudioUnitScope_Output,
					0,	// bus number
					&graphSampleRate,
					sizeof (graphSampleRate)
				);

	if (result) {[self printErrorMessage: @"AudioUnitSetProperty (set Multichannel Mixer output sample rate)" withStatus: result]; return;}


//............................................................................
// Connect the nodes of the audio processing graph
	NSLog (@"Connecting nodes in audio processing graph");
    // Connect the output of the input bus of the I/O unit to the Multichannel Mixer unit input.
	result =	AUGraphConnectNodeInput (
					processingGraph,
					ioNode,				// source node
					1,					// source node bus number
					mixerNode,			// destination node
					0					// destintaion node bus number
				);

	if (result) {[self printErrorMessage: @"AUGraphConnectNodeInput - I/O unit to Multichannel Mixer unit" withStatus: result]; return;}

    // Connect the output of the mixer unit to the input of the output bus of the I/O unit.
	result =	AUGraphConnectNodeInput (
					processingGraph,
					mixerNode,			// source node
					0,					// source node bus number
					ioNode,				// destination node
					0					// destination node bus number
				);

	if (result) {[self printErrorMessage: @"AUGraphConnectNodeInput - Multichannel Mixer unit to I/O unit" withStatus: result]; return;}

	
//............................................................................
// Initialize audio processing graph

/*
// Diagnostic code

	// Call CAShow if you want to look at the state of the audio processing 
	//	graph.
	NSLog (@"Audio processing graph state immediately before initializing it:");
	CAShow (processingGraph);
*/
    NSLog (@"Initializing the audio processing graph\n");
    // Initialize the audio processing graph, configure audio data stream formats that were previously
	//	specified, and validate the connections between audio units.
	result = AUGraphInitialize (processingGraph);
	
	if (result) {[self printErrorMessage: @"AUGraphInitialize" withStatus: result]; return;}
}

#pragma mark -
#pragma mark Audio Processing Graph Control

- (void) startAUGraph  {

    NSLog (@"Starting audio processing graph");
	OSStatus result = AUGraphStart (processingGraph);

	if (result) {[self printErrorMessage: @"AUGraphStart" withStatus: result]; return;}
}


- (void) stopAUGraph {

	NSLog (@"Stopping audio processing graph");
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning (processingGraph, &isRunning);

	if (result) {[self printErrorMessage: @"AUGraphIsRunning" withStatus: result]; return;}
    
    if (isRunning) {
        result = AUGraphStop (processingGraph);
        if (result) {[self printErrorMessage: @"AUGraphStop" withStatus: result]; return;}
    }
}


#pragma mark -
#pragma mark Multichannel Mixer Unit Control

UInt32 mixerInputBus = 0;

// Set the stereo panning position
- (void) setMixerInputPanningPosition: (AudioUnitParameterValue) newPanningPosition {

	OSStatus result =	AudioUnitSetParameter (
							mixerUnit,
							kMultiChannelMixerParam_Pan,
							kAudioUnitScope_Input,
							mixerInputBus,
							newPanningPosition,
							0
						);

	if (result) {[self printErrorMessage: @"AudioUnitSetParameter (set Multichannel Mixer unit input panning position)" withStatus: result]; return;}
}


#pragma mark -
#pragma mark Audio Session Delegate Methods

- (void) beginInterruption {


	// Interruptions do not put an AUGraph object into a "stopped" state, so
	//	do that here.
	[self stopAUGraph];
}


- (void) endInterruption {

	NSError *endInterruptionError = nil;
	
	[[AVAudioSession sharedInstance] setActive: YES
										 error: &endInterruptionError];
	// In a shipping application, you should check here to ensure that input is still 
	//	available. You should also check here to see if the hardware sample rate 
	//	changed from its previous value by comparing it to graphSampleRate. If it did 
	//	change, reconfigure the ioInputStreamFormat struct to use the new sample rate, 
	//	and set the new stream format on the two audio units. (On the mixer, you just 
	//	need to change the sample rate.
	//
	// Then call AUGraphUpdate on the graph before starting it.
	
	[self startAUGraph];
}

// There's no need here to implement the beginInterruption delegate method,
//	because this sample project has no user interface representing the 
//	application state.


#pragma mark -
#pragma mark Utility Methods / Diagnostic Code

// You can use this method during development and debugging to look at the
//	fields of an AudioStreamBasicDescription struct.
- (void) printASBD: (AudioStreamBasicDescription) asbd {

	char formatIDString[5];
	UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
	bcopy (&formatID, formatIDString, 4);
	formatIDString[4] = '\0';
	
	NSLog (@"  Sample Rate:			%10.0f",	asbd.mSampleRate);
	NSLog (@"  Format ID:			%10s",		formatIDString);
	NSLog (@"  Format Flags:		%10X",		asbd.mFormatFlags);
	NSLog (@"  Bytes per Packet:	%10d",		asbd.mBytesPerPacket);
	NSLog (@"  Frames per Packet:	%10d",		asbd.mFramesPerPacket);
	NSLog (@"  Bytes per Frame:		%10d",		asbd.mBytesPerFrame);
	NSLog (@"  Channels per Frame:	%10d",		asbd.mChannelsPerFrame);
	NSLog (@"  Bits per Channel:	%10d",		asbd.mBitsPerChannel);
}



- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {

	char resultString[5];
	UInt32 swappedResult = CFSwapInt32HostToBig (result);
	bcopy (&swappedResult, resultString, 4);
	resultString[4] = '\0';

	NSLog (
		@"*** %@ error: %d %08X %4.4s\n",
				errorString,
				(int)		result,
				(unsigned)	result,
				(char*)		&resultString
	);
}


@end
