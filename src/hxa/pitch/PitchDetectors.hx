package hxa.pitch;

import hxa.ds.CircularBuffer;
import hxa.fft.FFTFilter;

/**
 * The class collects the available pitch detectors in their "default" configurations for convenience.
 * Each static function creates one.
 */
class PitchDetectors{
    public static function createNaivePitchDetector(buffer: CircularBuffer<Float>, sampleRate: Int): IPitchProvider {
        var fftFilter = new FFTFilter(buffer, sampleRate);
        var pd = new NaivePitchDetector(fftFilter);
        return new MedianFilterPitchDetector(pd, 5);
    }
    
    public static function createDywaPitchDetector(buffer: CircularBuffer<Float>, sampleRate: Int): IPitchProvider {
        var pd = new DynamicWaveletPitchDetector(buffer, sampleRate);
        var pd2 = new DywaPitchTracker(pd);
        var pd3 = new MedianFilterPitchDetector(pd2, 5);
        return pd3;
    }
}