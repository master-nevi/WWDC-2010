Read Me About Wavy
========================
1.0

Wavy plots the waveform of audio captured using the AVFoundation capture
classes. It implements a data output sample buffer delegate to gain access to
each captured audio sample.

Wavy runs on iPhone OS 4.0 and later devices.

Using the Sample
----------------
To test the sample, just run it and the waveform of any audio captured through
the microphone is displayed on the screen.  The app registers as a "Play audio
in the background" app, so if you start the session and then press the Home button
to exit the app, you'll see a double-height red status bar indicating that Wavy
is still running the audio device in the background.

Building the Sample
-------------------
The sample was built using Xcode 3.2.3 on Mac OS X 10.6.3 with the Mac OS X
10.6 SDK.  You should be able to just open the project and choose Build from the
Build menu.

Credits and Version History
---------------------------
If you find any problems with this sample, please file a bug against it.

<http://developer.apple.com/bugreporter/>

1.0 (June 2010) was the first shipping version.