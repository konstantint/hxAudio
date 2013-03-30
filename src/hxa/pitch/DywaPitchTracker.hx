package hxa.pitch;

/**
 * A tracker filter to be used on top of DynamicWaveletPitchDetector.
 * 
 * @author Antoine Schmitt (see note in DynamicWaveletPitchDetector.hx)
 * @author Konstantin Tretyakov (Haxe port)
 */
class DywaPitchTracker implements IPitchProvider {
    public var pitch(default, null): Float;
    public var pd: IPitchProvider;
    
    var _prevPitch: Float;
    var _pitchConfidence: Int;
    
    public function new(pitchProvider: IPitchProvider) {
        this.pd = pitchProvider;
        _prevPitch = 0.0;
        _pitchConfidence = -1;
    }
    
    public function update() {
        pd.update();
        
        pitch = pd.pitch;
        if (pitch == 0.0) pitch = -1.0;

        var estimatedPitch = -1.0;
        var acceptedError = 0.2;
        var maxConfidence = 5;
	
        if (pitch != 0.0) {
            // I have a pitch here
		
            if (_prevPitch == -1) {
                // no previous
                estimatedPitch = pitch;
                _prevPitch = pitch;
                _pitchConfidence = 1;
                
            } else if (Math.abs(_prevPitch - pitch)/pitch < acceptedError) {
                // similar : remember and increment pitch
                _prevPitch = pitch;
                estimatedPitch = pitch;
                _pitchConfidence = min(maxConfidence, _pitchConfidence + 1); // maximum 3
                
            } else if ((_pitchConfidence >= maxConfidence-2) && Math.abs(_prevPitch - 2.*pitch)/(2.*pitch) < acceptedError) {
                // close to half the last pitch, which is trusted
                estimatedPitch = 2.*pitch;
                _prevPitch = estimatedPitch;
                
            } else if ((_pitchConfidence >= maxConfidence-2) && Math.abs(_prevPitch - 0.5*pitch)/(0.5*pitch) < acceptedError) {
                // close to twice the last pitch, which is trusted
                estimatedPitch = 0.5*pitch;
                _prevPitch = estimatedPitch;
                
            } else {
                // nothing like this : very different value
                if (_pitchConfidence >= 1) {
                    // previous trusted : keep previous
                    estimatedPitch = _prevPitch;
                    _pitchConfidence = max(0, _pitchConfidence - 1);
                } else {
                    // previous not trusted : take current
                    estimatedPitch = pitch;
                    _prevPitch = pitch;
                    _pitchConfidence = 1;
                }
            }
            
        } else {
            // no pitch now
            if (_prevPitch != -1) {
                // was pitch before
                if (_pitchConfidence >= 1) {
                    // continue previous
                    estimatedPitch = _prevPitch;
                    _pitchConfidence = max(0, _pitchConfidence - 1);
                } else {
                    _prevPitch = -1;
                    estimatedPitch = -1.;
                    _pitchConfidence = 0;
                }
            }
        }
	
        // put "_pitchConfidence="&pitchtracker->_pitchConfidence
        if (_pitchConfidence >= 1) {
            // ok
            pitch = estimatedPitch;
        } else {
            pitch = -1;
        }
	
        // equivalence
        if (pitch == -1) pitch = 0.0;
    }
    
    
    inline function min(a, b) {
        return a < b ? a : b;
    }
    
    inline function max(a, b) {
        return a < b ? b : a;
    }
}