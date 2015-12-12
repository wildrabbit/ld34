package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxAngle;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxVector;
import flixel.util.FlxVelocity;

/**
 * ...
 * @author ith1ldin
 */
class Item extends FlxSprite
{
	public static var w:Int = 32;
	public static var h:Int= 32;
	
	public var bottom:Float = 40;
	public var dragMagnitude:Float = 200;
	public var charge:Float = 120;
	public var maxSpeed:Float = 200;
	
	public var oldScale:Float = 0;
	public function new(X:Float=0, Y:Float=0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		loadRotatedGraphic("assets/images/64_pokeball.png", 32);
		//makeGraphic(16, 16, flixel.util.FlxColor.CHARTREUSE);
		drag.set(dragMagnitude, dragMagnitude);
		maxVelocity.set(maxSpeed, maxSpeed);
	}
	
	public function addForce(source:Magnet)
	{
		
		var sourcePos:FlxVector = source.getPosition();
		var position:FlxVector = getPosition();
		var direction:FlxVector = sourcePos.subtractNew(position);
		var unitDirection:FlxVector = new FlxVector(direction.x, direction.y);
		unitDirection.normalize();
		
		var distance:Float = direction.length;
		if (source.currentForce > 0 && distance < 48)
		{
			velocity.set(0, 0);
			setPos(sourcePos.x, sourcePos.y - 48 );
			angle = 0;
			return;
		}
		
		angle = direction.radians * FlxAngle.TO_DEG - 90;
		
		var force:Float = charge * source.currentForce / direction.lengthSquared;
		
		if (oldScale > 0 && force < 0 || oldScale < 0 && force > 0)
		{
			velocity.set(0, 0);
		}
		oldScale = force;
		
		velocity.add(unitDirection.x * force, unitDirection.y * force);
	}	
	
	public function removeForce()
	{
		acceleration.set(0, 0);
	}
	
	override public function update():Void
	{
		super.update();
		
		var lowerBound:Float = FlxG.height - bottom;
		if (y < 0)
		{
			y = 0;
			velocity.y  = 0;
		}
		else if (y + h> FlxG.height - h/2)
		{
			y = FlxG.height - 3*h/2;
			velocity.y  = 0;
		}
		
		if (x < 0)
		{
			x = 0;
			velocity.x = 0;
		}
		else if (x + w > FlxG.width)
		{
			x = FlxG.width - w;
			velocity.x = 0;
		}
	}
	
	public function getPosition():FlxVector
	{
		return new FlxVector(x + w / 2, y + w / 2);
	}
	
	public function setPos(x:Float, y:Float):Void 
	{
		this.x = x - w / 2;
		this.y = y - h / 2;
	}
}