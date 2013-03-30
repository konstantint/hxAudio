package hxa.flash.apps;

import flash.Lib;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.media.Microphone;
import flash.utils.Timer;
import flash.events.TimerEvent;

import util.Sprintf;

import hxa.ds.HxaArray;
import hxa.fft.FFTFilter;
import hxa.pitch.PitchDetectors;
import hxa.pitch.IPitchProvider;
import hxa.flash.widgets.Spectroscope;
import hxa.flash.sound.MicrophoneBuffer;

/**
 * Spectroscope visualization.
 * 
 * @author Konstantin Tretyakov
 */
class SpectroscopeViewer extends Sprite {
    // Data
    var statusMessage: String = ""; // Message (e.g. current pitch)
    
    // UI & child elements
    var spectroscope: Spectroscope;
    var statusText: TextField;
    
    // Microphone, sound buffer and processors
    var mic: Microphone;
    var micBuffer: MicrophoneBuffer;
    var fftFilter: FFTFilter;
    var naive: IPitchProvider;
    var dywa: IPitchProvider;
    
    var dataLine: HxaArray<Float>;
    
    // Config
    static inline var LOG_N = 11; // Log2 (FFT length);
    static inline var UPDATE_PERIOD = 50;
    static inline var SAMPLE_RATE = 22050; // in Hz's. Allowed values: 44100, 22050, 11025, 8000, 5512.
    
    public function new() {
        super();
        spectroscope = new Spectroscope(500, 512);
        spectroscope.yaxis("Hz", 0, SAMPLE_RATE/2, 500, "%0.0f");
        addChild(spectroscope);
        
        dataLine = new HxaArray<Float>(512);
        
        statusText = new TextField();
        statusText.x = 20;
        statusText.y = 560;
        statusText.text = "";
        statusText.autoSize = TextFieldAutoSize.LEFT;
        addChild(statusText);
        
        mic = Microphone.getMicrophone();
        mic.rate = Math.floor(SAMPLE_RATE / 1000); 
        mic.setSilenceLevel(0.0);                   // Listen to everything
        micBuffer = new MicrophoneBuffer(1 << LOG_N, mic);

        fftFilter = new FFTFilter(micBuffer, SAMPLE_RATE);
        naive = PitchDetectors.createNaivePitchDetector(micBuffer, SAMPLE_RATE);
        dywa = PitchDetectors.createDywaPitchDetector(micBuffer, SAMPLE_RATE);
        
        // Start polling
        var timer = new Timer(UPDATE_PERIOD);
        timer.addEventListener(TimerEvent.TIMER, update);
        timer.start();
    }
    
    public function update(event) {
        fftFilter.update();
        naive.update();
        dywa.update();
        
        var k = 0;
        var minValue = 0.0;
        var maxValue = -1e100;
        var scaleDown = Math.floor(fftFilter.mag.length / dataLine.length);
        for (i in 0...dataLine.length) {
            dataLine[i] = 0;
            for (j in 0...scaleDown) {
                dataLine[i] += fftFilter.mag[k++];
            }
            dataLine[i] = dataLine[i] / scaleDown;
            if (dataLine[i] < minValue) minValue = dataLine[i];
            if (dataLine[i] > maxValue) maxValue = dataLine[i];
        }
        var range = maxValue - minValue;
        if (range == 0) range = 0.1;
        for (i in 0...dataLine.length) dataLine[i] = (dataLine[i] - minValue) / range;
        
        spectroscope.addLine(dataLine);
        spectroscope.markPoint(Math.floor(512 * naive.pitch / fftFilter.freqs[fftFilter.freqs.length - 1]), 0xff0000);
        spectroscope.markPoint(Math.floor(512 * dywa.pitch / fftFilter.freqs[fftFilter.freqs.length - 1]), 0x0000ff);
        
        statusText.text = Sprintf.format("Detected pitch: %0.3f Hz  %0.3f Hz", [naive.pitch, dywa.pitch]);
    }
    
	public static function main() {
        Lib.current.addChild(new SpectroscopeViewer());
	}    
}