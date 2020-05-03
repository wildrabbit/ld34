package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;

/**
 * A FlxState which can be used for the game's menu.
 */
class MenuState extends FlxState
{
	var bg:FlxSprite ;
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		bg = new FlxSprite(0, 0, "assets/images/ld34_main.png");
		add(bg);
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(dt:Float):Void
	{
		super.update(dt);
		
		if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed || FlxG.touches.justStarted(FlxG.touches.list).length > 0)
		{
			FlxG.sound.play("assets/sounds/click.wav");
			FlxG.switchState(new PlayState());
		}
	}
}