package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.input.touch.FlxTouch;
import flixel.system.scaleModes.BaseScaleMode;
#if android
import lime.system.JNI;
#end

class ScreenUtil
{
	public static var swipe(default, never):SwipeUtil = new SwipeUtil();
	public static var touch(default, never):TouchUtil = new TouchUtil();
	public static var wideScreen(default, never):WideScreenMode = new WideScreenMode();
	#if android
	public static var jni(default, never):AndroidJNI = new AndroidJNI();

	public static inline function setOrientation(width:Int, height:Int, resizeable:Bool, hint:String):Dynamic
		return jni.setOrientation_jni(width, height, resizeable, hint);

	public static inline function getCurrentOrientationAsString():String
	{
		return switch (jni.getCurrentOrientation_jni())
		{
			case 1: "LandscapeRight"; //SDL_ORIENTATION_LANDSCAPE
			case 2: "LandscapeLeft"; //SDL_ORIENTATION_LANDSCAPE_FLIPPED
			case 3: "Portrait"; //SDL_ORIENTATION_PORTRAIT
			case 4: "PortraitUpsideDown"; //SDL_ORIENTATION_PORTRAIT_FLIPPED
			default: "Unknown";
		}
	}

	public static inline function isScreenKeyboardShown():Dynamic
		return jni.isScreenKeyboardShown_jni();

	public static inline function clipboardHasText():Dynamic
		return jni.clipboardHasText_jni();

	public static inline function clipboardGetText():Dynamic
		return jni.clipboardGetText_jni();

	public static inline function clipboardSetText(string:String):Dynamic
		return jni.clipboardSetText_jni(string);

	public static inline function manualBackButton():Dynamic
		return jni.manualBackButton_jni();

	public static inline function setActivityTitle(title:String):Dynamic
		return jni.setActivityTitle_jni(title);
	#end
}

class WideScreenMode extends BaseScaleMode
{
	public var enabled(default, set):Bool = false;
	public static var _enabled:Bool = false;

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		if(_enabled)
		{
			super.updateGameSize(Width, Height);
		}
		else
		{
			var ratio:Float = FlxG.width / FlxG.height;
			var realRatio:Float = Width / Height;
	
			var scaleY:Bool = realRatio < ratio;
	
			if (scaleY)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}
	}

	override function updateGamePosition():Void
	{
		if(_enabled)
			FlxG.game.x = FlxG.game.y = 0;
		else
			super.updateGamePosition();
	}

	@:noCompletion
	private function set_enabled(value:Bool):Bool
	{
		enabled = value;
		_enabled = value;
		FlxG.scaleMode = new WideScreenMode();
		return value;
	}
}


#if android
class AndroidJNI #if (lime >= "8.0.0") implements JNISafety #end
{
	public function new() {}

	@:noCompletion public var setOrientation_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setOrientation',
		'(IIZLjava/lang/String;)V');
	@:noCompletion public var getCurrentOrientation_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'getCurrentOrientation', '()I');
	@:noCompletion public var isScreenKeyboardShown_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'isScreenKeyboardShown', '()Z');
	@:noCompletion public var clipboardHasText_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardHasText', '()Z');
	@:noCompletion public var clipboardGetText_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardGetText',
		'()Ljava/lang/String;');
	@:noCompletion public var clipboardSetText_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardSetText',
		'(Ljava/lang/String;)V');
	@:noCompletion public var manualBackButton_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'manualBackButton', '()V');
	@:noCompletion public var setActivityTitle_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setActivityTitle',
		'(Ljava/lang/String;)Z');
}
#end

class TouchUtil {
	public function new() {}

	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;
	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var instance(get, never):FlxTouch;

	public function overlaps(object:FlxObject, ?camera:FlxCamera):Bool {
		for (touch in FlxG.touches.list)
			if (touch.overlaps(object, camera ?? object.camera))
				return true;

		return false;
	}

	public function overlapsComplex(object:FlxObject, ?camera:FlxCamera):Bool {
		if (camera == null)
			for (camera in object.cameras)
				for (touch in FlxG.touches.list)
					@:privateAccess
					if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera))
						return true;
					else
						@:privateAccess
						if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera))
							return true;

		return false;
	}

	/**
	 * Touch checker for `spr`, then runs `onTouch` function
	 * @param spr	   Sprite that will be checked
	 * @param onTouch   Function that will be runned if Touch = true
	 */
	public function overlapsUltraComplex(spr:FlxSprite, onTouch:Void -> Void) {
		if (instance != null)
		{
			var sprPos = spr.getScreenPosition(spr.camera);
			#if (flixel < "5.9.0")
			var touchX = instance.screenX;
			var touchY = instance.screenY;
			#else
			var touchX = instance.viewX;
			var touchY = instance.viewY;
			#end
			var overlap:Bool = (touchX >= sprPos.x && touchX <= sprPos.x + spr.frameWidth
			&& touchY >= sprPos.y && touchY <= sprPos.y + spr.frameHeight);
			if (overlap && instance.justPressed)
				onTouch();
		}
	}

	@:noCompletion
	private function get_pressed():Bool {
		for (touch in FlxG.touches.list)
			if (touch.pressed)
				return true;

		return false;
	}

	@:noCompletion
	private function get_justPressed():Bool {
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				return true;

		return false;
	}

	@:noCompletion
	private function get_justReleased():Bool {
		for (touch in FlxG.touches.list)
			if (touch.justReleased)
				return true;

		return false;
	}

	@:noCompletion
	private function get_released():Bool {
		for (touch in FlxG.touches.list)
			if (touch.released)
				return true;

		return false;
	}

	@:noCompletion
	private function get_instance():FlxTouch {
		for (touch in FlxG.touches.list)
			if (touch != null)
				return touch;

		return FlxG.touches.getFirst();
	}
}

class SwipeUtil {
	public function new() {}

	@:noCompletion
	public function checkSwipe(minDegree:Float, maxDegree:Float):Bool {
		#if FLX_POINTER_INPUT
		for (swipe in FlxG.swipes) {
			if (swipe != null) {
				var degrees = swipe.degrees;
				if (degrees >= minDegree && degrees <= maxDegree && swipe.distance > 20) {
					return true;
				}
			}
		}
		#end
		return false;
	}

	public var UP(get, never):Bool;

	@:noCompletion
	private function get_UP():Bool {
		return checkSwipe(45, 135);
	}

	public var DOWN(get, never):Bool;

	@:noCompletion
	private function get_DOWN():Bool {
		return checkSwipe(-135, -45);
	}

	public var LEFT(get, never):Bool;

	@:noCompletion
	private function get_LEFT():Bool {
		return checkSwipe(135, 180) || checkSwipe(-180, -135);
	}

	public var RIGHT(get, never):Bool;

	@:noCompletion
	private function get_RIGHT():Bool {
		return checkSwipe(-45, 45);
	}
}