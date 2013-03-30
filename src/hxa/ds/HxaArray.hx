package hxa.ds;

/**
 * Multiplatform 'Array' definition.
 */
#if flash
typedef HxaArray<T> = flash.Vector<T>;
#else
typedef HxaArray<T> = Array<T>;
#end
