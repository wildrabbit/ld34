package org.wildrabbit.magnetpuzzle;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxRect;
import org.wildrabbit.magnetpuzzle.PlayState.WheelData;

/**
 * ...
 * @author ith1ldin
 */
class DeadlyWheel extends FlxSprite
{
	public var w:Int;
	public var h:Int;
	private var bounds:FlxRect;
	
	public function new(Data:WheelData, Bounds:FlxRect) 
	{
		w = Data.dims.x;
		h = Data.dims.y;
		
		bounds = Bounds;

		super(Data.pos.x - w/2, Data.pos.y - h/2);
		makeGraphic(w, h, Data.color);	
		angularVelocity = Data.rotationSpeed;
	}
	
	public function setPos(x:Float, y:Float):Void
	{
		this.x = x - w / 2;
		this.y = y - h / 2;
	}
}