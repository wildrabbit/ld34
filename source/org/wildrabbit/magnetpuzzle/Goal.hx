package org.wildrabbit.magnetpuzzle;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import org.wildrabbit.magnetpuzzle.PlayState.LevelRect;
import org.wildrabbit.magnetpuzzle.PlayState.ObstacleData;

/**
 * ...
 * @author ith1ldin
 */
class Goal extends FlxSprite
{

	public var w:Int;
	public var h:Int;
	private var bounds:FlxRect;
	
	public function new(goalData:ObstacleData, Bounds:FlxRect) 
	{
		w = goalData.dims.x;
		h = goalData.dims.y;
		
		bounds = Bounds;
		
		super(bounds.x + goalData.pos.x - w / 2, bounds.y + goalData.pos.y);
		
		if (goalData.path != null)
		{
			loadGraphic(goalData.path, false, w, h);
		}
		else 
		{
			makeGraphic(w, h, Std.parseInt(goalData.color));	
		}
		
		
	}
	public function setPos(x:Float, y:Float):Void
	{
		this.x = bounds.x + x - w / 2;
		this.y = bounds.y + y;
	}
}