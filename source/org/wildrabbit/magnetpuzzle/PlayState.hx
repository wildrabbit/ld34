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
import haxe.remoting.FlashJsConnection;
import openfl.utils.Dictionary;
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
}

typedef WheelData =
{
	var color:Int;
	var pos:Vec2;
	var dims:IntVec2;
	var rotationSpeed:Float;
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
	private var worldDebug:FlxSprite;
	
	private var goal: Goal;
	
	private var player:Magnet;
	private var effect:FlxSprite;
	
	private var currentLevel:String;
	
	private var levelTable: Map<String,Level>;
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		worldArea = new FlxRect(0, 0, FlxG.width, FlxG.height);
		worldDebug = new FlxSprite(worldArea.x, worldArea.y);
		worldDebug.makeGraphic(cast(worldArea.width,Int),cast(worldArea.height,Int), 0x99FFFFFF);
		add(worldDebug);
		
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
			area: { x:100, y:0, w:600, h:600 },
			player: {
				pos: { x: 300, y: 584 },
				dims: { x: 32, y:32 },
				force: 10000,
				initialState: MagnetMode.Off
			},
			items: [
				{path: "assets/images/64_pokeball.png", pos: {x: 300, y: 300}, dims: {x:32,y:32}, charge:120}//,
				//{path: "assets/images/64_pokeball.png", pos: {x: 200, y: 300}, dims: {x:32,y:32}, charge:120},
				//{path: "assets/images/64_pokeball.png", pos: {x: 400, y: 300}, dims: {x:32,y:32}, charge:120},
			],
			goal: {color:FlxColor.SALMON, pos: {x: 300,y:4}, dims: {x:200,y:60}},
			obstacles: [],
			wheels: []
		});
		levelTable.set("Level1",{
			name:"Level1",
			area: { x:100, y:0, w:600, h:600 },
			player: {
				pos: { x: 300, y: 584},
				dims: { x: 32, y:32 },
				force: 10000,
				initialState: MagnetMode.Off
			},
			items: [
				{path: "assets/images/64_pokeball.png", pos: {x: 300, y: 300}, dims: {x:32,y:32}, charge:120},
				{path: "assets/images/64_pokeball.png", pos: {x: 200, y: 300}, dims: {x:32,y:32}, charge:120},
				{path: "assets/images/64_pokeball.png", pos: {x: 400, y: 300}, dims: {x:32,y:32}, charge:120},
			],
			goal: {color:FlxColor.PURPLE, pos: {x:300,y:4}, dims: {x:200,y:60}},
			obstacles: [{color:FlxColor.GOLDENROD, pos: {x:100,y:300}, dims: {x:80,y:60}}],
			wheels: [{color:FlxColor.GRAY, pos: {x:480,y:200}, dims: {x:72,y:72}, rotationSpeed: 360}]
		});
		

		
		FlxG.debugger.visible = true;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		currentLevel = "Level1";
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
		worldArea.set(lv.area.x, lv.area.y, lv.area.w, lv.area.h);	
		worldDebug.makeGraphic(cast(worldArea.width,Int),cast(worldArea.height,Int), 0x99FFFFFF);
		worldDebug.setPosition(worldArea.x, worldArea.y);
		
		if (player != null)
		{
			remove(player);
			player = null;
		}		
		player = new Magnet(lv.player, worldArea, effect);
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
			obs.makeGraphic(obstacleData.dims.x, obstacleData.dims.y, obstacleData.color);
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
	}
	
	
	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		
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
		FlxG.collide(items, itemCollisions);
		
		super.update();
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
			currentLevel = "Level1";				
			//if (currentLevel == "Level0")
			//{
				//currentLevel = "Level1";				
			//}
			//else 
			//{
				//currentLevel = "Level0";
			//}
			loadLevel(levelTable.get(currentLevel));
		}
	}
	
	private function onWheelsOverlap(x:Item, y:DeadlyWheel):Void
	{
		x.kill();
		trace("D'oh!");
	}
}