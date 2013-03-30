package hxa.pitch;

import hxa.ds.MedianFilter;

/**
 * Takes any IPitchDetector and applies median filtering
 * to obtain smooth results.
 * 
 * @author Konstantin Tretyakov
 */
class MedianFilterPitchDetector implements IPitchProvider{
    var pd: IPitchProvider;
    var medianFilter: MedianFilter<Float>;
    
    public var pitch(default, null): Float;
    
    public function new(pd: IPitchProvider, filterSize:Int = 5) {
        this.pd = pd;
        this.medianFilter = new MedianFilter<Float>(filterSize, 0.0);
    }
    
    public function update() {
        pd.update();
        medianFilter.update(pd.pitch);
        pitch = medianFilter.value;
    }
}