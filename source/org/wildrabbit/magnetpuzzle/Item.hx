package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxAngle;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxRect;
import flixel.util.FlxVector;
import flixel.util.FlxVelocity;
import org.wildrabbit.magnetpuzzle.PlayState.ItemData;

/**
 * ...
 * @author ith1ldin
 */
class Item extends FlxSprite
{
	public var w:Int;
	public var h:Int;
	private var bounds:FlxRect;
	
	public var bottom:Float = 40;
	public var dragMagnitude:Float = 200;
	public var charge:Float = 120;
	public var maxSpeed:Float = 200;
	
	public var oldScale:Float = 0;
	public function new(itemData:ItemData, Bounds: FlxRect) 
	{
		w = itemData.dims.x;
		h = itemData.dims.y;
		
		bounds = Bounds;
		
		super(bounds.x + itemData.pos.x- w/2, bounds.y + itemData.pos.y - h/2);
		loadRotatedGraphic(itemData.path, 32);
		charge = itemData.charge;
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
			setPos(sourcePos.x, sourcePos.y - source.w/2 - 4);
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
		
		if (y < bounds.y)
		{
			y = bounds.y;
			velocity.y  = 0;
		}
		else if (y + h> bounds.y + bounds.height - h/2)
		{
			y = bounds.y + bounds.height - 3*h/2;
			velocity.y  = 0;
		}
		
		if (x < bounds.x)
		{
			x = bounds.x;
			velocity.x = 0;
		}
		else if (x + w > bounds.x + bounds.width)
		{
			x = bounds.x + bounds.width - w;
			velocity.x = 0;
		}
	}
	
	public function getPosition():FlxVector
	{
		return new FlxVector(x - bounds.x + w / 2, y - bounds.y + w / 2);
	}
	
	public function setPos(x:Float, y:Float):Void 
	{
		this.x = bounds.x + x - w / 2;
		this.y = bounds.y + y - h / 2;
	}
}