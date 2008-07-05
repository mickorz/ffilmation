// CAMERA

package org.ffilmation.engine.core {
	
		// Imports

		/**
		* <p>This object provides access to the AI methods of the engine. Unfortunately,
		* in this release the aren't any as they we not mature enought. But the object is already there for reference</p>
		*
		*/
		public class fAiContainer  {
		
			private var scene:fScene
			
			/**
			* Constructor for the fAiContainer class
			*
			* @param scene The scene associated to this AI
		  *
			* @private
			*/
			function fAiContainer(scene:fScene) {
			
				 this.scene = scene		 
				 
			}

		  /**
		  * Finds a path between 2 points, using an A* search algorythm. It works in 3d.
		  *
		  * @return	An array of 3dPoints describing the resulting path
		  */
/*		  public function findPath(originx:Number,originy:Number,originz:Number,destinyx:Number,destinyy:Number,destinyz:Number):Array {

		  	trace("Starting to solve: "+start+" to "+goal);
		  	open = new Array();
		  	closed = new Array();
		  	visited = new Array();
		  	
		  	
		  	var node:AStarNode = start;
		  	node.h = dist(goal);
		  	open.push(node);
		  	
		  	var solved:Boolean = false;
		  	var i:int = 0;
		  	
		  	
		  	// Ok let's start
		  	while(!solved) {
		  		
		  		// This line can actually be removed
		  		if (i++ > 10000) throw new Error("Overflow");
		  		
		  		// Sort open list by cost
		  		open.sortOn("f",Array.NUMERIC);
		  		if (open.length <= 0) break;
		  		node = open.shift();
		  		closed.push(node);
		  		
		  		// Could it be true, are we there?
		  		if (node.x == goal.x && node.y == goal.y) {
		  			// We found a solution!
		  			solved = true;
		  			break;
		  		}
		  		
		  		for each (var n:AStarNode in neighbors(node)) {
		  			
		  			if (!hasElement(open,n) && !hasElement(closed,n)) {
		  				open.push(n);
		  				n.parent = node;
		  				n.h = dist(n);
		  				n.g = node.g;
		  			} else {
		  				var f:Number = n.g + node.g + n.h;
		  				if (f < n.f) {
		  					n.parent = node;
		  					n.g = node.g;
		  				}
		  			}
		  			visit (n);
		  		}
		  		
		  		
		  	}
      
		  	// The loop was broken,
		  	// see if we found the solution
		  	if (solved) {
		  		trace("Solved");
		  		// We did! Format the data for use.
		  		var solution:Array = new Array();
		  		// Start at the end...
		  		solution.push(new IntPoint(node.x, node.y));
		  		// ...walk all the way to the start to record where we've been...
		  		while (node.parent && node.parent!=start) {
		  			node = node.parent;
		  			solution.push(new IntPoint(node.x, node.y));
		  		}
		  		// ...and add our initial position.
		  		solution.push(new IntPoint(node.x, node.y));
		  		
		  		return solution;
		  	} else {
		  		// No solution found... :(
		  		// This might be something else instead
		  		// (like an array with only the starting position)
		  		return null;
		  	}
		  }
			*/
			
		}
}

