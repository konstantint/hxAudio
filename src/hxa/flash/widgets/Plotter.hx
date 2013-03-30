package hxa.flash.widgets;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import util.Sprintf;
import hxa.ds.HxaArray;

/**
 * A simplistic "plotter" display.
 * 
 * Usage:
 *      plotter = new Plotter(500, 300);
 *      plotter.xaxis("x-axis", 0, 10, 1, "%0.0f");
 *      plotter.yaxis("y-axis", -5, 5, 1, "%0.0f");
 *      plotter.plot(xs, ys);
 *      addChild(plotter);
 * 
 * Despite the interface, it is not a real (x, y) curve plotter,
 * the xs must be sequentially increasing.
 * 
 * @author Gerard T. Bearegard (original AS3 code, reused partially in this version)
 * @author Konstantin Tretyakov
 */
class Plotter extends Sprite {
    
    // Display configuration
    public var viewportWidth(default, null): Int;
    public var viewportHeight(default, null): Int;
    public var left(default, null): Int;
    public var top(default, null): Int;
    public var tickSize(default, default): Int;
    
    public var xmin(default, null): Float;
    public var xmax(default, null): Float;
    public var xstep(default, null): Float;
    public var xformat(default, null): String;
    
    public var ymin(default, null): Float;
    public var ymax(default, null): Float;
    public var ystep(default, null): Float;
    public var yformat(default, null): String;
    
    public var xlabel(get_xlabel, set_xlabel): String;
    public var ylabel(get_ylabel, set_ylabel): String;
    
    var ticks: Array<DisplayObject>;
    var xlabelField: TextField;
    var ylabelField: TextField;
    
    var xs: HxaArray<Float>;
    var ys: HxaArray<Float>;
    
    var xToPx: Float;
    var yToPx: Float;
    
    public function new(viewportWidth = 500, viewportHeight = 300) {
        super();
        this.viewportWidth = viewportWidth;
        this.viewportHeight = viewportHeight;
        left = 60; top = 50; tickSize = 10;
        
        // Axis labels
        ylabelField = new TextField();
        ylabelField.text = ylabel;
        ylabelField.x = left - 50;
        ylabelField.y = top + viewportHeight / 2 - ylabelField.textHeight / 2;
        ylabelField.height = 20;
        ylabelField.width = 50;
        addChild(ylabelField);

        xlabelField = new TextField();
        xlabelField.text = xlabel;
        xlabelField.width = 0;
        xlabelField.x = left + viewportWidth / 2;
        xlabelField.y = top + viewportHeight + 30;
        xlabelField.autoSize = TextFieldAutoSize.CENTER;
        addChild(xlabelField);
        
        ticks = new Array<DisplayObject>();
        xaxis();
        yaxis();       
    }
    
    public function xaxis(label: String = "x", min: Float = 0.0, max: Float = 1.0, step: Float = 0.1, format: String = "%0.1f") {
        xlabel = label;  xmin = min; xmax = max; xstep = step; xformat = format;
        xToPx = viewportWidth / (xmax - xmin);
        updateAxes();
    }
    public function yaxis(label: String = "y", min: Float = 0.0, max: Float = 1.0, step: Float = 0.1, format: String = "%0.1f") {
        ylabel = label;  ymin = min; ymax = max; ystep = step; yformat = format;
        yToPx = viewportHeight / (ymax - ymin); 
        updateAxes();
    }
    function set_xlabel(label: String) return (xlabelField.text = label)
    function get_xlabel(): String return xlabelField.text
    function set_ylabel(label: String) return (ylabelField.text = label)
    function get_ylabel(): String return ylabelField.text
    
    /**
     * Update the display with new x-y data.
     * The display actually assumes that x values are incrementally increasing, i.e. you can't draw arbitrary curves.
     */
    public function plot(xs: HxaArray<Float>, ys: HxaArray<Float>) {
        if (xs.length != ys.length) trace("X and Y lengths must match!");
        else {
            this.xs = xs; this.ys = ys;
            updateData();
        }
    }
        
    function updateAxes() {
        for (i in 0...ticks.length) removeChild(ticks[i]);
        ticks = new Array<DisplayObject>();
        
        for (xtick in tickiter(xmin, xmax, xstep)) {
            var x = left + xToPx * (xtick - xmin);
            var t = new TextField();
            t.text = Sprintf.format(xformat, [xtick]);
            t.width = 0;
            t.height = 20;
            t.x = x;
            t.y = top + viewportHeight + 7;
            t.autoSize = TextFieldAutoSize.CENTER;
            addChild(t);
            ticks.push(t);
        }
        
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
    }
    
    function updateData() {
        var bottom = top + viewportHeight;
        graphics.clear();
        
        // Draw a rectangular box marking the boundaries of the graph
        graphics.lineStyle( 1, 0x000000 );
        graphics.drawRect(left, top, viewportWidth, viewportHeight);

        // Tick marks
        for (ytick in tickiter(ymin, ymax, ystep)) {
            var y = bottom - yToPx * (ytick - ymin);
            graphics.moveTo(left - tickSize / 2, y);
            graphics.lineTo(left + tickSize / 2, y);            
        }
        for (xtick in tickiter(xmin, xmax, xstep)) {
            var x = left + xToPx * (xtick - xmin);
            graphics.moveTo(x, bottom - tickSize / 2);
            graphics.lineTo(x, bottom + tickSize / 2);
        }
                
        // Plot line
        var first = true;
        for (i in 0...xs.length) {
            if (xs[i] < xmin || xs[i] > xmax) continue;
            var x = left + xToPx * (xs[i] - xmin);
            var y = bottom - yToPx * (ys[i] - ymin);
            if (y < top) y = top;
            else if (y > bottom) y = bottom;
            if (first) {
                graphics.moveTo(x, y);
                first = false;
            }
            else graphics.lineTo(x, y);
        }
    }
    
    inline static function tickiter(min, max, step) return new TickIter(min, max, step)
}

/**
 * for (i in new TickIter(0, 1, 0.1)) { ... }
 * will iterate over [0, 0.1, 0.2, ..., 1.0].
 */
class TickIter {
    var min: Float;
    var max: Float;
    var step: Float;
    var cur: Float;
    public function new(min, max, step) {
        this.min = this.cur = min; this.max = max; this.step = step;
    }
    inline public function hasNext() return cur <= max
    inline public function next() {
        var v = cur;
        cur += step;
        return v;
    }
}
