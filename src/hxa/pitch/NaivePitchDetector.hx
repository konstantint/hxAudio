package hxa.pitch;
import hxa.fft.FFTFilter;

/**
 * A very naive FFT-based pitch detector.
 * It assumes that all frequency components above a predefined cutoffLevel correspond to 
 * vocal pitch data. Consequently, the smallest frequency with power exceeding the cutoff
 * must correspond to the base pitch. 
 * 
 * Works quite well in quiet environments, however the cutoffLevel may be dependent
 * on the microphone, and it usually underestimates the actual pitch slightly.
 * Adding a median filter on top seems to improve overall tracking ability.
 * 
 * @author Konstantin Tretyakov
 */
class NaivePitchDetector implements IPitchProvider {
    var fftFilter: FFTFilter;
    public var cutoffLevel(default, default): Float;
    public var pitch(default, null): Float;
    
    public function new(fftFilter: FFTFilter, cutoffLevel: Float = -35.0) {
        this.fftFilter = fftFilter;
        this.cutoffLevel = cutoffLevel;
    }
    
    public function update() {
        fftFilter.update();
        
        // A very hackish pitch detection technique.
        pitch = 0.0;
        for (i in 0...fftFilter.mag.length) {
            if (fftFilter.mag[i] > cutoffLevel && fftFilter.freqs[i] > 60) {
                pitch = fftFilter.freqs[i];
                break;
            }
        }
    }
}
