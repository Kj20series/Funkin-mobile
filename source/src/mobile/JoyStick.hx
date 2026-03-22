package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets;
import openfl.display.BitmapData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

/**
 * A Virtual Joystick component for mobile devices.
 * Processes touch input to provide directional vectors, angles, and movement strength.
 */
class JoyStick extends FlxSpriteGroup
{
	/** The movable inner part of the joystick. **/
	public var thumb:FlxSprite;

	/** The static background/outer ring of the joystick. **/
	public var base:MobileButton;

	/** * Callback triggered during joystick movement.
	 * Parameters: (angle:Float, strength:Float, directionID:Int, directionName:String)
	 */
	public var onMove:Float->Float->Float->String->Void;

	/** If true, the thumb returns to the center position when the touch is released. **/
	public var autoRecenter:Bool = true;

	/** If true, the thumb stays locked at the maximum radius distance during movement. **/
	public var stickToBorder:Bool = false;

	public var keepRadius:Bool;

	/** Movement constraint: 0 = Omni-directional, 1 = Vertical Only, 2 = Horizontal Only. **/
	private var _direction:Int = 0;

	/** The maximum allowed distance the thumb can travel from the center. **/
	private var _radius:Float;

	/** Reference to the specific touch input currently controlling this joystick. **/
	private var _activeTouch:FlxTouch = null;

	private var _lastScale:Float = 1;

	/**
	 * Creates a new JoyStick instance.
	 * @param x Initial X position.
	 * @param y Initial Y position.
	 * @param graphic Optional path to the texture atlas (Sparrow format).
	 * @param onMove Optional callback function for movement events.
	 */
	public function new(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void)
	{
		super(x, y);
		this.onMove = onMove;

		base = new MobileButton(0, 0);
		if (graphic != null)
			loadObjectGraphic(base, graphic, 'base');
		else
		{
			var baseSize = 200;
			base.makeGraphic(baseSize, baseSize, FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawCircle(base, baseSize / 2, baseSize / 2, baseSize / 2, 0xAA000000);
			FlxSpriteUtil.drawCircle(base, baseSize / 2, baseSize / 2, (baseSize / 2) - 4, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.WHITE});
		}
		add(base);

		_radius = (Math.min(base.width, base.height) / 2);

		thumb = new FlxSprite();
		if (graphic != null)
			loadObjectGraphic(thumb, graphic, 'thumb');
		else
		{
			var thumbSize = Std.int(_radius * 0.5); 
			thumb.makeGraphic(thumbSize, thumbSize, FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawCircle(thumb, thumbSize / 2, thumbSize / 2, thumbSize / 2, FlxColor.WHITE);
		}
		add(thumb);
		
		centerThumb();
	}

	/** Loads sprite graphics from the file system or assets using Sparrow Atlas format. **/
	private function loadObjectGraphic(object:FlxSprite, graphic:String, img:String) {
		if (!graphic.startsWith(MobileConfig.mobileFolderPath))
			graphic = MobileConfig.mobileFolderPath + graphic;

		#if mobile_controls_file_support
		var xmlAndPngExists:Bool = (FileSystem.exists('$graphic.xml') && FileSystem.exists('$graphic.png'));
		if (xmlAndPngExists)
			object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(BitmapData.fromFile('$graphic.png'), File.getContent('$graphic.xml')).getByName(img)));
		else #end
			object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(Assets.getBitmapData('$graphic.png'), Assets.getText('$graphic.xml')).getByName(img)));
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (_lastScale != scale.x && !keepRadius) {
			_lastScale = scale.x;
			_radius = (Math.min(base.width, base.height) / 2) * _lastScale;
		}

		if (_activeTouch == null)
		{
			if (base.justPressed)
			{
				@:privateAccess
				_activeTouch = cast base.currentInput;
			}
		}

		if (_activeTouch != null)
		{
			if (_activeTouch.released)
			{
				_activeTouch = null;
				direction = [0, 'NONE'];
				if (autoRecenter) centerThumb();
				if (onMove != null) onMove(0, 0, 0, 'NONE');
			}
			else
			{
				handleInputDrag(_activeTouch.getWorldPosition(camera));
			}
		}
	}

	/**
	 * Calculates thumb position, angle, and strength based on world coordinates.
	 * @param inputPos The current world position of the touch input.
	 */
	private function handleInputDrag(inputPos:FlxPoint):Void
	{
		var center = getBaseCenter();
		
		var dx:Float = 0;
		var dy:Float = 0;

		if (_direction == 0 || _direction == 2) dx = inputPos.x - center.x;
		if (_direction == 0 || _direction == 1) dy = inputPos.y - center.y;

		var angleRad = Math.atan2(dy, dx);
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist > _radius || (stickToBorder && dist != 0))
			dist = _radius;

		var newX = center.x + Math.cos(angleRad) * dist;
		var newY = center.y + Math.sin(angleRad) * dist;

		updateThumbPosition(newX, newY);

		var strength = (dist / _radius) * 100;
		var protractorAngle = Math.atan2(-dy, dx) * FlxAngle.TO_DEG;
		if (protractorAngle < 0) protractorAngle += 360;

		updateCurrentDirection(protractorAngle, strength);

		if (onMove != null)
			onMove(protractorAngle, strength, direction[0], direction[1]);

		inputPos.put();
		center.put();
	}

	/** Snaps the thumb back to the center of the base. **/
	private function centerThumb():Void
	{
		var center = getBaseCenter();
		updateThumbPosition(center.x, center.y);
		center.put();
	}

	/** Updates the visual X/Y coordinates of the thumb sprite. **/
	private function updateThumbPosition(xPos:Float, yPos:Float):Void
	{
		thumb.x = xPos - (thumb.width / 2);
		thumb.y = yPos - (thumb.height / 2);
	}

	/** Returns the center coordinate of the joystick base as a FlxPoint. **/
	public function getBaseCenter():FlxPoint
	{
		return FlxPoint.get(base.x + base.width / 2, base.y + base.height / 2);
	}

	/** Input State Helpers (Directional Checks) **/
	public function pressed(?pos:String):Bool {
		return (_activeTouch != null && (pos == null || Std.string(direction[1]).contains(pos.toUpperCase())));
	}
	public function justPressed(?pos:String):Bool {
		return (base.justPressed && (pos == null || Std.string(direction[1]).contains(pos.toUpperCase())));
	}
	public function justReleased(?pos:String):Bool {
		return (_activeTouch == null && base.justReleased && (pos == null || Std.string(direction[1]).contains(pos.toUpperCase())));
	}
	public function released(?pos:String):Bool {
		return (_activeTouch == null && (pos == null || Std.string(direction[1]).contains(pos.toUpperCase())));
	}

	override public function destroy():Void
	{
		_activeTouch = null;
		super.destroy();
	}

	/** The currently active direction stored as: [ID, Name] (e.g., [2, 'UP']) **/
	public var direction:Array<Dynamic> = [0, 'NONE'];

	/**
	 * Maps the raw input angle to 8 cardinal and intercardinal directions.
	 * @param angle The angle in degrees (0-360).
	 * @param strength The pull strength percentage (0-100).
	 */
	private function updateCurrentDirection(angle:Float, strength:Float):Void
	{
		if (strength < 10)
		{
			direction = [0, 'NONE'];
			return;
		}

		if (angle >= 112.5 && angle < 157.5) direction = [1, 'UP_LEFT'];
		else if (angle >= 67.5 && angle < 112.5) direction = [2, 'UP'];
		else if (angle >= 22.5 && angle < 67.5) direction = [3, 'UP_RIGHT'];
		else if (angle >= 157.5 && angle < 202.5) direction = [4, 'LEFT'];
		else if (angle >= 337.5 || angle < 22.5) direction = [5, 'RIGHT'];
		else if (angle >= 202.5 && angle < 247.5) direction = [6, 'DOWN_LEFT'];
		else if (angle >= 247.5 && angle < 292.5) direction = [7, 'DOWN'];
		else if (angle >= 292.5 && angle < 337.5) direction = [8, 'DOWN_RIGHT'];
	}
}
