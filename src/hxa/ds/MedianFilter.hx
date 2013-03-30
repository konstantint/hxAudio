package hxa.ds;

/**
 * Median filter. 
 * A median filter receives a stream of values as input, and is 
 * capable of reporting the median of /size/ most recent values.
 * 
 * The values are simply kept in a CircularBuffer and each time
 * output is requested, the buffer is sorted. This is not the most
 * efficient way to do, but works OK for small-size filters.
 * 
 * Example:
 *     var b = new MedianFilter<Int>(3, 0);
 *     b.writeValue(1);    // b.buffer.data == [1, 0*, 0], b.value == 0
 *     b.writeValue(2);    // b.buffer.data == [1, 2, 0*], b.value == 1
 *     b.writeValue(3);    // b.buffer.data == [1*, 2, 3], b.value == 1
 *     b.writeValue(4);    // b.buffer.data == [4, 2*, 3], b.value == 3
 * 
 * @author Konstantin Tretyakov
 */
class MedianFilter<ElementType> {
    var buffer: CircularBuffer<ElementType>;
    var bufferCopy:HxaArray<ElementType>;
    var middleIdx: Int;
    
    public var value(get_value, null): ElementType;
    
    public function new(size: Int = 5, defaultValue: ElementType) {
        buffer = new CircularBuffer<ElementType>(size);
        bufferCopy = HxaArrayUtil.newArray(size, true);
        middleIdx = size >> 1;
        for (i in 0...size) buffer.data[i] = defaultValue;        
    }
    
    public function update(nextValue: ElementType) {
        buffer.writeValue(nextValue);
    }
    
    public function get_value():ElementType {
        buffer.copyToArray(bufferCopy);
        #if flash
        bufferCopy.sort(untyped function(a, b) { return a < b; } );
        #else
        bufferCopy.sort();
        #end
        return bufferCopy[middleIdx];
    }
}
