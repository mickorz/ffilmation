package org.ffilmation.engine.elements {
	
		// Imports
		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*

		/**
		* <p>Arbitrary-sized tiles that form each floor in your scene</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT.<br>
		* Floors are created when the scene is processed</p>
		*
		*/
		public class fFloor extends fPlane {
		
			// Private properties
			
			/** @private */
			public var gWidth:Number
			/** @private */
			public var gDepth:Number
			/** @private */
			public var i:Number
			/** @private */
			public var j:Number
			/** @private */
			public var k:Number
			
			// Public properties

			/**
			* Floor width in pixels. Size along x-axis
			*/
			public var width:Number
			
			/**
			* Floor depth in pixels. Size along y-axis
			*/
			public var depth:Number

			/** @private */
	    public var bounds:fPlaneBounds
			   
			// Constructor
			/** @private */
			function fFloor(defObj:XML,scene:fScene):void {
			
			   // Dimensions, parse size and snap to gride
			   this.gWidth = Math.round(defObj.@width/scene.gridSize)
			   this.gDepth = Math.round(defObj.@height/scene.gridSize)
			   this.width = scene.gridSize*this.gWidth
			   this.depth = scene.gridSize*this.gDepth
			   
			   // Previous
				 super(defObj,scene,this.width,this.depth)
			   
			   // Specific coordinates
			   this.i = Math.round(defObj.@x/scene.gridSize)
			   this.j = Math.round(defObj.@y/scene.gridSize)
			   this.k = Math.round(defObj.@z/scene.levelSize)
			   this.x0 = this.x = this.i*scene.gridSize
			   this.y0 = this.y = this.j*scene.gridSize
			   this.top = this.z = this.k*scene.levelSize
			   this.x1 = this.x0+this.width
			   this.y1 = this.y0+this.depth
			   
			   // Bounds
			   this.bounds = new fPlaneBounds(this)
			   
			}

			// Is this floor in front of other plane ? Note that a false return value does not imply the opposite: None of the planes
			// may be in front of each other
			/** @private */
			public override function inFrontOf(p:fPlane):Boolean {
				
					if(p is fWall) {
						  var wall:fWall = p as fWall
						  if(wall.vertical) {
								if( (this.i<wall.i && (this.j+this.gDepth)>wall.j && this.k>wall.k) 
								    //|| ((this.j+this.gDepth)>wall.j && (this.i+this.gWidth)<=wall.i)
								    //|| (this.i<=wall.i && (this.j+this.gDepth)>wall.j && this.k>=(wall.k+wall.gHeight)) 
								    ) return true
								return false
			     		} else {
								if( (this.i<(wall.i+wall.size) && (this.j+this.gDepth)>wall.j && this.k>wall.k)
								    //|| (this.i<(wall.i+wall.size) && this.j>=wall.j)
								    //|| (this.i<(wall.i+wall.size) && (this.j+this.gDepth)>wall.j && this.k>=(wall.k+wall.gHeight))
								    ) return true
								return false
			     		}
			    } else {
			     		var floor:fFloor = p as fFloor		
			     		if ( (this.i<(floor.i+floor.gWidth) && (this.j+this.gDepth)>floor.j && this.k>floor.k) 
			     		      || ((this.j+this.gDepth)>floor.j && (this.i+this.gWidth)<=floor.i)
			     		      || (this.i>=floor.i && this.i<(floor.i+floor.gWidth) && this.j>=(floor.j+floor.gDepth)) 
			     		    ) return true
			     		return false
			    }
					
			}

			/** @private */
			public override function distanceTo(x:Number,y:Number,z:Number):Number {
			
				 // Easy case
				 if(x>=this.x && x<=this.x+this.width && y>=this.y && y<=this.y+this.depth) return Math.abs(this.z-z)
				 
				 
				 if(y<this.y) {
				 	
				 		if(x<this.x) return mathUtils.distance3d(x,y,z,this.x,this.y,this.z)
				 		if(x>this.x+this.width) return mathUtils.distance3d(x,y,z,this.x+this.width,this.y,this.z)
				 	  return mathUtils.distance(y,z,this.y,this.z)
				 	
				 }
				 if(y>(this.y+this.depth)) {
				 	
				 		if(x<this.x) return mathUtils.distance3d(x,y,z,this.x,this.y+this.depth,this.z)
				 		if(x>this.x+this.width) return mathUtils.distance3d(x,y,z,this.x+this.width,this.y+this.depth,this.z)
				 	  return mathUtils.distance(y,z,this.y+this.depth,this.z)
				 	
				 }
				 
		 		 if(x<this.x) return mathUtils.distance(x,z,this.x,this.z)
				 return mathUtils.distance(x,z,this.x+this.width,this.z)

			
			}

			/** @private */
			public function disposeFloor():void {

	    	this.bounds = null
				this.disposePlane()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposeFloor()
			}		

			
		}
}
