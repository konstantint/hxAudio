package hxa.ds;

/**
 * Cross-platform "Array.new".
 */
class HxaArrayUtil {
    public static inline function newArray<T>(len=0, fixed=false): HxaArray<T> {
        return new
            #if flash
                flash.Vector<T>(len, fixed)
            #else
                Array<T>()
            #end
        ;
    }
}