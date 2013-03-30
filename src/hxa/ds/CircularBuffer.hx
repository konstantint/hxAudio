package hxa.ds;

import hxa.ds.HxaArray;

/**
 * Circular buffer.
 * 
 * Example:
 *     var b = new CircularBuffer<Int>(3);
 *     b.writeValue(1);    // b.data == [1, 0*, 0], b.pos == 1
 *     b.writeValue(2);    // b.data == [1, 2, 0*], b.pos == 2
 *     b.writeValue(3);    // b.data == [1*, 2, 3], b.pos == 0
 *     b.writeValue(4);    // b.data == [4, 2*, 3], b.pos == 1
 *     b.copyToArray(a);   // a == [2, 3, 4]
 * 
 * @author Konstantin Tretyakov
 */
class CircularBuffer<ElementType>{
    public var length(default, null): Int;
    public var pos(default, null): Int = 0; // Next write position of the buffer. Also first read position.
    public var data(default, null): HxaArray<ElementType>;
    
    public function new(length: Int) {
        this.length = length;
        this.pos = 0;
        this.data = HxaArrayUtil.newArray(length, true);
    }
    
    /**
     * Appends a value to the buffer
     */
    inline public function writeValue(val: ElementType) {
        data[pos] = val;
        pos = (pos + 1) % length;
    }
    
    /**
     * Copies buffer to an array of the same length in correct order
     */
    inline public function copyToArray(arr: HxaArray<ElementType>) {
        var readPos = pos;
        for (i in 0...length) {
            arr[i] = data[readPos];
            readPos = (readPos + 1) % length;
        }
    }
}
