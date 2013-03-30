package hxa.flash.apps;

import flash.Lib;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.media.Microphone;
import flash.utils.Timer;
import flash.events.TimerEvent;
import util.Stopwatch;

import util.Sprintf;

import hxa.fft.FFTFilter;
import hxa.flash.widgets.Plotter;
import hxa.flash.sound.MicrophoneBuffer;

/**
 * Spectrum visualization app.
 * 
 * @author Gerald T. Beauregard (original AS3 code, see note in hxa.fft.FFT)
 * @author Konstantin Tretyakov (substantial rewrite in Haxe)
 */
class SpectrumViewer extends Sprite {
    // Data
    var statusMessage: String = ""; // Message (useful for debugging and other things)
    
    // UI & child elements
    var plotter: Plotter;
    var statusText: TextField;
    var mic: Microphone;
    var micBuffer: MicrophoneBuffer;
    var fftFilter: FFTFilter;
    var stopwatch: Stopwatch;
    
    // Config
    static inline var LOG_N = 11; // Log2 (FFT length);
    static inline var UPDATE_PERIOD = 50;
    static inline var SAMPLE_RATE = 5; // in K's.
    
    public function new() {
        super();
        plotter = new Plotter(500, 300);
        plotter.xaxis("Frequency (Hz)", 0, SAMPLE_RATE*1000/2, 500, "%0.0f");
        plotter.yaxis("dB", -60, 0, 10, "%0.0f");
        addChild(plotter);
        
        statusText = new TextField();
        statusText.x = 20;
        statusText.y = 400;
        statusText.text = "";
        statusText.autoSize = TextFieldAutoSize.LEFT;
        addChild(statusText);
        
        mic = Microphone.getMicrophone();
        mic.rate = SAMPLE_RATE;     // (only 5k, 8k, 11k, 22k and 44k are supported)
        mic.setSilenceLevel(0.0);   // Listen to everything
        micBuffer = new MicrophoneBuffer(1 << LOG_N, mic);

        fftFilter = new FFTFilter(micBuffer, SAMPLE_RATE*1000);
        stopwatch = new Stopwatch();
        
        // Start polling
        var timer = new Timer(UPDATE_PERIOD);
        timer.addEventListener(TimerEvent.TIMER, update);
        timer.start();
    }
    
    public function update(event) {
        stopwatch.tic();
        fftFilter.update();
        stopwatch.toc();
        
        plotter.plot(fftFilter.freqs, fftFilter.mag);
        if (stopwatch.averageTime >= 0)
            statusText.text = Sprintf.format("Average time per FFT: %0.3fms", [stopwatch.averageTime*1000]);
    }
    
	public static function main() {
        Lib.current.addChild(new SpectrumViewer());
	}    
}