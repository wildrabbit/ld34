package org.wildrabbit.magnetpuzzle;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxMath;
import flixel.util.FlxRect;
import flixel.util.FlxSort;
import flixel.util.FlxVector;
import flixel.util.FlxPoint;
import haxe.Json;
import org.wildrabbit.magnetpuzzle.Magnet.MagnetMode;
import org.wildrabbit.magnetpuzzle.PlayState.Vec2;

typedef LevelRect =
{
	var x:Float;
	var y:Float;
	var w:Float;
	var h:Float;
}
typedef IntVec2 =
{
	var x:Int;
	var y:Int;
}
typedef Vec2 =
{
	var x:Float;
	var y:Float;
}

typedef PlayerData =  
{
	var pos:Vec2;
	var dims:IntVec2;
	var force:Float;
	var initialState:MagnetMode;
	@:optional var path:String;
	@:optional var offIdx:Int;
	@:optional var posIdx:Int;
	@:optional var negIdx:Int;
}

typedef ItemData =
{
	var path:String;
	var pos:Vec2;
	var dims:IntVec2;
	var charge:Float;
}

typedef Level =
{
	var name:String;
	var area:LevelRect;
	var player:PlayerData;
	var items:Array<ItemData>;
	var goal:ObstacleData;
	var obstacles:Array<ObstacleData>;
	var wheels:Array<WheelData>;
}

typedef ObstacleData =
{
	var color:Int;
	var pos:Vec2;
	var dims:IntVec2;
	@:optional var path:String;
}

typedef WheelData =
{
	var color:Int;
	var pos:Vec2;
	var path:String;
	var dims:IntVec2;
	var rotationSpeed:Float;
}

 @:enum abstract MoveTarget(Int) from Int to Int
 {
	 var None = -1;
	 var Key = 0;
	 var Mouse = 1;
	 var Touch = 2;
 }

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var items:FlxTypedGroup<Item>;
	private var obstacles:FlxTypedGroup<FlxSprite>; //Normal, collidable
	private var deadlyStuff:FlxTypedGroup<DeadlyWheel>;
	
	private var itemCollisions:FlxGroup;
	
	public var worldArea:FlxRect;
	private var worldBackground:FlxSprite;
	private var worldForeground:FlxSprite;
	private var magnetPaddle:FlxSprite;
	
	private var bgColour:Int = 0xffca9b8c;
	
	private var txtColour:Int = 0xff7c3e5c;
	
	private var goal: Goal;
	
	private var player:Magnet;
	private var effect:FlxSprite;
	
	private var currentLevel:String;
	
	private var levelTable: Map<String,Level>;
	
	private var movementButton: FlxSprite;
	private var magnetButton:FlxSprite;
	private var magnetPressed:Bool;
	
	private var movePressed:Bool;
	private var movePressTarget:MoveTarget;
	
	private static var moveKeys:Array<String> = ["F", "U"];
	private static var magnetKeys:Array<String> = ["J", "H"];
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		movementButton = new FlxSprite(32, 512);
		movementButton.loadGraphic("assets/images/move_button.png", true, 128, 128);
		movementButton.animation.add("normal", [0], 1, false);
		movementButton.animation.add("pressed", [1], 1, false);
		movePressed = false;
		movePressTarget = MoveTarget.None;
		movementButton.animation.play("normal");
		
		magnetButton = new FlxSprite(320, 512);
		magnetButton.loadGraphic("assets/images/magnet_mode_button.png", true, 128, 128);
		magnetButton.animation.add("negative", [0], 1, false);
		magnetButton.animation.add("positive", [1], 1, false);
		magnetButton.animation.add("off", [2], 1, false);
		magnetPressed = false;
		magnetButton.animation.play("off");
		
		worldArea = new FlxRect(0, 0, FlxG.width, FlxG.height);
		worldBackground = new FlxSprite(worldArea.x, worldArea.y);
		worldBackground.makeGraphic(cast(worldArea.width,Int),cast(worldArea.height,Int), bgColour);
		add(worldBackground);
		
		effect = new FlxSprite(0, 0);
		effect.loadGraphic("assets/images/effects.png", true, 32, 32, true);
		effect.animation.add("repel", [0, 1, 2, 3, 4], 10, true);
		effect.animation.add("attract", [8, 9, 10, 11, 12], 10, true);
		effect.visible = false;
		add(effect);
		
		// Groups
		obstacles = new FlxTypedGroup<FlxSprite>();
		add(obstacles);
		deadlyStuff = new FlxTypedGroup<DeadlyWheel>();
		add(deadlyStuff);
		items = new FlxTypedGroup<Item>();
		add(items);
		itemCollisions = new FlxGroup();
		itemCollisions.add(items);
		itemCollisions.add(obstacles);
		
		levelTable = new Map<String,Level>();
		
		levelTable.set("Level0",{
			name:"Level0",
			area: { x:0, y:0, w:480, h:512 },
			player: {
				pos: { x: 240, y: 448 },
				dims: { x: 64, y:64 },
				force: 10000,
				initialState: MagnetMode.Off,
				path:"assets/images/magnet.png",
				offIdx:0,
				posIdx:1,
				negIdx:2
			},
			items: [
				{path: "assets/images/64_pokeball.png", pos: {x: 240, y: 200}, dims: {x:32,y:32}, charge:120}//,
				//{path: "assets/images/64_pokeball.png", pos: {x: 200, y: 300}, dims: {x:32,y:32}, charge:120},
				//{path: "assets/images/64_pokeball.png", pos: {x: 400, y: 300}, dims: {x:32,y:32}, charge:120},
			],
			goal: {color:FlxColor.SALMON, pos: {x: 240,y:4}, dims: {x:200,y:60}, path:"assets/images/goal_200x60.png"},
			obstacles: [],
			wheels: []
		});
		levelTable.set("Level1",{
			name:"Level1",
			area: { x:0, y:0, w:480, h:512 },
			player: {
				pos: { x: 240, y: 448},
				dims: { x: 64, y:64 },
				force: 10000,
				initialState: MagnetMode.Off,
				path:"assets/images/magnet.png",
				offIdx:0,
				posIdx:1,
				negIdx:2
			},
			items: [
				{path: "assets/images/64_pokeball.png", pos: {x: 240, y: 200}, dims: {x:32,y:32}, charge:250},
				{path: "assets/images/64_pokeball.png", pos: {x: 160, y: 200}, dims: {x:32,y:32}, charge:-250},
				{path: "assets/images/64_pokeball.png", pos: {x: 320, y: 200}, dims: {x:32,y:32}, charge:250},
			],
			goal: {color:FlxColor.PURPLE, pos: {x:140,y:60}, dims: {x:200,y:60}, path:"assets/images/goal_200x60.png"},
			obstacles: [{color:FlxColor.GOLDENROD, pos: {x:100,y:300}, dims: {x:96,y:64}, path:"assets/images/crate.png"}],
			wheels: [{color:FlxColor.GRAY, pos: {x:384,y:120}, dims: {x:96,y:96}, rotationSpeed: 720, path:"assets/images/wheel_96x96.png"}]
		});
		

		
		FlxG.debugger.visible = true;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		currentLevel = "Level0";
		
		worldForeground = new FlxSprite(0, 0, "assets/images/ui_cover.png");
		magnetPaddle = new FlxSprite(0, 0, "assets/images/magnet_paddle.png");
		magnetPaddle.moves = false;
		magnetPaddle.immovable = true;
		
		loadLevel(levelTable.get(currentLevel));
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		worldArea = null;
		player = null;
		goal = null;
		
		items.clear();
		items = null;
		
		deadlyStuff.clear();
		deadlyStuff = null;
		obstacles.clear();
		obstacles = null;
		
		itemCollisions.clear();
		itemCollisions = null;
	}
	
	public function loadLevel(lv:Level):Void
	{
		FlxG.worldBounds.set(lv.area.x + 10, lv.area.y + 10, lv.area.w - 10, lv.area.h - 10);
		worldArea.set(lv.area.x, lv.area.y, lv.area.w, lv.area.h);	
		worldBackground.makeGraphic(cast(worldArea.width,Int),cast(worldArea.height,Int), bgColour);
		worldBackground.setPosition(worldArea.x, worldArea.y);
		
		remove(magnetPaddle);
		add(magnetPaddle);
		magnetPaddle.setPosition(-(512 - worldArea.width)/ 2, worldArea.y + lv.player.pos.y);
		
		if (player != null)
		{
			remove(player);
			player = null;
		}		
		player = new Magnet(lv.player, worldArea, effect);
		refreshMagnetButton();
		add(player);
		
		if (goal != null)
		{
			remove(goal);
			goal = null;
		}
		goal = new Goal(lv.goal,worldArea);		
		add(goal);
		
		obstacles.clear();
		for (obstacleData in lv.obstacles)
		{
			var obs:FlxSprite = new FlxSprite(obstacleData.pos.x + worldArea.x, obstacleData.pos.y + worldArea.y);
			obs.moves = false;
			obs.immovable = true;
			if (obstacleData.path != null)
			{
				obs.loadGraphic(obstacleData.path,false,obstacleData.dims.x,obstacleData.dims.y);
			}
			else
			{
				obs.makeGraphic(obstacleData.dims.x, obstacleData.dims.y, obstacleData.color);
			}
			obstacles.add(obs);
		}
		
		deadlyStuff.clear();
		for (wheelData in lv.wheels)
		{
			var wheel:DeadlyWheel = new DeadlyWheel(wheelData, worldArea);
			deadlyStuff.add(wheel);			
		}
		
		items.clear();
		for (item in lv.items)
		{
			var item:Item = new Item(item, worldArea); 
			items.add(item);
		}
		
		remove(worldForeground);
		add(worldForeground);
		
		remove(movementButton);
		add(movementButton);
		
		remove(magnetButton);
		add(magnetButton);
	}
	
	
	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		processInput();
		
		FlxG.overlap(items, goal, onGoalOverlap);
		FlxG.overlap(items, deadlyStuff, onWheelsOverlap);
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
		super.update();
		
		FlxG.collide(player, items);
		FlxG.collide(magnetPaddle, items);
		FlxG.collide(items, itemCollisions);
	}	
	
	private function processInput():Void
	{
		var keyPressed:Bool = FlxG.keys.anyJustPressed(moveKeys);
		var mousePressed:Bool = FlxG.mouse.justPressed && movementButton.overlapsPoint(new FlxPoint(FlxG.mouse.x, FlxG.mouse.y));
		var touchPressed:Bool = false;		
		for (touch in FlxG.touches.list)
		{
			if (!(touch.overlaps(movementButton)))
			{
				continue;
			}
			if (touch.justPressed)
			{
				touchPressed = true;
				break;
			}				
		}

		if (!movePressed && (keyPressed || mousePressed || touchPressed))
		{
			var mvTarget:MoveTarget = MoveTarget.None;
			if (keyPressed) 
			{
				mvTarget = MoveTarget.Key;
			}
			else if (mousePressed)
			{
				mvTarget = MoveTarget.Mouse;
			}
			else if (touchPressed)
			{
				mvTarget = MoveTarget.Touch;
			}
			OnMovePressed(mvTarget);
		}
		else if (movePressed)
		{
			var keyReleased:Bool = FlxG.keys.anyJustReleased(moveKeys);
			var mouseReleased:Bool = FlxG.mouse.justReleased;
			var touchReleased:Bool = false;
			for (touch in FlxG.touches.list)
			{
				if (touch.justReleased)
				{
					touchReleased = true;
					break;
				}
			}

			if ((keyReleased && movePressTarget == MoveTarget.Key ) || (mouseReleased && movePressTarget == MoveTarget.Mouse) || (touchReleased && movePressTarget == MoveTarget.Touch))
			{
				OnMoveReleased();
			}
		}
		
		var ascending:Bool = true;
		keyPressed = FlxG.keys.anyJustPressed(magnetKeys);
		var swipesDetected:Bool = false;
		for (swipe in FlxG.swipes)
		{
			if (!magnetButton.overlapsPoint(swipe.startPosition)) continue;
			
			if (swipe.distance > 24 && (Math.abs(swipe.angle) < 20 || Math.abs(swipe.angle) > 160))
			{
				swipesDetected = true;
				ascending = Math.abs(swipe.angle) > 160;
				break;
			}
		}
		
		if (keyPressed || swipesDetected)
		{
			OnMagnetCycle(ascending);
		}
	}
	
	private function OnMagnetCycle(ascending:Bool):Void
	{
		player.OnCycleMagnetMode(ascending);
		refreshMagnetButton();		
	}
	private function refreshMagnetButton():Void
	{
		switch (player.mgMode)
		{
			case MagnetMode.Off: 
			{
				magnetButton.animation.play("off");
			}
			case MagnetMode.Positive:
			{
				magnetButton.animation.play("positive");
			}
			case MagnetMode.Negative:
			{
				magnetButton.animation.play("negative");
			}
		}
	}
	
	private function OnMovePressed(mvTarget:MoveTarget):Void
	{
		movementButton.animation.play("pressed");
		player.OnMoveJustPressed();
		movePressed = true;
		movePressTarget = mvTarget;
	}
	
	private function OnMoveReleased ():Void
	{
		movementButton.animation.play("normal");
		player.OnMoveJustReleased();
		movePressed = false;
		movePressTarget = MoveTarget.None;
	}
	
	private function sortByX(order:Int, ob1:Item, ob2:Item):Int 
	{
		return FlxSort.byValues(FlxSort.ASCENDING, ob1.x, ob2.x);		
	}
	
	private function onCollideFinished(x:Item, y:Item):Void
	{
		FlxObject.separate(x, y);	
	}
	
	private function onGoalOverlap(x:Item, y:Goal):Void 
	{
		x.kill();
		trace("Yay! killed one item!");
		
		if (items.countLiving() == 0)
		{				
			if (currentLevel == "Level0")
			{
				currentLevel = "Level1";				
			}
			else 
			{
				currentLevel = "Level0";
			}
			loadLevel(levelTable.get(currentLevel));
		}
	}
	
	private function onWheelsOverlap(x:Item, y:DeadlyWheel):Void
	{
		x.kill();
		trace("D'oh!");
	}
}