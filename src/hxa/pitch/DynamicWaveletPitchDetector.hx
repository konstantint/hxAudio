package hxa.pitch;

import hxa.ds.CircularBuffer;
import hxa.ds.HxaArray;
import hxa.ds.HxaArray;
import hxa.ds.HxaArray;
import hxa.ds.HxaArrayUtil;

/**
 * A haxe port of a dynamic wavelet algorithm pitch tracking library.
 * Seems to work best with higher sampling rates (22 and 44KHz), 
 * at lower rates seems to fail.
 * 
 * @author Eric Larson and Ross Maddox (proposed the method in the article "Real-Time Time-Domain Pitch Tracking Using Wavelets")
 * @author Antoine Schmitt (original code in C, http://www.schmittmachine.com/dywapitchtrack.html)
 * @author Konstantin Tretyakov (Haxe port)
 * 
 * Verbatim MIT license text from the code by A. Schmitt:
 *
 * Dynamic Wavelet Algorithm Pitch Tracking library
 * Released under the MIT open source licence
 * 
 * Copyright (c) 2010 Antoine Schmitt
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
class DynamicWaveletPitchDetector implements IPitchProvider {
    public var pitch(default, null): Float;
    
    var buffer: CircularBuffer<Float>;    
    var scaleFactor: Float;
    
    // Data used in the "update" method.
    var data: HxaArray<Float>;
    var distances: HxaArray<Int>;
    var mins: HxaArray<Int>;
    var maxs: HxaArray<Int>;
    
    /**
     * buffer.length must be a power of 2.
     */
    public function new(buffer: CircularBuffer<Float>, sampleRate: Int) {
        this.buffer = buffer;
        // The algorithm below is implemented under the assumption of sampling frequency of 44100.
        // for other frequencies, we must simply rescale the result.
        this.scaleFactor = sampleRate / 44100.0;  
        data = HxaArrayUtil.newArray(buffer.length, true);
        distances = HxaArrayUtil.newArray(buffer.length, true);
        mins = HxaArrayUtil.newArray(buffer.length, true);
        maxs = HxaArrayUtil.newArray(buffer.length, true);
    }
    
    /**
     * Compute pitch from buffer data using the dynamic wavelet algorithm.
     */
    public function update() {
        var pitchF = 0.0;
	
        var i: Int, j: Int, si: Float, si1: Float;
	
        var samplecount = buffer.length; // Must be a power of 2
        var sam = data;
        buffer.copyToArray(sam);
        
        var curSamNb = samplecount;
        var nbMins: Int, nbMaxs: Int;

        // algorithm parameters
        var maxFLWTlevels = 6;
        var maxF = 3000.0;
        var differenceLevelsN = 3;
        var maximaThresholdRatio = 0.75;
	
        var ampltitudeThreshold: Float;
        var theDC = 0.0;
	
        { // compute ampltitudeThreshold and theDC
            //first compute the DC and maxAMplitude
            var maxValue = 0.0;
            var minValue = 0.0;
            for (i in 0...samplecount) {
                si = sam[i];
                theDC = theDC + si;
                if (si > maxValue) maxValue = si;
                if (si < minValue) minValue = si;
            }
            theDC = theDC/samplecount;
            maxValue = maxValue - theDC;
            minValue = minValue - theDC;
            var amplitudeMax = (maxValue > -minValue ? maxValue : -minValue);
            
            ampltitudeThreshold = amplitudeMax*maximaThresholdRatio;
            //asLog("dywapitch theDC=%f ampltitudeThreshold=%f\n", theDC, ampltitudeThreshold);
        }
	
        // levels, start without downsampling..
        var curLevel = 0;
        var curModeDistance = -1.0;
        var delta: Int;
	
        while(true) {
            
            // delta
            delta = Math.floor(44100. / (_2power(curLevel) * maxF));
            //("dywapitch doing level=%ld delta=%ld\n", curLevel, delta);
            
            if (curSamNb < 2) break;
            
            // compute the first maximums and minumums after zero-crossing
            // store if greater than the min threshold
            // and if at a greater distance than delta
            var dv: Float;
            var previousDV = -1000.0;
            nbMins = nbMaxs = 0;
            var lastMinIndex = -1000000;
            var lastmaxIndex = -1000000;
            var findMax = 0;
            var findMin = 0;
            for (i in 2...curSamNb) {
                si = sam[i] - theDC;
                si1 = sam[i-1] - theDC;
                
                if (si1 <= 0 && si > 0) findMax = 1;
                if (si1 >= 0 && si < 0) findMin = 1;
                
                // min or max ?
                dv = si - si1;
                
                if (previousDV > -1000) {
                    
                    if (findMin != 0 && previousDV < 0 && dv >= 0) { 
                        // minimum
                        if (Math.abs(si) >= ampltitudeThreshold) {
                            if (i > lastMinIndex + delta) {
                                mins[nbMins++] = i;
                                lastMinIndex = i;
                                findMin = 0;
                                //if DEBUGG then put "min ok"&&si
                                //
                            } else {
                                //if DEBUGG then put "min too close to previous"&&(i - lastMinIndex)
                                //
                            }
                        } else {
                            // if DEBUGG then put "min "&abs(si)&" < thresh = "&ampltitudeThreshold
                            //--
                        }
                    }
                    
                    if (findMax != 0 && previousDV > 0 && dv <= 0) {
                        // maximum
                        if (Math.abs(si) >= ampltitudeThreshold) {
                            if (i > lastmaxIndex + delta) {
                                maxs[nbMaxs++] = i;
                                lastmaxIndex = i;
                                findMax = 0;
                            } else {
                                //if DEBUGG then put "max too close to previous"&&(i - lastmaxIndex)
                                //--
                            }
                        } else {
                            //if DEBUGG then put "max "&abs(si)&" < thresh = "&ampltitudeThreshold
                            //--
                        }
                    }
                }
                
                previousDV = dv;
            }
            
            if (nbMins == 0 && nbMaxs == 0) {
                // no best distance !
                //asLog("dywapitch no mins nor maxs, exiting\n");
                
                // if DEBUGG then put "no mins nor maxs, exiting"
                break;
            }
            //if DEBUGG then put count(maxs)&&"maxs &"&&count(mins)&&"mins"
            
            // maxs = [5, 20, 100,...]
            // compute distances
            var d: Int;
            for (i in 0...distances.length) distances[i] = 0;            
            for (i in 0...nbMins) {
                for (j in 1...differenceLevelsN) {
                    if (i+j < nbMins) {
                        d = _iabs(mins[i] - mins[i+j]);
                        //asLog("dywapitch i=%ld j=%ld d=%ld\n", i, j, d);
                        distances[d] = distances[d] + 1;
                    }
                }
            }
            for (i in 0...nbMaxs) {
                for (j in 1...differenceLevelsN) {
                    if (i+j < nbMaxs) {
                        d = _iabs(maxs[i] - maxs[i+j]);
                        //asLog("dywapitch i=%ld j=%ld d=%ld\n", i, j, d);
                        distances[d] = distances[d] + 1;
                    }
                }
            }
            
            // find best summed distance
            var bestDistance = -1;
            var bestValue = -1;
            for (i in 0...curSamNb) {
                var summed = 0;
                for (j in (-delta)...(delta+1)) {
                    if (i+j >=0 && i+j < curSamNb)
                        summed += distances[i+j];
                }
                //asLog("dywapitch i=%ld summed=%ld bestDistance=%ld\n", i, summed, bestDistance);
                if (summed == bestValue) {
                    if (i == 2*bestDistance)
                        bestDistance = i;
                    
                } else if (summed > bestValue) {
                    bestValue = summed;
                    bestDistance = i;
                }
            }
            //asLog("dywapitch bestDistance=%ld\n", bestDistance);
            
            // averaging
            var distAvg = 0.0;
            var nbDists = 0.0;
            for (j in (-delta)...(delta+1)) {
                if (bestDistance+j >=0 && bestDistance+j < samplecount) {
                    var nbDist = distances[bestDistance+j];
                    if (nbDist > 0) {
                        nbDists += nbDist;
                        distAvg += (bestDistance+j)*nbDist;
                    }
                }
            }
            // this is our mode distance !
            distAvg /= nbDists;
            //asLog("dywapitch distAvg=%f\n", distAvg);
            
            // continue the levels ?
            if (curModeDistance > -1.) {
                var similarity = Math.abs(distAvg*2 - curModeDistance);
                if (similarity <= 2*delta) {
                    //if DEBUGG then put "similarity="&similarity&&"delta="&delta&&"ok"
                    //asLog("dywapitch similarity=%f OK !\n", similarity);
                    // two consecutive similar mode distances : ok !
                    pitchF = 44100./(_2power(curLevel-1)*curModeDistance);
                    break;
                }
                //if DEBUGG then put "similarity="&similarity&&"delta="&delta&&"not"
            }
            
            // not similar, continue next level
            curModeDistance = distAvg;
            
            curLevel = curLevel + 1;
            if (curLevel >= maxFLWTlevels) {
                // put "max levels reached, exiting"
                //asLog("dywapitch max levels reached, exiting\n");
                break;
            }
            
            // downsample
            if (curSamNb < 2) {
                //asLog("dywapitch not enough samples, exiting\n");
                break;
            }
            for (i in 0...(curSamNb>>1)) {
                sam[i] = (sam[2*i] + sam[2*i + 1])/2.;
            }
            curSamNb >>= 1;
        }

        this.pitch = pitchF * this.scaleFactor;
    }
    
    // 2 power (NB: could be made faster)
    inline function _2power(i: Int): Int {
        var res = 1;
        for (j in 0...i) res <<= 1;
        return res;
    }
    
    // abs value
    inline function _iabs(x: Int): Int {
        return (x >= 0) ? x : -x;
    }    
}