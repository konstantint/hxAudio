package hxa.flash.widgets;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.BitmapData;
import flash.display.Bitmap;

import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import util.Sprintf;
import hxa.ds.HxaArray;

/**
 * A "running spectroscope" display.
 * 
 * Usage:
 *      spectroscope = new Spectroscope(500, 512);
 *      spectroscope.yaxis("Hz", 0, SAMPLE_RATE*1000/2, 500, "%0.0f");
 *      addChild(spectroscope);
 * 
 *      ... later on in a timer event ...
 *      dataLine = new HxaArray<Float>(512);   // Must be same size as the Spectroscope's viewportHeight
 *      ... prepare data ...                   // dataLine must contain values between 0 and 1.
 *      spectroscope.addLine(dataLine);        // Adds a vertical line of pixels to the current position on the spectroscope (line visualized bottom-up)
 *      spectroscope.markPoint(x, 0xff0000);   // Modifies x-th pixel from below on the currently added line.
 *  
 * @author Konstantin Tretyakov
 */
class Spectroscope extends Sprite {
    
    // Display configuration
    public var viewportWidth(default, null): UInt;
    public var viewportHeight(default, null): UInt;
    public var left(default, null): Int;
    public var top(default, null): Int;
    public var tickSize(default, default): Int;
        
    public var ymin(default, null): Float;
    public var ymax(default, null): Float;
    public var ystep(default, null): Float;
    public var yformat(default, null): String;
    
    public var ylabel(get_ylabel, set_ylabel): String;
    
    var bitmap: Bitmap;
    var curColumn: UInt;
    
    var ticks: Array<DisplayObject>;
    var ylabelField: TextField;
    
    var ys: HxaArray<Float>;
    
    var yToPx: Float;
    
    public function new(viewportWidth = 500, viewportHeight = 512) {
        super();
        this.viewportWidth = viewportWidth;
        this.viewportHeight = viewportHeight;
        left = 60; top = 20; tickSize = 10;
        
        // Bitmap to be drawn
        var bitmapData = new BitmapData(viewportWidth, viewportHeight, true);
        bitmap = new Bitmap(bitmapData);
        curColumn = 0;
        bitmap.x = left + 1;
        bitmap.y = top + 1;
        addChild(bitmap);
        
        // Axis labels
        ylabelField = new TextField();
        ylabelField.text = ylabel;
        ylabelField.x = left - 50;
        ylabelField.y = top + viewportHeight / 2 - ylabelField.textHeight / 2;
        ylabelField.height = 20;
        ylabelField.width = 50;
        addChild(ylabelField);
        
        ticks = new Array<DisplayObject>();
        yaxis();       
    }
    
    public function yaxis(label: String = "y", min: Float = 0.0, max: Float = 1.0, step: Float = 0.1, format: String = "%0.1f") {
        ylabel = label;  ymin = min; ymax = max; ystep = step; yformat = format;
        yToPx = viewportHeight / (ymax - ymin); 
        updateAxes();
    }
    function set_ylabel(label: String) return (ylabelField.text = label)
    function get_ylabel(): String return ylabelField.text
    
    /**
     * Update the display with new x-y data.
     * The display actually assumes that x values are incrementally increasing, i.e. you can't draw arbitrary curves.
     */
    public function addLine(ys: HxaArray<Float>) {
        if (ys.length != viewportHeight) trace("Length of Y must match viewport height!");
        else {
            for (i in 0...viewportHeight) {
                bitmap.bitmapData.setPixel(curColumn, viewportHeight-i, rgb(1-ys[i], 1-ys[i], 1-ys[i]));
            }
            var nextColumn = (curColumn + 1) % viewportWidth;
            for (i in 0...viewportHeight) bitmap.bitmapData.setPixel(nextColumn, i, 0xffffff);
            curColumn = (curColumn + 1) % viewportWidth;
        }
    }
    
    public function markPoint(point: Int, color: UInt = 0xff0000) {
        var prevColumn = curColumn - 1;
        if (prevColumn < 0) prevColumn = viewportWidth - 1;
        bitmap.bitmapData.setPixel(prevColumn, viewportHeight - point, color);
    }
    
    function updateAxes() {
        for (i in 0...ticks.length) removeChild(ticks[i]);
        ticks = new Array<DisplayObject>();
        
        for (ytick in tickiter(ymin, ymax, ystep)) {
            var y = top + viewportHeight - yToPx * (ytick - ymin);
            var t = new TextField();
            t.text = Sprintf.format(yformat, [ytick]);
            t.width = 0;
            t.height = 20;
            t.x = left - 2;
            t.y = y - t.textHeight / 2;
            t.autoSize = TextFieldAutoSize.RIGHT;
            addChild(t);
            ticks.push(t);
        }
        
        // Draw bounding box
        var bottom = top + viewportHeight;
        graphics.clear();
        
        // Draw a rectangular box marking the boundaries of the graph
        graphics.lineStyle( 1, 0x000000 );
        graphics.drawRect(left, top, viewportWidth + 2, viewportHeight + 2);
        
        // Tick marks
        for (ytick in tickiter(ymin, ymax, ystep)) {
            var y = bottom - yToPx * (ytick - ymin);
            graphics.moveTo(left - tickSize / 2, y);
            graphics.lineTo(left, y);            
        }
    }
    
    inline static function tickiter(min, max, step) return new TickIter(min, max, step)
    
    function rgb(r: Float, g: Float, b: Float): UInt {
        return Math.floor(255*r) << 16 | Math.floor(255*g) << 8 | Math.floor(255*b);
    }
}


class TickIter {
    var min: Float;
    var max: Float;
    var step: Float;
    var cur: Float;
    public function new(min, max, step) {
        this.min = this.cur = min; this.max = max; this.step = step;
    }
    public function hasNext() return cur <= max
    public function next() {
        var v = cur;
        cur += step;
        return v;
    }
}
