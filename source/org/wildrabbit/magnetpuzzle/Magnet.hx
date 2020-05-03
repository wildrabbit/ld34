package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.gamepad.FlxGamepad;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import org.wildrabbit.magnetpuzzle.PlayState.PlayerData;

/**
 * ...
 * @author ith1ldin
 */

 @:enum abstract MovementMode(Int) from Int to Int
 {
	 var Off = 0;
	 var Left = 1;
	 var Right = 2;
 }
 
 @:enum abstract MagnetMode(Int) from Int to Int
 {
	 var Off = 0;
	 var Positive = 1;
	 var Negative = 2;
 }
 
class Magnet extends FlxSprite
{
	public var w:Int = 32;
	public var h:Int = 32;
	
	private var speed:Float = 300;
	private var gamepad:FlxGamepad;
	
	public static inline var MOVEMODE_COUNT:Int = MovementMode.Right - MovementMode.Off + 1;
	public static inline var MAGNETMODE_COUNT:Int = MagnetMode.Negative - MagnetMode.Off + 1;
	
	private var lastMv:MovementMode;
	public var mvMode:MovementMode;
	
	private var lastMg:MagnetMode;
	public var mgMode:MagnetMode;
	
	private var forceMagnitude: Float = 10000;
	public var currentForce: Float = 0;
	public var minThreshold:Float = 48;
	public var maxThreshold:Float = 240;
	
	public var radius:Float = 48;
	private var bounds:FlxRect;
	
	private var effect:FlxSprite;
	
	private var animated:Bool;
	
	private var mvSound:FlxSound;
	private var attractSound:FlxSound;
	private var repelSound:FlxSound;
				
	
	public function new(data:PlayerData,Bounds:FlxRect, ?Effect:FlxSprite) 
	{
		bounds = Bounds;
		
		w = data.dims.x;
		h = data.dims.y;

		super(bounds.x + data.pos.x - w/2, bounds.y + data.pos.y - h/2, null);	
		
		if (data.path != null)
		{
			loadGraphic(data.path, true, data.dims.x, data.dims.y);
			animation.add("off", [data.offIdx], 1, false);
			animation.add("pos", [data.posIdx], 1, false);
			animation.add("neg", [data.negIdx], 1, false);
			animated = true;
		}
		else 
		{
			makeGraphic(w, h);
			animated = false;
		}
		
		forceMagnitude = data.force;
				
		mvSound = FlxG.sound.load("assets/sounds/move.wav",1,true);
		attractSound = FlxG.sound.load("assets/sounds/attract.wav");
		repelSound = FlxG.sound.load("assets/sounds/repel.wav");
		
		velocity.set(0, 0);		
		gamepad = null;

		effect = Effect;

		lastMv = MovementMode.Right;
		changeMovement(MovementMode.Off);		
		
		lastMg = MagnetMode.Negative;
		changeMagnet(MagnetMode.Off);

	}
	
	override public function update(dt:Float):Void
	{
		super.update(dt);
		
		if ((x + w) > bounds.x + bounds.width)
		{
			x = bounds.x + bounds.width - w;
			changeMovement(MovementMode.Left);
			lastMv = MovementMode.Left;
		}
		else if (x < bounds.x)
		{
			x = bounds.x;
			changeMovement(MovementMode.Right);
			lastMv = MovementMode.Right;
		}
		
		effect.x = x + w/2 - effect.width/2;
		effect.y = y - effect.height - 4; 
		immovable = true;
	}
	
	public function OnMoveJustPressed ():Void
	{
		if (lastMv == MovementMode.Left)
		{
			changeMovement(lastMv);
		}
		else if (lastMv == MovementMode.Right)
		{
			changeMovement(lastMv);
		}
	}
	
	public function OnMoveJustReleased (): Void 
	{
		changeMovement(MovementMode.Off);
	}
	
	public function OnCycleMagnetMode(ascending:Bool = true): Void 
	{
		var newMagnet:Int = mgMode;
		if (ascending)
		{
			newMagnet = (newMagnet+ 1) % MAGNETMODE_COUNT;			
		}
		else 
		{
			if (newMagnet == 0)
			{
				newMagnet = MAGNETMODE_COUNT - 1;
			}
			else 
			{
				newMagnet = (newMagnet - 1) % MAGNETMODE_COUNT;
			}
		}
		changeMagnet(newMagnet);
	}
	
	
	private function changeMovement(newMvMode:MovementMode ):Void 
	{
		var old:MovementMode = mvMode;
		mvMode = newMvMode;
		switch mvMode
		{
			case MovementMode.Off: 
			{
				velocity.set(0, 0);
				mvSound.stop();
			}
			case MovementMode.Left:
			{				
				velocity.set( -speed, 0);
				if (old == MovementMode.Off)
				{
					mvSound.play();
				}
			}
			case MovementMode.Right:
			{
				velocity.set(speed, 0);
				if (old == MovementMode.Off)
				{
					mvSound.play();
				}				
			}
		}		
	}
	

	
	private function changeMagnet (newMgMode:MagnetMode):Void 
	{
		mgMode = newMgMode;
		switch mgMode
		{
			case MagnetMode.Off: 
			{
				if (animated)
				{
					animation.play("off");
				}
				else 
				{
					color = FlxColor.GRAY;				
				}
				
				currentForce = 0;
				if (effect != null)
				{
					effect.visible = false;
					effect.animation.pause();
				}
			}
			case MagnetMode.Positive:
			{
				if (animated)
				{
					animation.play("pos");
				}
				else 
				{
					color = FlxColor.RED;				
				}
				attractSound.play();
				currentForce = forceMagnitude;
				if (effect != null)
				{
					effect.visible = true;
					effect.animation.play("attract");
				}
			}
			case MagnetMode.Negative:
			{
				if (animated)
				{
					animation.play("neg");
				}
				else 
				{
					color = FlxColor.BLUE;				
				}

				currentForce = -forceMagnitude;
				if (effect != null)
				{
					effect.visible = true;
					effect.animation.play("repel");
				}
				repelSound.play();
			}
		}
	}
	public function getPos():FlxVector 
	{
		return new FlxVector(x - bounds.x + w/2, y - bounds.y + h/2);
	}
}