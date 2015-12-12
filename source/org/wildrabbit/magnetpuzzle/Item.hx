package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxVector;

/**
 * ...
 * @author ith1ldin
 */
class Item extends FlxSprite
{
	public var resistance:Float = 10;
	public function new(X:Float=0, Y:Float=0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		makeGraphic(16, 16, flixel.util.FlxColor.CHARTREUSE);
	}
	
	public function addForce(otherX:Float, otherY: Float, magnitude: Float)
	{
		var distance: Float = FlxMath.getDistance(new FlxPoint(otherX, otherY), new FlxPoint(x + 8, y));
		if (distance < 10)
		{
			removeForce();
			return;
		}
		
		var invSqrDistance:Float = 1 / (distance * distance);
		trace("Squared distance inverse: " + Std.string(invSqrDistance));
		
		var value:Float = resistance * magnitude * invSqrDistance;
		trace("Magnitude: " + Std.string(value));
		if (Math.abs(value) > 0.1)
		{
			var direction:FlxVector = new FlxVector(otherX - (x + 8), otherY - (y));
			direction = direction.normalize();
			acceleration = direction.scale(value);
		}
	}	
	
	public function removeForce()
	{
		acceleration.set(0, 0);
	}
	
	override public function update():Void
	{
		super.update();
		if (y < 0)
		{
			y = 0;
		}
		else if (y + 8 > FlxG.height)
		{
			y = FlxG.height - 8;
		}
		
		if (x < 0)
		{
			x = 0;
		}
		else if (x + 8 > FlxG.width)
		{
			x = FlxG.width - 8;
		}
	}
}