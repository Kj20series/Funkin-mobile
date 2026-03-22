package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import mobile.MobilePad;
import mobile.Hitbox;
import mobile.JoyStick;
import flixel.FlxBasic;

/**
 * A simple mobile manager for who doesn't want to create these manually
 * if you're making big projects or have a experience to how controls work, create the controls yourself
 */
class MobileControlManager implements IFlxDestroyable {
	public var mobilePadCam:FlxCamera;
	public var mobilePad:MobilePad;
	public var joyStickCam:FlxCamera;
	public var joyStick:JoyStick;
	public var hitboxCam:FlxCamera;
	public var hitbox:Hitbox;
	public var curState:Dynamic;

	public function new(target:Dynamic):Void
	{
		curState = target;
		trace("MobileControlManager initialized.");
	}

	public function addMobilePad(DPad:String, Action:String):Void
	{
		if (mobilePad != null) removeMobilePad();
		mobilePad = new MobilePad(DPad, Action);
		curState.add(mobilePad);
	}

	public function removeMobilePad():Void
	{
		if (mobilePad != null)
		{
			curState.remove(mobilePad);
			mobilePad = FlxDestroyUtil.destroy(mobilePad);
		}

		if(mobilePadCam != null)
		{
			FlxG.cameras.remove(mobilePadCam);
			mobilePadCam = FlxDestroyUtil.destroy(mobilePadCam);
		}
	}

	public function addMobilePadCamera():Void
	{
		mobilePadCam = new FlxCamera();
		mobilePadCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobilePadCam, false);
		mobilePad.cameras = [mobilePadCam];
	}

	public function addHitbox(Mode:String):Void
	{
		if (hitbox != null) removeHitbox();
		hitbox = new Hitbox(Mode);
		curState.add(hitbox);
	}

	public function removeHitbox():Void
	{
		if (hitbox != null)
		{
			curState.remove(hitbox);
			hitbox = FlxDestroyUtil.destroy(hitbox);
		}

		if(hitboxCam != null)
		{
			FlxG.cameras.remove(hitboxCam);
			hitboxCam = FlxDestroyUtil.destroy(hitboxCam);
		}
	}

	public function addHitboxCamera():Void
	{
		hitboxCam = new FlxCamera();
		hitboxCam.bgColor.alpha = 0;
		FlxG.cameras.add(hitboxCam, false);
		hitbox.cameras = [hitboxCam];
	}

	public function addJoyStick(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void):Void
	{
		if (joyStick != null) removeJoyStick();
		joyStick = new JoyStick(x, y, graphic, onMove);
		curState.add(joyStick);
	}

	public function removeJoyStick():Void
	{
		if (joyStick != null)
		{
			curState.remove(joyStick);
			joyStick = FlxDestroyUtil.destroy(joyStick);
		}

		if(joyStickCam != null)
		{
			FlxG.cameras.remove(joyStickCam);
			joyStickCam = FlxDestroyUtil.destroy(joyStickCam);
		}
	}

	public function addJoyStickCamera():Void {
		joyStickCam = new FlxCamera();
		joyStickCam.bgColor.alpha = 0;
		FlxG.cameras.add(joyStickCam, false);
		joyStick.cameras = [joyStickCam];
	}

	public function destroy():Void {
		removeMobilePad();
		removeHitbox();
		removeJoyStick();
	}
}
