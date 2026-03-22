package mobile;

import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.Assets;
import mobile.MobileConfig.ButtonModes;

class PadSignal {
	var listeners:Array<(MobileButtonFL, Array<String>, Int) -> Void> = [];
	public function new() {}
	public function add(cb:(MobileButtonFL, Array<String>, Int) -> Void) listeners.push(cb);
	public function dispatch(btn:MobileButtonFL, ids:Array<String>, uid:Int) {
		for (cb in listeners) cb(btn, ids, uid);
	}
	public function destroy() listeners = [];
}

/**
 * A pure OpenFL MobilePad.
 */
class MobilePadFL extends Sprite {
	public var onButtonDown:PadSignal = new PadSignal();
	public var onButtonUp:PadSignal = new PadSignal();
	public var instance:MobilePadFL;
	public var buttons:Array<Array<MobileButtonFL>> = [[], []]; // [dpads], [actions]
	public var buttonMap:Map<String, MobileButtonFL> = [];

	public var baseWidth:Float = 1280;
	public var baseHeight:Float = 720;

	public function getButton(name:String):MobileButtonFL return buttonMap.get(name);

	public function getIndex(name:String, type:String = "DPad"):Int {
		var btn = buttonMap.get(name);
		if (btn == null) return -1;

		return switch(type.toUpperCase()) {
			case "DPAD": buttons[0].indexOf(btn);
			case "ACTION": buttons[1].indexOf(btn);
			default: 0;
		}
	}

	public function new(DPad:String = "NONE", Action:String = "NONE", buttonCreation:Bool = true) {
		super();
		instance = this;

		if (buttonCreation) {
			if (DPad != "NONE") {
				if (!MobileConfig.dpadModes.exists(DPad)) throw 'The mobilePad dpadMode "$DPad" doesn\'t exist.';
				for (buttonData in MobileConfig.dpadModes.get(DPad).buttons) {
					createButtonFromData(buttonData, DPAD);
				}
			}

			if (Action != "NONE") {
				if (!MobileConfig.actionModes.exists(Action)) throw 'The mobilePad actionMode "$Action" doesn\'t exist.';
				for (buttonData in MobileConfig.actionModes.get(Action).buttons) {
					createButtonFromData(buttonData, ACTION);
				}
			}
		}

		if (stage != null) onAddedToStage(null);
		else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(e:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		updateScale();
		stage.addEventListener(Event.RESIZE, onStageResize);
	}

	private function onStageResize(e:Event):Void {
		updateScale();
	}

	/**
	 * Calculates letterbox math to lock the UI perfectly to the screen 
	 * without stretching the buttons.
	 */
	public function updateScale():Void {
		if (stage == null) return;

		var stageWidth = stage.stageWidth;
		var stageHeight = stage.stageHeight;

		var ratioX = stageWidth / baseWidth;
		var ratioY = stageHeight / baseHeight;

		var scale = Math.min(ratioX, ratioY);

		this.scaleX = this.scaleY = scale;

		this.x = (stageWidth - (baseWidth * scale)) / 2;
		this.y = (stageHeight - (baseHeight * scale)) / 2;
	}

	private function createButtonFromData(buttonData:Dynamic, indexType:ButtonModes) {
		var scale:Float = buttonData.scale != null ? buttonData.scale : 1.0;
		var returnKey:String = buttonData.returnKey != null ? buttonData.returnKey : "NONE";
		var uniqueID:Int = buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1;
		var colorStr = buttonData.color; 

		addButton(
			buttonData.button, 
			buttonData.buttonIDs, 
			uniqueID, 
			buttonData.position[0], 
			buttonData.position[1], 
			buttonData.graphic, 
			scale, 
			Util.colorFromString(colorStr),
			returnKey, 
			indexType
		);
	}

	public function addButton(name:String, IDs:Array<String>, uniqueID:Int = -1, X:Float, Y:Float, Graphic:String, Scale:Float = 1.0, Color:Int = 0xFFFFFF, returned:String = "NONE", indexType:ButtonModes = DPAD) {
		var button:MobileButtonFL = createVirtualButton(X, Y, Graphic, Scale, Color, returned);
		button.name = name;
		button.uniqueID = uniqueID;
		button.IDs = IDs;

		button.onDown.callback = () -> onButtonDown.dispatch(button, IDs, uniqueID);
		button.onOut.callback = button.onUp.callback = () -> onButtonUp.dispatch(button, IDs, uniqueID);

		addChild(button);
		buttonMap.set(name, button);
		var groupIndex = (indexType == DPAD) ? 0 : 1;
		buttons[groupIndex].push(button);
	}

	public function createVirtualButton(x:Float, y:Float, framePath:String, scale:Float = 1.0, ColorS:Int = 0xFFFFFF, returned:String = "NONE"):MobileButtonFL {
		var bmd:BitmapData;
		final path:String = MobileConfig.mobileFolderPath + 'MobilePad/Textures/$framePath.png';

		if (Assets.exists(path)) bmd = Assets.getBitmapData(path);
		else bmd = Assets.getBitmapData(MobileConfig.mobileFolderPath + 'MobilePad/Textures/default.png');

		var button = new MobileButtonFL(x, y, returned);
		button.tag = framePath.toUpperCase();
		button.setFrames(bmd);

		button.setGraphicScale(scale);

		/*
		if (ColorS != 0xFFFFFF) {
			var tint = new openfl.geom.ColorTransform();
			tint.color = ColorS;
			button.transform.colorTransform = tint;
		}
		*/

		return button;
	}

	public function destroy():Void {
		if (stage != null) stage.removeEventListener(Event.RESIZE, onStageResize);
		onButtonUp.destroy();
		onButtonDown.destroy();
		buttons = [[], []];
		buttonMap.clear();
		while (numChildren > 0) {
			var child = getChildAt(0);
			if (Std.isOfType(child, MobileButtonFL)) cast(child, MobileButtonFL).destroy();
			removeChildAt(0);
		}
	}
}
