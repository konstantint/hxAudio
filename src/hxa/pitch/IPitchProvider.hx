package hxa.pitch;

/**
 * Generic interface for a pitch-tracking filter object.
 * The method "update()" should invoke the computation on 
 * the most recent data, and the variable pitch should provide the
 * computed pitch value.
 * 
 * @author Konstantin Tretyakov
 */
interface IPitchProvider {
    var pitch(default, null): Float;
    function update(): Void;
}
