package mobile;

import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.atlas.FlxNode;
import flixel.graphics.frames.FlxTileFrames;
import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
#if mobile_controls_allow_mouse_clicks
import flixel.input.mouse.FlxMouseButton;
#end
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end

/**
 * A simplified version of TouchButton.
 * Do not touch if you don't know what are you doing.
 * @author KralOyuncu2010x
 */
class MobileButton extends TypedMobileButton<FlxSprite>
{
	public static inline var NORMAL:Int = 0;
	public static inline var HIGHLIGHT:Int = 1;
	public static inline var PRESSED:Int = 2;

	public var tag:String;
	public var name:String;
	public var returnedKey:String;
	public var IDs:Array<String> = [];
	public var uniqueID:Int;

	@:isVar public var bounds(get, set):FlxSprite;

	public function new(X:Float = 0, Y:Float = 0, ?returned:String):Void
	{
		super(X, Y);
		if (returned != null && returned != '') returnedKey = returned;
	}

	public inline function centerInBounds()
	{
		setPosition(bounds.x + ((bounds.width - frameWidth) * 0.5), bounds.y + ((bounds.height - frameHeight) * 0.5));
	}

	public inline function centerBounds()
	{
		bounds.setPosition(x + ((frameWidth - bounds.width) * 0.5), y + ((frameHeight - bounds.height) * 0.5));
	}

	function get_bounds():FlxSprite {
		if (bounds == null) bounds = new FlxSprite();
		return bounds;
	}

	function set_bounds(value:FlxSprite):FlxSprite {
		return bounds = value;
	}
}

#if !display
@:generic
#end
class TypedMobileButton<T:FlxSprite> extends FlxSprite implements IFlxInput
{
	public var label(default, set):T;
	public var allowSwiping:Bool = true;
	public var multiTouch:Bool = false;
	public var maxInputMovement:Float = Math.POSITIVE_INFINITY;

	public var onUp(default, null):MobileButtonEvent;
	public var onDown(default, null):MobileButtonEvent;
	public var onOver(default, null):MobileButtonEvent;
	public var onOut(default, null):MobileButtonEvent;

	public var status(default, set):Int;
	public var statusAlphas:Array<Float> = [1.0, 1.0, 0.6];
	public var statusAnimations:Array<String> = ['normal', 'highlight', 'pressed'];
	public var labelStatusDiff:Float = 0.05;
	public var parentAlpha(default, set):Float = 1;
	public var statusIndicatorType(default, set):StatusIndicators = ALPHA;

	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

	public var isJoyStick:Bool;
	public var deadZones:Array<FlxSprite> = [];
	public var canChangeLabelAlpha:Bool = true;

	public var hintUp:FlxSprite;
	public var hintDown:FlxSprite;

	var _spriteLabel:FlxSprite;
	var input:FlxInput<Int>;
	var currentInput:IFlxInput;
	var lastStatus = -1;

	#if mobile_controls_allow_mouse_clicks
	public var mouseButtons:Array<FlxMouseButtonID> = [FlxMouseButtonID.LEFT];
	#end

	public function new(X:Float = 0, Y:Float = 0, ?OnClick:Void->Void):Void
	{
		super(X, Y);
		loadGraphic('flixel/images/ui/button.png', true, 80, 20);

		onUp = new MobileButtonEvent();
		onDown = new MobileButtonEvent();
		onOver = new MobileButtonEvent();
		onOut = new MobileButtonEvent();

		status = multiTouch ? MobileButton.NORMAL : MobileButton.HIGHLIGHT;
		scrollFactor.set();
		statusAnimations[MobileButton.HIGHLIGHT] = 'normal';
		input = new FlxInput(0);
	}

	override public function graphicLoaded():Void
	{
		super.graphicLoaded();
		var frames = #if (flixel < "5.3.0") animation.frames #else animation.numFrames #end;
		animation.add('normal', [Std.int(Math.min(MobileButton.NORMAL, frames - 1))]);
		animation.add('pressed', [Std.int(Math.min(MobileButton.PRESSED, frames - 1))]);
	}

	override public function destroy():Void
	{
		label = FlxDestroyUtil.destroy(label);
		_spriteLabel = null;
		hintUp = hintDown = null;

		onUp = FlxDestroyUtil.destroy(onUp);
		onDown = FlxDestroyUtil.destroy(onDown);
		onOver = FlxDestroyUtil.destroy(onOver);
		onOut = FlxDestroyUtil.destroy(onOut);

		deadZones = FlxDestroyUtil.destroyArray(deadZones);
		currentInput = null;
		input = null;

		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (visible)
		{
			#if FLX_POINTER_INPUT
			updateButton();
			#end

			if (lastStatus != status)
			{
				animation.play(statusAnimations[status]);
				lastStatus = status;
			}
		}
		input.update();
	}

	override public function draw():Void
	{
		super.draw();
		drawSprite(_spriteLabel);
		drawSprite(hintUp);
		drawSprite(hintDown);
	}

	inline function drawSprite(sprite:FlxSprite):Void
	{
		if (sprite != null && sprite.visible)
		{
			sprite.cameras = cameras;
			sprite.draw();
		}
	}

	#if FLX_DEBUG
	override public function drawDebug():Void
	{
		super.drawDebug();
		if (_spriteLabel != null) _spriteLabel.drawDebug();
		if (hintUp != null) hintUp.drawDebug();
		if (hintDown != null) hintDown.drawDebug();
	}
	#end

	function updateButton():Void
	{
		var overlapFound = false;
		
		#if mobile_controls_allow_mouse_clicks
		overlapFound = checkMouseOverlap();
		#end
		
		if (!overlapFound) overlapFound = checkTouchOverlap();

		if (!isJoyStick) {
			if (currentInput != null && currentInput.justReleased && overlapFound)
				onUpHandler();

			if (status != MobileButton.NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased)))
				onOutHandler();
		}
	}

	private function isPointInDeadZone(worldPos:FlxPoint, camera:FlxCamera):Bool 
	{
		for (zone in deadZones) {
			if (zone != null && zone.exists && zone.active && zone.overlapsPoint(worldPos, true, camera)) 
				return true;
		}
		return false;
	}

	#if mobile_controls_allow_mouse_clicks
	function checkMouseOverlap():Bool
	{
		for (camera in cameras) {
			final worldPos:FlxPoint = FlxG.mouse.getWorldPosition(camera, _point);
			if (isPointInDeadZone(worldPos, camera)) continue;

			for (buttonID in mouseButtons) {
				var button = FlxMouseButton.getByID(buttonID);
				if (checkInput(FlxG.mouse, button, button.justPressedPosition, camera)) return true;
			}
		}
		return false;
	}
	#end

	function checkTouchOverlap():Bool
	{
		for (camera in cameras) {
			for (touch in FlxG.touches.list) {
				final worldPos:FlxPoint = touch.getWorldPosition(camera, _point);
				if (isPointInDeadZone(worldPos, camera)) continue;

				if (checkInput(touch, touch, touch.justPressedPosition, camera)) return true;
			}
		}
		return false;
	}

	function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool
	{
		var distance = justPressedPosition.distanceTo(
			#if (flixel < "5.9.0") pointer.getScreenPosition(FlxPoint.weak()) #else pointer.getViewPosition(FlxPoint.weak()) #end
		);

		if (maxInputMovement != Math.POSITIVE_INFINITY && distance > maxInputMovement && input == currentInput)
		{
			currentInput = null;
		}
		else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera))
		{
			updateStatus(input);
			return true;
		}
		return false;
	}

	function updateStatus(input:IFlxInput):Void
	{
		if (input.justPressed) {
			currentInput = input;
			onDownHandler();
		} else if (status == MobileButton.NORMAL) {
			(allowSwiping && input.pressed) ? onDownHandler() : onOverHandler();
		}
	}

	public inline function updateLabelPosition()
	{
		if (_spriteLabel != null) {
			_spriteLabel.x = ((width - _spriteLabel.width) * 0.5) + (pixelPerfectPosition ? Math.floor(x) : x);
			_spriteLabel.y = ((height - _spriteLabel.height) * 0.5) + (pixelPerfectPosition ? Math.floor(y) : y);
		}
	}
	
	public inline function updateLabelScale()
	{
		if (_spriteLabel != null) _spriteLabel.scale.set(scale.x, scale.y);
	}

	inline function indicateStatus()
	{
		if (statusIndicatorType == ALPHA && _spriteLabel != null && statusAlphas.length > status)
			_spriteLabel.alpha = alpha * statusAlphas[status];
	}

	public function onUpHandler():Void
	{
		status = MobileButton.NORMAL;
		input.release();
		currentInput = null;
		onUp.fire(); 
	}

	public function onDownHandler():Void
	{
		status = MobileButton.PRESSED;
		input.press();
		onDown.fire(); 
	}

	public function onOverHandler():Void
	{
		status = MobileButton.HIGHLIGHT;
		onOver.fire(); 
	}

	public function onOutHandler():Void
	{
		status = MobileButton.NORMAL;
		input.release();
		onOut.fire(); 
	}

	function set_label(Value:T):T {
		if (Value != null) {
			Value.scrollFactor.put();
			Value.scrollFactor = scrollFactor;
		}
		label = Value;
		_spriteLabel = label;
		updateLabelPosition();
		return Value;
	}

	function set_status(Value:Int):Int {
		status = Value;
		indicateStatus();
		return status;
	}

	override function set_alpha(Value:Float):Float {
		super.set_alpha(Value);
		indicateStatus();
		return alpha;
	}
	
	override function set_visible(Value:Bool):Bool {
		super.set_visible(Value);
		if (_spriteLabel != null) _spriteLabel.visible = Value;
		return Value;
	}

	override function set_x(Value:Float):Float {
		super.set_x(Value);
		updateLabelPosition();
		return x;
	}

	override function set_y(Value:Float):Float {
		super.set_y(Value);
		updateLabelPosition();
		return y;
	}
	
	override function set_color(Value:FlxColor):Int {
		if (_spriteLabel != null) _spriteLabel.color = Value;
		return super.set_color(Value);
	}

	override private function set_width(Value:Float) {
		super.set_width(Value);
		updateLabelScale();
		return Value;
	}

	override private function set_height(Value:Float) {
		super.set_height(Value);
		updateLabelScale();
		return Value;
	}

	override public function updateHitbox() {
		super.updateHitbox();
		if (_spriteLabel != null) _spriteLabel.updateHitbox();
		if (hintUp != null) hintUp.updateHitbox();
		if (hintDown != null) hintDown.updateHitbox();
	}

	function set_parentAlpha(Value:Float):Float {
		statusAlphas = [
			Value,
			Value - 0.05,
			(parentAlpha - 0.45 == 0 && parentAlpha > 0) ? 0.25 : parentAlpha - 0.45
		];
		indicateStatus();
		return parentAlpha = Value;
	}

	function set_statusIndicatorType(Value:StatusIndicators) {
		return statusIndicatorType = Value;
	}

	inline function get_justReleased():Bool return input.justReleased;
	inline function get_released():Bool return input.released;
	inline function get_pressed():Bool return input.pressed;
	inline function get_justPressed():Bool return input.justPressed;
}

private class MobileButtonEvent implements IFlxDestroyable
{
	public var callback:Void->Void;
	#if FLX_SOUND_SYSTEM public var sound:FlxSound; #end

	public function new(?Callback:Void->Void, ?sound:FlxSound):Void {
		callback = Callback;
		#if FLX_SOUND_SYSTEM this.sound = sound; #end
	}

	public inline function destroy():Void {
		callback = null;
		#if FLX_SOUND_SYSTEM sound = FlxDestroyUtil.destroy(sound); #end
	}

	public inline function fire():Void {
		if (callback != null) callback();
		#if FLX_SOUND_SYSTEM if (sound != null) sound.play(true); #end
	}
}

enum StatusIndicators {
	ALPHA;
	NONE;
}
