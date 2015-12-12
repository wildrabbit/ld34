package org.wildrabbit.magnetpuzzle;

import flixel.FlxSprite;

/**
 * ...
 * @author ith1ldin
 */
class Goal extends FlxSprite
{

	public function new(X:Float=0, Y:Float=0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		
		makeGraphic(200, 60, 0xF0FF00FF);
	}
	
}