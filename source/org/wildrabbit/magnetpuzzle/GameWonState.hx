package org.wildrabbit.magnetpuzzle;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;

/**
 * ...
 * @author ith1ldin
 */
class GameWonState extends FlxState
{
	var bg:FlxSprite;
	
	var mv:FlxSprite;
	var mg:FlxSprite;
	
	var message:FlxText;
	var backMessage:FlxText;
		
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width, FlxG.height, PlayState.bgColour);
		add(bg);
		
		add(new FlxSprite(0, 0, "assets/images/ui_cover.png"));
		
		mv = new FlxSprite(32, 512);
		mv.loadGraphic("assets/images/move_button.png", true, 128, 128);
		mv.animation.add("default", [0], 1, false);
		mv.animation.play("default");
		add(mv);
		
		mg = new FlxSprite(320, 512);
		mg.loadGraphic("assets/images/magnet_mode_button.png", true, 128, 128);
		mg.animation.add("default", [0], 1, false);
		mg.animation.play("default");
		add(mg);
		
		message = new FlxText(50, 100, 380, "CONGRATULATIONS!", 30);
		message.color = PlayState.txtColour;
		message.alignment = "center";
		add(message);
		
		backMessage = new FlxText(90, 180, 300, "Press any key (or tap the screen) to go back to the main menu", 18);
		backMessage.color = PlayState.txtColour;
		backMessage.alignment = "center";
		add(backMessage);
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
	override public function update():Void
	{
		super.update();
		
		if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed || FlxG.touches.justStarted(FlxG.touches.list).length > 0)
		{
			FlxG.sound.play("assets/sounds/click.wav");
			FlxG.switchState(new MenuState());
		}
	}	
}