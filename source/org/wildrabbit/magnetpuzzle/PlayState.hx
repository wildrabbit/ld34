package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxVector;
import flixel.util.FlxPoint;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var items:FlxTypedGroup<Item>;
	private var goal: Goal;
	
	private var player:Magnet;
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		FlxG.debugger.visible = true;
		
		var magnetStart:FlxPoint = new FlxPoint((FlxG.width - Magnet.w)/2, FlxG.height - Magnet.h - 4);
	
		goal = new Goal((FlxG.width - 200) / 2, 4);
		add(goal);

		player = new Magnet(magnetStart.x, magnetStart.y);
		add(player);
		
		items = new FlxTypedGroup<Item>();
		add(items);
		
		items.add(new Item((FlxG.width - Item.w)/2 - Item.w, (FlxG.height  - Item.h)/2));
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
		
		if (Math.abs(player.currentForce) > 0.001)
		{
			for (x in items) 
			{
				x.addForce(player);
			}
		}
		else 
		{
			for (x in items) 
			{
				x.removeForce();
			}
		}
	}
}