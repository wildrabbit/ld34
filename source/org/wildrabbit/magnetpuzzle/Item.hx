package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;
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
	
	public var stuck:Bool = false;
	public var stuckAngle:Float;
	
	public var dragMagnitude:Float = 300;
	public var charge:Float = 120;
	public var maxSpeed:Float = 200;
	
	public var oldScale:Float = 0;
	public function new(itemData:ItemData, Bounds: FlxRect) 
	{
		w = itemData.dims.x;
		h = itemData.dims.y;
		
		var f: Float = Math.random();
		if (f < 0.33)
		{
			color = FlxColor.PLUM;
		}
		else if (f < 0.66)
		{
			color = FlxColor.TEAL;
		}
		
		bounds = Bounds;
		
		super(bounds.x + itemData.pos.x- w/2, bounds.y + itemData.pos.y - h/2);
		loadGraphic(itemData.path, true, w, h);
		animation.add("positive", [itemData.index],1,false);
		animation.add("negative", [itemData.index + 1], 1, false);
		
		charge = itemData.charge;
		if (charge > 0)
		{
			animation.play("positive");
		}
		else 
		{
			animation.play("negative");
		}
		drag.set(dragMagnitude, dragMagnitude);
		maxVelocity.set(maxSpeed, maxSpeed);
		stuck = false;
		stuckAngle = 0;
	}
	
	public function willAttract(force:Float):Bool
	{
		return !(FlxMath.sameSign(force, charge));
	}
	
	public function addForce(source:Magnet)
	{
		var sourcePos:FlxVector = source.getPosition();
		var attract:Bool = willAttract(source.currentForce);
		
		var threshold:Float = 50;
		
		if (stuck)
		{
			angle = stuckAngle * FlxAngle.TO_DEG - 90;
			if (!attract)
			{
				stuck = false;
				stuckAngle = 0;
			}
			else
			{
				setPos(sourcePos.x - threshold * Math.cos(stuckAngle), sourcePos.y - threshold* Math.sin(stuckAngle));
				return;
			}
		}
		var position:FlxVector = getPosition();
		var direction:FlxVector = sourcePos.subtractNew(position);
		var unitDirection:FlxVector = new FlxVector(direction.x, direction.y);
		unitDirection.normalize();
		
		angle = direction.radians * FlxAngle.TO_DEG - 90;
		
		var distance:Float = direction.length;
		if (distance <= threshold)
		{
			if (attract)
			{
				velocity.set(0, 0);
				angle = 0;
				setPos(sourcePos.x - unitDirection.x * threshold, sourcePos.y - unitDirection.y * threshold);
				stuck = true;
				stuckAngle = direction.radians; 
				return;				
			}
			else 
			{
				if (Math.abs(angle) < 15)
				{
					unitDirection.set(0, 1);
					setPos(sourcePos.x - unitDirection.x * threshold, sourcePos.y - unitDirection.y * threshold);
					angle = direction.radians * FlxAngle.TO_DEG - 90;
				}
				else if (Math.abs(angle) > 60)
				{
					var newDirectionAngle:Float = FlxMath.signOf(angle) * 60;
					unitDirection.set(Math.cos((newDirectionAngle + 90) * FlxAngle.TO_RAD), Math.sin((newDirectionAngle + 90) * FlxAngle.TO_RAD));
					setPos(sourcePos.x - unitDirection.x * threshold, sourcePos.y - unitDirection.y * threshold);
					angle = newDirectionAngle;			 
				}
			}
		}
		
		var force:Float = -charge * source.currentForce / direction.lengthSquared;
		
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
		stuck = false;
		stuckAngle = 0;
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