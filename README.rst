================================
Pitch detection and FFT in Haxe
================================

This is a small Haxe library I hacked up from various MIT-licensed pieces
while hectically trying to implement pitch detection for a `tiny weekend project <http://rrracer.com>`_.

There does not seem to be too much of useful pitch detection (and sound processing in general) cross-platform code
lying around, hence this might hopefully be of use to someone. I have only tested this with flash, although in principle
the core algorithms should all be cross-compilable to any Haxe-supported language.

Usage
-----
There's not too much documentation, but there are some examples which might help. 
To build, open hxAudio.hxproj in FlashDevelop and hit "build". 
Alternatively, you can compile the code with haxe from the command line:

    $ haxe compile.hxml

As a result, several example swf files will be created in the bin/ directory. 


Credits
-------
Copyright (C) 2013, Konstantin Tretyakov.

The project is largely based on the work by:
* Gerald T. Beauregard (http://gerrybeauregard.wordpress.com/2010/08/03/an-even-faster-as3-fft/)
* Rigondo (http://rigondo.wordpress.com/2011/08/18/9/)
* Antoine Schmitt (http://www.schmittmachine.com/dywapitchtrack.html)
* Nate Cook & the Caffeine-hx project.
(see remarks in the corresponding source files)

The code is MIT-licensed, except for `util/Sprintf.hx`.

