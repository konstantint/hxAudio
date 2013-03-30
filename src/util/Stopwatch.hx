package util;

import haxe.Timer;

/**
 * Simplistic stopwatch.
 * 
 * Usage:
 *    s = new Stopwatch();
 *    ...
 *    s.tic();
 *    <do something>
 *    s.toc();
 *    ...
 *    if (s.averageTime >= 0) trace(s.averageTime);  // After at least 20 tic-toc iterations.
 * 
 * @author Konstantin Tretyakov
 * @license MIT
 */
class Stopwatch {
    var N = 50; // Number of samples at which averaging resets.
    var totalTime: Float;
    var totalSamples: Int;
    var lastTic: Float;
    
    public var averageTime(get_averageTime, null): Float;
    public function new() {
        totalTime = 0;
        totalSamples = 0;
        averageTime = -1;
    }
    
    public function tic() {
        lastTic = Timer.stamp();
    }
    
    public function toc() {
        var dif = Timer.stamp() - lastTic;
        totalTime += dif;
        totalSamples += 1;
        if (totalSamples == N) {
            totalTime = totalTime / 2;
            totalSamples = totalSamples >> 1;
        }        
    }
    
    function get_averageTime(): Float {
        return totalTime / totalSamples;
    }
}