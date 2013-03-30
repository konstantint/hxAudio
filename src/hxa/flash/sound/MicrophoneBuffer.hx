package hxa.flash.sound;

import flash.events.SampleDataEvent;
import flash.media.Microphone;
import hxa.ds.CircularBuffer;

/**
 * A subclass of CircularBuffer that can be easily attached to a
 * Microphone object for automatic data collection.
 * 
 * @author Konstantin Tretyakov
 */
class MicrophoneBuffer extends CircularBuffer<Float> {
    var microphone: Microphone;
    
    public function new(size: Int, microphone: Microphone = null) {
        super(size);
        if (microphone != null) attachMicrophone(microphone);
    }
    
    private function onMicrophoneSampleData(event:SampleDataEvent) {
        var len = Math.floor(event.data.length / 4);
        for (i in 0...len) writeValue(event.data.readFloat());
    }
    
    public function attachMicrophone(microphone: Microphone) {
        microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, this.onMicrophoneSampleData);
    }
}
