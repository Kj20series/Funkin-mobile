package mobile;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import flixel.util.FlxColor;
import flixel.FlxCamera;

/**
 * A zone with custom hint's (A hitbox).
 * It's really easy to customize the layout.
 * @author ArkoseLabs && KralOyuncu 2010x
 */
class Hitbox extends MobileInputHandler
{
	public var onButtonDown:FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void> = new FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void>();
	public var onButtonUp:FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void> = new FlxTypedSignal<(MobileButton, Array<String>, Int) -> Void>();
	public var instance:MobileInputHandler;
	public var hintMap:Map<String, MobileButton> = [];
	public var hints:Array<MobileButton> = [];

	public function getButton(name:String):MobileButton
		return hintMap.get(name);

	public function getIndex(name:String):Int {
		var btn = hintMap.get(name);
		if (btn == null) return -1;
		return hints.indexOf(btn);
	}

	/**
	 * Create the zone.
	 *
	 * @param   Mode   The Hitbox mode. `Test` for example.
	 * @param   hintCreation   The hint creation.
	 */
	public function new(Mode:String = "NONE", hintCreation:Bool = true):Void
	{
		instance = this;
		super();

		if (hintCreation && Mode != "NONE")
		{
			if (!MobileConfig.hitboxModes.exists(Mode))
				throw 'The hitbox hitboxMode "$Mode" doesn\'t exists.';

			for (buttonData in MobileConfig.hitboxModes.get(Mode).hints)
			{
				var buttonName:String = buttonData.button;
				var buttonIDs:Array<String> = buttonData.buttonIDs;
				var buttonUniqueID:Int = (buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1);
				var buttonX:Float = buttonData.position[0];
				var buttonY:Float = buttonData.position[1];

				var buttonWidth:Int = buttonData.scale[0];
				var buttonHeight:Int = buttonData.scale[1];

				var buttonColor = buttonData.color;
				var buttonReturn = buttonData.returnKey;

				addHint(buttonName, buttonIDs, buttonUniqueID, buttonX, buttonY, buttonWidth, buttonHeight, Util.colorFromString(buttonColor), buttonReturn);
			}
		}

		scrollFactor.set();
		updateTrackedButtons();
		instance = this;
	}

	public function addHint(name:String, IDs:Array<String>, uniqueID:Int, x:Float, y:Float, width:Int, height:Int, color:Int = 0xFFFFFF, ?returned:String)  
	{
		var hint = createHint(IDs, uniqueID, x, y, width, height, color, returned);
		add(hint);
		hintMap.set(name, hint);
		hints.push(hint);
	}

	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?isLane:Bool = false):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);
		// Gradient (Example)
		shape.graphics.lineStyle(3, Color, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.lineStyle(0, 0, 0);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();
		if (isLane)
			shape.graphics.beginFill(Color);
		else
			shape.graphics.beginGradientFill(RADIAL, [Color, FlxColor.TRANSPARENT], [alpha, 0], [0, 255], null, null, null, 0.5);
		shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	public function createHint(name:Array<String>, uniqueID:Int, x:Float, y:Float, width:Int, height:Int, color:Int = 0xFFFFFF, ?returned:String):MobileButton
	{
		var hint:MobileButton = new MobileButton(x, y, returned);
		hint.loadGraphic(createHintGraphic(width, height, color));

		hint.solid = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.IDs = name;
		hint.uniqueID = uniqueID;
		hint.onDown.callback = function()
		{
			onButtonDown.dispatch(hint, name, uniqueID);
			if (hint.alpha != alpha)
				hint.alpha = alpha;
		}
		hint.onOut.callback = hint.onUp.callback = function()
		{
			onButtonUp.dispatch(hint, name, uniqueID);
			if (hint.alpha != 0.00001)
				hint.alpha = 0.00001;
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	/**
	 * Clean up memory.
	 */
	override function destroy():Void
	{
		super.destroy();
		onButtonUp.destroy();
		onButtonDown.destroy();
		hints = [];
		hintMap.clear();
	}
}