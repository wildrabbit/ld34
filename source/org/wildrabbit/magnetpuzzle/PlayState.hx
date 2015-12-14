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
import openfl.Assets;
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
	var index:Int;
}

typedef Level =
{
	var name:String;
	var required:Int;
	var area:LevelRect;
	var player:PlayerData;
	var items:Array<ItemData>;
	var goal:ObstacleData;
	var obstacles:Array<ObstacleData>;
	var wheels:Array<WheelData>;
}

typedef ObstacleData =
{
	var color:String;
	var pos:Vec2;
	var dims:IntVec2;
	@:optional var path:String;
}

typedef WheelData =
{
	var color:String;
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
 
 typedef LevelList = 
 {
	 var levels:Array<Level>;
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
	
	public static inline var bgColour:Int = 0xffecc284;
	
	public static inline var txtColour:Int = 0xff4c2e54;
	
	private var goal: Goal;
	
	private var player:Magnet;
	private var effect:FlxSprite;
	
	private var currentLevelIndex:Int;
	
	private var levelSequence:Array<String>;
	private var levelTable: Map<String,Level>;
	
	private var movementButton: FlxSprite;
	private var magnetButton:FlxSprite;
	private var magnetPressed:Bool;
	
	private var movePressed:Bool;
	private var movePressTarget:MoveTarget;
	
	private static var moveKeys:Array<String> = ["F", "U"];
	private static var magnetKeys:Array<String> = ["J", "H"];
	
	private var necessaryCharges = 1;
	private var successfulCharges = 0;
	private var lostCharges = 0;
	
	private var gameOver:Bool = false;
	private var gameLost:Bool = false;
	private var gameWon:Bool = false;
	
	
	private var sequencePlaying:Bool = false;
	private var newLevelRemaining:Float = 0.0;
	private var newLevelDuration:Float = 2.0;
	
	private var waitingLevelEnd:Bool = false;
	private var waitingDelayRemaining:Float = 0.0;
	private var waitingDelayDuration: Float = 1.5;
	
	private var transitionBg:FlxSprite;
	private var textEndLevel:FlxText;
	private var textNewLevel:FlxText;
	
	private var texts:Array<String>;
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		texts = ["Well done!", "One less to go", "Yay!", "Level beaten", "Awesome", "F*ck yeah!"];
		
		movementButton = new FlxSprite(32, 500);
		movementButton.loadGraphic("assets/images/move_button.png", true, 128, 128);
		movementButton.animation.add("normal", [0], 1, false);
		movementButton.animation.add("pressed", [1], 1, false);
		movePressed = false;
		movePressTarget = MoveTarget.None;
		movementButton.animation.play("normal");
		
		magnetButton = new FlxSprite(320, 500);
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
		
		var levels:String = Assets.getText("assets/data/levels.json");
		trace(levels);
		var levelList:LevelList = Json.parse(levels);
		
		levelTable = new Map<String,Level>();
		levelSequence = new Array<String>();
		for (level in levelList.levels)
		{
			levelSequence.push(level.name);

			levelTable.set(level.name, level);
		}
		
		transitionBg = new FlxSprite(0, 0);
		transitionBg.makeGraphic(FlxG.width, FlxG.height, bgColour);
		
		textEndLevel = new FlxText(90, 240, 300, "...", 24);
		textEndLevel.alignment = "center";
		textEndLevel.color = txtColour;
		textNewLevel = new FlxText(90, 240, 300, "...", 24);
		textNewLevel.color = txtColour;
		textNewLevel.alignment = "center";
		
		sequencePlaying = false;
		waitingLevelEnd = false;
		
		FlxG.debugger.visible = true;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		worldForeground = new FlxSprite(0, 0, "assets/images/ui_cover.png");
		magnetPaddle = new FlxSprite(0, 0, "assets/images/magnet_paddle.png");
		magnetPaddle.moves = false;
		magnetPaddle.immovable = true;
		
		if (levelSequence.length > 0)
		{
			currentLevelIndex = 0;
			loadLevel(levelTable.get(levelSequence[currentLevelIndex]));
		}
		
		FlxG.sound.playMusic("assets/music/music.wav");
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
		necessaryCharges = lv.required;
		
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
				obs.makeGraphic(obstacleData.dims.x, obstacleData.dims.y, Std.parseInt(obstacleData.color));
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
		
		remove(transitionBg);
		add(transitionBg);
		transitionBg.visible = false;
		
		remove(textEndLevel);
		add(textEndLevel);
		textEndLevel.visible = false;
		
		remove(textNewLevel);
		add(textNewLevel);
		textNewLevel.visible = false;
		
		remove(worldForeground);
		add(worldForeground);
		
		remove(movementButton);
		add(movementButton);
		
		remove(magnetButton);
		add(magnetButton);
		
		lostCharges = 0;
		successfulCharges = 0;
		
		sequencePlaying = true;
		newLevelRemaining = newLevelDuration;
		showNewLevel();
	}
	
	
	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		if (waitingLevelEnd)
		{
			if (waitingDelayRemaining < waitingDelayDuration * 0.7)			
			{
				if (waitingDelayRemaining <= 0 || (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed || FlxG.touches.justStarted(FlxG.touches.list).length > 0))
				{
					hideEndLevel();
					nextLevel();
					waitingLevelEnd = false;					
				}
				else
				{
					waitingDelayRemaining -= FlxG.elapsed;
				}
				
			}
			else
			{
				waitingDelayRemaining -= FlxG.elapsed;
			}
			return;
		}
		if (sequencePlaying)
		{
			if (newLevelRemaining <= 0)
			{
				newLevelRemaining = 0;
				sequencePlaying = false;
				hideNewLevel();
			}
			else newLevelRemaining -= FlxG.elapsed;
			return;
		}
		
		if (gameOver)
		{
			if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed || FlxG.touches.justStarted(FlxG.touches.list).length > 0)
			{
				resetGame();
				FlxG.sound.play("assets/sounds/click.wav");
				FlxG.switchState(new MenuState());
				FlxG.sound.music.stop();
			}
			return;			
		}
		
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
		#if debug
			if (FlxG.keys.anyJustPressed(["S"]))
			{
				nextLevel(true);
			}
		#end
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
		FlxG.sound.play("assets/sounds/click.wav");
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
		FlxG.sound.play("assets/sounds/click.wav");
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
		successfulCharges++;
		trace("Yay, took one item to the goal!");
		FlxG.sound.play("assets/sounds/arrive.wav");
		
		onChargeKilled(x);
	}
	
	private function onWheelsOverlap(x:Item, y:DeadlyWheel):Void
	{
		lostCharges++;
		trace("D'oh! Got hit!!");
		FlxG.sound.play("assets/sounds/wheel.wav");
		onChargeKilled(x);
	
	}
	
	private function onChargeKilled(charge:Item):Void
	{
		charge.kill();
		
		if (items.countLiving() == 0)
		{
			if ( successfulCharges >= necessaryCharges)
			{
				waitingLevelEnd = true;
				waitingDelayRemaining = waitingDelayDuration;
				showLevelEnd();
				//nextLevel();				
			}
			else 
			{
				gameOver = true;
				gameLost = true;
				gameWon = false;
				
				FlxG.switchState(new GameLostState());
				FlxG.sound.music.stop();
			}	
		}
	}
	
	private function showLevelEnd():Void
	{
		transitionBg.visible = true;
		var idx:Int = Math.floor (Math.random() * texts.length);
		textEndLevel.text = texts[idx];
		textEndLevel.visible = true;
	}
	
	private function hideEndLevel():Void
	{
		transitionBg.visible = false;
		textEndLevel.visible = false;
	}
	
	private function showNewLevel():Void
	{
		transitionBg.visible = true;
		textNewLevel.text = "Level " + Std.string(currentLevelIndex + 1) + ": " + levelTable.get(levelSequence[currentLevelIndex]).name;
		textNewLevel.visible = true;
	}
	
	private function hideNewLevel():Void
	{
		transitionBg.visible = false;
		textNewLevel.visible = false;
	}
	
	private function nextLevel (wrap:Bool = false):Void	
	{
		currentLevelIndex++;
		if (currentLevelIndex < levelSequence.length)
		{
			loadLevel(levelTable.get(levelSequence[currentLevelIndex]));				
		}
		else 
		{
			if (wrap)
			{
				currentLevelIndex = 0;
				loadLevel(levelTable.get(levelSequence[currentLevelIndex]));
			}
			else {
				gameOver = true;
				gameLost = false;
				gameWon = true;
				
				FlxG.switchState(new GameWonState());
				FlxG.sound.music.stop();				
			}
			
		}
	}
	
	private function resetGame():Void
	{
		currentLevelIndex = 0;
		if (currentLevelIndex < levelSequence.length)
		{
			loadLevel(levelTable.get(levelSequence[currentLevelIndex]));
			gameOver = gameWon = gameLost = false;
		}
		else 
		{
			trace("WTF...no levels");
		}
	}
}