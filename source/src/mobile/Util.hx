package mobile;

import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import mobile.MobileConfig.ButtonModes;
import mobile.MobileConfig.MobileButtonsData;
import mobile.MobileConfig.CustomHitboxData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;
class Util {
	inline public static function colorFromString_FL(color:String):Int {
		var hideChars = ~/[\t\n\r]/g;
		var cleanColor = hideChars.replace(color, "").trim();

		if (cleanColor.startsWith("#")) {
			cleanColor = cleanColor.substring(1);
		} else if (cleanColor.startsWith("0x"))
			cleanColor = cleanColor.substring(cleanColor.length - 6);

		var colorNum = Std.parseInt("0x" + cleanColor);
		return colorNum != null ? colorNum : 0xFFFFFF; 
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function setupMaps(folder:String, map:Dynamic, mode:ButtonModes)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		#if mobile_controls_file_support if (FileSystem.exists(folder)) #end
		for (file in readDirectory(folder))
		{
			if (Path.extension(file) == 'json')
			{
				file = Path.join([folder, Path.withoutDirectory(file)]);

				var str:String;
				#if mobile_controls_file_support
				if (FileSystem.exists(file))
					str = File.getContent(file);
				else #end
					str = Assets.getText(file);

				if (mode == HITBOX) {
					var json:CustomHitboxData = cast Json.parse(str);
					var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
					map.set(mapKey, json);
				}
				else if (mode == ACTION || mode == DPAD) {
					var json:MobileButtonsData = cast Json.parse(str);
					var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
					map.set(mapKey, json);
				}
			}
		}
	}

	inline public static function readDirectory(directory:String):Array<String>
	{
		var dirs:Array<String> = [];

		#if mobile_controls_file_support
		return FileSystem.readDirectory(directory);
		#else
		var dirs:Array<String> = [];
		for(dir in Assets.list().filter(folder -> folder.startsWith(directory)))
		{
			@:privateAccess
			for(library in lime.utils.Assets.libraries.keys())
			{
				if(library != 'default' && Assets.exists('$library:$dir') && (!dirs.contains('$library:$dir') || !dirs.contains(dir)))
					dirs.push('$library:$dir');
				else if(Assets.exists(dir) && !dirs.contains(dir))
					dirs.push(dir);
			}
		}
		return dirs;
		#end
	}
}