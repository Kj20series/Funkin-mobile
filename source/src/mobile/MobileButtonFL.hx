package mobile;

import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

class MobileButtonEvent {
	public var callback:Void->Void;
	public function new(?Callback:Void->Void) { callback = Callback; }
	public inline function fire():Void { if (callback != null) callback(); }
	public inline function destroy():Void { callback = null; }
}

/**
 * Pure OpenFL version of MobileButton with multi-touch support.
 */
class MobileButtonFL extends Sprite {
	public static inline var NORMAL:Int = 0;
	public static inline var PRESSED:Int = 1;

	public var tag:String;
	public var buttonName:String;
	public var returnedKey:String;
	public var IDs:Array<String> = [];
	public var uniqueID:Int;

	public var onUp(default, null):MobileButtonEvent;
	public var onDown(default, null):MobileButtonEvent;
	public var onOver(default, null):MobileButtonEvent;
	public var onOut(default, null):MobileButtonEvent;

	public var status(default, set):Int = NORMAL;

	public var statusAlphas:Array<Float> = [1.0, 0.6]; 

	public var bitmap:Bitmap;
	private var frames:Array<BitmapData> = [];
	private var currentTouchID:Int = -1; // Prevents other fingers from releasing this button

	public function new(X:Float = 0, Y:Float = 0, ?returned:String):Void {
		super();
		this.x = X;
		this.y = Y;

		if (returned != null && returned != '') returnedKey = returned;

		bitmap = new Bitmap();
		bitmap.smoothing = true;
		addChild(bitmap);

		onUp = new MobileButtonEvent();
		onDown = new MobileButtonEvent();
		onOver = new MobileButtonEvent();
		onOut = new MobileButtonEvent();

		this.buttonMode = true;
		this.mouseChildren = false;

		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

		addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
		addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);

		addEventListener(TouchEvent.TOUCH_BEGIN, handleTouchDown);
		addEventListener(TouchEvent.TOUCH_END, handleTouchUp);
		addEventListener(TouchEvent.TOUCH_OUT, handleTouchOut);
	}

	public function setFrames(bmd:BitmapData):Void {
		frames = [];
		var frameWidth:Int = Std.int(bmd.width / 2);
		var frameHeight:Int = bmd.height;

		var normalData = new BitmapData(frameWidth, frameHeight, true, 0x00000000);
		normalData.copyPixels(bmd, new Rectangle(0, 0, frameWidth, frameHeight), new Point(0, 0));
		frames.push(normalData);

		var pressedData = new BitmapData(frameWidth, frameHeight, true, 0x00000000);
		pressedData.copyPixels(bmd, new Rectangle(frameWidth, 0, frameWidth, frameHeight), new Point(0, 0));
		frames.push(pressedData);

		updateGraphic();
	}

	public function setGraphicScale(multiplier:Float):Void {
		if (bitmap != null) {
			bitmap.scaleX = multiplier;
			bitmap.scaleY = multiplier;
		}
	}

	private function handleTouchDown(e:TouchEvent):Void {
		if (status == NORMAL) {
			currentTouchID = e.touchPointID;
			status = PRESSED;
			onDown.fire();
		}
	}

	private function handleTouchUp(e:TouchEvent):Void {
		if (status == PRESSED && e.touchPointID == currentTouchID) {
			currentTouchID = -1;
			status = NORMAL;
			onUp.fire();
		}
	}

	private function handleTouchOut(e:TouchEvent):Void {
		if (status == PRESSED && e.touchPointID == currentTouchID) {
			currentTouchID = -1;
			status = NORMAL;
			onOut.fire();
		}
	}

	private function handleMouseDown(e:MouseEvent):Void {
		if (status == NORMAL) {
			status = PRESSED;
			onDown.fire();
		}
	}

	private function handleMouseUp(e:MouseEvent):Void {
		if (status == PRESSED) {
			status = NORMAL;
			onUp.fire();
		}
	}

	private function handleMouseOut(e:MouseEvent):Void {
		if (status == PRESSED) {
			status = NORMAL;
			onOut.fire();
		}
	}

	private function set_status(val:Int):Int {
		status = val;
		updateGraphic();
		return val;
	}

	private function updateGraphic():Void {
		if (frames.length == 0) return;
		var frameIndex = (status == PRESSED && frames.length > 1) ? 1 : 0;
		bitmap.bitmapData = frames[frameIndex];

		this.alpha = statusAlphas[frameIndex];
	}

	public function destroy():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
		removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
		removeEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);

		removeEventListener(TouchEvent.TOUCH_BEGIN, handleTouchDown);
		removeEventListener(TouchEvent.TOUCH_END, handleTouchUp);
		removeEventListener(TouchEvent.TOUCH_OUT, handleTouchOut);

		onUp.destroy();
		onDown.destroy();
		onOver.destroy();
		onOut.destroy();

		for (bmd in frames) bmd.dispose();
		frames = [];
		if (bitmap.bitmapData != null) bitmap.bitmapData.dispose();
	}
}
