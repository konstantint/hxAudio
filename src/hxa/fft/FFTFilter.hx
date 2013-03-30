package hxa.fft;

import hxa.ds.CircularBuffer;
import hxa.ds.HxaArray;
import hxa.ds.HxaArrayUtil;

/**
 * A "filter"-interface for applying FFT.
 * 
 * Keeps a reference to a circular buffer of samples,
 * each time "update()" is invoked, a FFT of the buffer is performed
 * and the public array mag keeps the frequency magnitudes.
 * 
 * The length of the circular buffer must be a power of 2.
 * 
 * Example:
 *     f = new FFTFilter(buffer, 44100);
 *     ... (fill buffer with sound data) ...
 *     f.update();
 *     .... now f.mag contains frequency magnitudes ...
 * 
 * This is a (substantially modified) rewrite of AS3 code by Gerald T. Beauregard (see note in FFT.hx)
 * 
 * @author Konstantin Tretyakov
 */
class FFTFilter {
    var buffer: CircularBuffer<Float>;
    var win: HxaArray<Float>;   // Window to premultiply the array with
    var re: HxaArray<Float>;
    var im: HxaArray<Float>;
    var fft: FFT;
    var useWindow: Bool;        // Whether the window function is used during FFT
    var doLogScaling: Bool;     // Whether the resulting magnitudes are rescaled to decibels
    inline public static var SCALE = 20.0 / Math.log(10);   // 20 log10(mag) => 20/ln(10) ln(mag)
    

    public var sampleRate(default, null): Int;
    public var mag(default, null): HxaArray<Float>;   // Magnitudes (array half the size)
    public var freqs(default, null): HxaArray<Float>; // Corresponding frequencies.

    /**
     * Creates a new FFT filter.
     * 
     * @param buffer The circular buffer which acts as the source of data. Buffer length must be a power of 2.
     * @param sampleRate The sample rate of sound in the buffer.
     * @param useWindow  Whether Hann window is applied to data in the buffer before FFT.
     * @param doLogScaling When false, mag array contains raw magnitudes. When true, the output is 20*log10(mag).
     */
    public function new(buffer: CircularBuffer<Float>, sampleRate: Int, useWindow: Bool=true, doLogScaling: Bool=true) {
        this.buffer = buffer;
        this.sampleRate = sampleRate;
        this.useWindow = useWindow;
        this.doLogScaling = doLogScaling;
        this.re = HxaArrayUtil.newArray(buffer.length, true);
        this.im = HxaArrayUtil.newArray(buffer.length, true);
        this.fft = new FFT();
        fft.init(Math.round(Math.log(buffer.length) / Math.log(2)));
        
        // Hanning window
        this.win = HxaArrayUtil.newArray(buffer.length, true);
        for (i in 0...win.length) win[i] = (4.0 / win.length) * 0.5 * (1 - Math.cos(2 * Math.PI * i / win.length));
        
        // Only need to keep half of the magnitudes (the FT is symmetric)
        this.mag = HxaArrayUtil.newArray(buffer.length >> 1, true);
        this.freqs = HxaArrayUtil.newArray(buffer.length >> 1, true);
        for (i in 0...freqs.length) freqs[i] = i * sampleRate / buffer.length;
    }
    
    public function update() {
        // Copy the signal to real component
        var pos = buffer.pos;
        if (useWindow) {
            for (i in 0...buffer.length) {
                re[i] = win[i] * buffer.data[pos];
                pos = (pos + 1) % buffer.length;
            }
        }
        else buffer.copyToArray(re);
        
        // Zero the imaginary part
        for (i in 0...im.length) im[i] = 0.0;
        
        // Do FFT and compute magnitude spectrum
        fft.run(re, im);        
        for (i in 0...mag.length)
            mag[i] = Math.sqrt(re[i] * re[i] + im[i] * im[i]);
        
        // Convert to dB magnitude
        if (doLogScaling)
            for (i in 0...mag.length) {
                mag[i] = SCALE * Math.log(mag[i] + 1e-100);
        }
    }
    
}