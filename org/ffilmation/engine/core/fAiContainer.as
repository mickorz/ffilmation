// AI methods

package org.ffilmation.engine.core {
	
		// Imports
		import org.ffilmation.utils.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.logicSolvers.collisionSolver.*

		/**
		* <p>This object provides access to the AI methods of the engine.</p>
		*
		*/
		public class fAiContainer  {
		
			/**
			* These costs are used when finding paths in the scene. You may want to adjust them to change how your characters move.
			* The default values will force the path to avoid going up if possible, and go down as soon as possible. For a walking person,
			* this will result in a more human behaviour */
			private static const COST_ORTHOGONAL:Number = 0.7
			private static const COST_DIAGONAL:Number = 0.9
			private static const COST_GOING_UP:Number = 2
			private static const COST_GOING_DOWN:Number = -1.1
			
			/**
			* This is the maximum depth pathfinding will reach before failing. You may need to adjust this depending on your cell size
			*/
			public static const MAXSEARCHDEPTH:Number = 200

			// Private properties
			private var scene:fScene															// A reference to the scene
			private var withDiagonals:Boolean											// Diagonal movement is allowed ?
			
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
		  * <p>Finds a path between 2 points, using an AStar search algorythm. It works in 3d. This is a CPU-intensive calculation: If you have
		  * several elements trying to find its way around at the same time, it will impact your performance: try to use it sparingly. If you
		  * want an example of how to make a character walk around your scene using this, download the mynameisponcho sources from the download area.</p>
		  *
		  * <p>I took it from <a href="http://blog.baseoneonline.com/?p=87" target="_blank">here</a>. Thank you!</p>
		  *
		  * <p>TODO: 
		  * <ul>
		  * <li>Accept a character as optional parameter and take its dimensions into account.</li>
		  * <li>Include objects and try to find ways around them.</li>
		  * <li>More precise hole calculations. Now it will try to search through any open hole.</li>
		  * </ul></p>
		  *
		  * @param originx Origin point
		  * @param destinyx Destination point
		  * @param withDiagonals Is diagonal movement allowed for this calculation ?
		  *
		  * @return	An array of 3dPoints describing the resulting path. Null if it fails
		  */
		  public function findPath(origin:fPoint3d,destiny:fPoint3d,withDiagonals:Boolean=true):Array {

		  	var open:Array = new Array()
		  	var closed:Array = new Array()
		  	this.withDiagonals = withDiagonals
		  	
		  	// Start coordinates
		  	var start:fCell = this.scene.translateToCell(origin.x,origin.y,origin.z)
		  	
		  	// Get final coordinates
		  	var goal:fCell = this.scene.translateToCell(destiny.x,destiny.y,destiny.z)
		  	if(!goal) return null
		  	
		  	// Start at first node
		  	var node:fCell = start
		  	node.g = 0
		  	node.h = mathUtils.distance3d(node.i,node.j,node.k,goal.i,goal.j,goal.k)
		  	open.push(node)
		  	
		  	var solved:Boolean = false
		  	var i:int = 0
		  	
		  	// Ok let's start
		  	while(!solved) {
		  		
		  		// This line can actually be removed
		  		if (i++ > fAiContainer.MAXSEARCHDEPTH) {
		  			trace("FindPath reached its depth limit without a solution")
		  			return null
		  		}
		  		
		  		// Sort open list by cost
		  		open.sortOn("f",Array.NUMERIC)
		  		if (open.length <= 0) break
		  		node = open.shift()
		  		closed.push(node)
		  		
		  		// Could it be true, are we there?
		  		if (node == goal) {
		  			solved = true
		  			break
		  		}
		  		
		  		// Add neighbours to search list
		  		for each (var n:fCell in this.accessibleFrom(node)) {
		  			if (open.indexOf(n)<0 && closed.indexOf(n)<0) {
		  				open.push(n)
		  				n.parent = node
		  				n.h = mathUtils.distance3d(n.i,n.j,n.k,goal.i,goal.j,goal.k)
		  				n.g = node.g+n.cost
		  			} else {
		  				var newf:Number = n.cost + node.g + n.h
		  				if (newf < n.f) {
		  					n.parent = node
		  					n.g = n.cost + node.g
		  				}
		  			}
		  		}
		  		
		  	}
		  	
		  	trace("Pathfind took "+i+" loops.")
      
		  	// The loop was broken,
		  	// see if we found the solution
		  	if (solved) {
		  		// We did! Format the data for use.
		  		var solution:Array = new Array()
		  		
		  		// Path uses the center point of the involved cells, we need to apply the offset from the real origin coordinate
		  		var dx:Number = origin.x-start.x
		  		var dy:Number = origin.y-start.y
		  		var dz:Number = origin.z-start.z
		  		
		  		// Start at the end...
		  		solution.push(new fPoint3d(destiny.x, destiny.y, destiny.z))
		  		// ...walk all the way to the start to record where we've been...
		  		while (node.parent && node.parent!=start) {
		  			node = node.parent
		  			solution.push(new fPoint3d(node.x+dx, node.y+dy, node.z+dz))
		  		}
		  		// Uncomment this if you want the initial position to be part of the path
		  		//solution.push(new fPoint3d(origin.x, origin.y, origin.z))
		  		
		  		solution.reverse()
		  		return solution
		  		
		  	} else {
		  		
		  		// No solution found... :(
		  		return null
		  		
		  	}
		  }
			
			/**
			* Returns a weighed list of a cells's accessible neighbours
			* 
			* @return An array of fCells.
			*/
			private function accessibleFrom(cell:fCell):Array {
			
				var ret:Array = new Array
				var next:fCell
				
				// Up ?
				if(!cell.walls.up || !fCollisionSolver.testPointCollision(cell.x,cell.y,cell.z,cell.walls.up)) {
					next = this.scene.getCellAt(cell.i,cell.j-1,cell.k)
					if(next) {
						next.cost = fAiContainer.COST_ORTHOGONAL
						ret.push(next)
					}
				}
				// Down ?
				if(!cell.walls.down || !fCollisionSolver.testPointCollision(cell.x,cell.y,cell.z,cell.walls.down)) {
					next = this.scene.getCellAt(cell.i,cell.j+1,cell.k)
					if(next) {
						next.cost = fAiContainer.COST_ORTHOGONAL
						ret.push(next)
					}
				}
				// Left ?
				if(!cell.walls.left || !fCollisionSolver.testPointCollision(cell.x,cell.y,cell.z,cell.walls.left)) {
					next = this.scene.getCellAt(cell.i-1,cell.j,cell.k)
					if(next) {
						next.cost = fAiContainer.COST_ORTHOGONAL
						ret.push(next)
					}
				}
				// Right ?
				if(!cell.walls.right || !fCollisionSolver.testPointCollision(cell.x,cell.y,cell.z,cell.walls.right)) {
					next = this.scene.getCellAt(cell.i+1,cell.j,cell.k)
					if(next) {
						next.cost = fAiContainer.COST_ORTHOGONAL
						ret.push(next)
					}
				}
				// Top ?
				if(!cell.walls.top || !fCollisionSolver.testPointCollision(cell.x,cell.y,cell.z,cell.walls.top)) {
					next = this.scene.getCellAt(cell.i,cell.j,cell.k+1)
					if(next) {
						next.cost = fAiContainer.COST_GOING_UP
						ret.push(next)
					}
				}
				// Bottom ?
				if(!cell.walls.bottom || !fCollisionSolver.testPointCollision(cell.x,cell.y,cell.z,cell.walls.bottom)) {
					next = this.scene.getCellAt(cell.i,cell.j,cell.k-1)
					if(next) {
						next.cost = fAiContainer.COST_GOING_DOWN
						ret.push(next)
					}
				}

			  // Diagonals ?
			  if(this.withDiagonals) {
			  	
					// Up Right ?
					if(!cell.walls.right && !cell.walls.up) {
						next = this.scene.getCellAt(cell.i+1,cell.j-1,cell.k)
						if(next) {
							next.cost = fAiContainer.COST_DIAGONAL
							ret.push(next)
						}
					}

					// Up Left ?
					if(!cell.walls.left && !cell.walls.up) {
						next = this.scene.getCellAt(cell.i-1,cell.j-1,cell.k)
						if(next) {
							next.cost = fAiContainer.COST_DIAGONAL
							ret.push(next)
						}
					}
			  	
					// Down Right ?
					if(!cell.walls.right && !cell.walls.down) {
						next = this.scene.getCellAt(cell.i+1,cell.j+1,cell.k)
						if(next) {
							next.cost = fAiContainer.COST_DIAGONAL
							ret.push(next)
						}
					}

					// Down Left ?
					if(!cell.walls.left && !cell.walls.down) {
						next = this.scene.getCellAt(cell.i-1,cell.j+1,cell.k)
						if(next) {
							next.cost = fAiContainer.COST_DIAGONAL
							ret.push(next)
						}
					}
			  	
			  }
				
				return ret
				
			}
		
		
	}
		
		
}
