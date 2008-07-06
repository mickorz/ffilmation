package org.ffilmation.engine.elements {
	
		// Imports
		import flash.display.*
		import flash.geom.Point
		import flash.geom.Matrix
		import flash.geom.Rectangle
		import flash.geom.ColorTransform
		import flash.utils.getDefinitionByName
		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*

		/**
		* <p>Arbitrary-sized tiles that form each floor in your scene</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT.<br>
		* Floors are created when the scene is processed</p>
		*
		*/
		public class fFloor extends fPlane {
		
			// Static properties and Render cache
			private static var floorProjectionCache:fFloorProjectionCache = new fFloorProjectionCache()
			private static var wallProjectionCache:Object = []
			private static var objectProjectionCache:Object = []
			private static var matrix:Matrix = new Matrix(0.7071075439453125,-0.35355377197265625,0.7071075439453125,0.35355377197265625,0,0)
						
			// Private properties
	    private var polyClip:Array
			
			// Public properties
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
			/** @private */
			private var lastCharacterCollision:fPlaneBounds
			   
			// Constructor
			/** @private */
			function fFloor(container:MovieClip,defObj:XML,scene:fScene):void {
			
				 // Generate sprites
				 var mask:Sprite = new Sprite()
				 var destination:Sprite = new Sprite()
				 container.addChild(mask)
				 mask.mouseEnabled = false
				 mask.addChild(destination)

			   // Deform floor to match perspective
			   container.transform.matrix = fFloor.matrix
			   
			   // Dimensions, parse size and snap to gride
			   this.gWidth = Math.round(defObj.@width/scene.gridSize)
			   this.gDepth = Math.round(defObj.@height/scene.gridSize)
			   this.width = scene.gridSize*this.gWidth
			   this.depth = scene.gridSize*this.gDepth

			   // Previous
				 super(defObj,scene,this.width,this.depth,destination,container)
			   
			   // Specific coordinates
			   this.i = Math.round(defObj.@x/scene.gridSize)
			   this.j = Math.round(defObj.@y/scene.gridSize)
			   this.x0 = this.x = this.i*scene.gridSize
			   this.y0 = this.y = this.j*scene.gridSize
			   this.k = Math.round(defObj.@z/scene.levelSize)
			   this.top = this.z = this.k*scene.levelSize
			   this.x1 = this.x0+this.width
			   this.y1 = this.y0+this.depth
			   
			   // Bounds
			   this.bounds = new fPlaneBounds()
			   this.bounds.x = this.x
			   this.bounds.y = this.y
			   this.bounds.z = this.z
			   this.bounds.x0 = this.x
			   this.bounds.x1 = this.x+this.width
			   this.bounds.y0 = this.x
			   this.bounds.y1 = this.x+this.depth
			   this.bounds.width = this.width
			   this.bounds.depth = this.depth

				 // Scale
			   mask.scrollRect = new Rectangle(0, 0, this.width, this.depth)
			   
				 // Create polygon bounds, for clipping algorythm
				 this.polyClip = [ new Point(this.x,this.y),
				 							     new Point(this.x+this.width,this.y),
				 							     new Point(this.x+this.width,this.y+this.depth),
				 							     new Point(this.x,this.y+this.depth) ]
			
			}


			// Gives geometry container the proper dimensions
			/** @private */
			public override function setDimensions(lClip:DisplayObject):void {
				lClip.width = this.width
				lClip.height = this.depth
		  }


			/** @private */
			public override function place():void {
			   // Place in position
			   var coords:Point = this.scene.translateCoords(this.x,this.y,this.z)
			   this.container.x = coords.x
			   this.container.y = coords.y+1
			   
			}

			// Is this floor in front of other plane ? Note that a false return value doesn not imply the opposite: None of the planes
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

			// Test a point's collision
			/** @private */
			public override function testPointCollision(x:Number,y:Number,z:Number):Boolean {		
			
				if(!this.solid) return false
				
				// Loop through holes and see if point is inside one
				for(var h:int=0;h<this.holes.length;h++) {
				
					 	if(this.holes[h].open) {
						 	var hole:fPlaneBounds = this.holes[h].bounds
						 	if(hole.x<=x && (hole.x+hole.width)>=x && hole.y<=y && (hole.y+hole.height)>=y) {
							 		return false
						 	}
			 	  	}
				}				

				return true

			}


			// Test primary fCollision from an object and this floor
			/** @private */
			public override function testPrimaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {
				
				var obj:fObject = other as fObject

				if(obj.z>this.z || obj.top<this.z) return null
				
				var x:Number, y:Number
				
				x = obj.x
				y = obj.y

				// Loop through holes and see if point is inside one
				for(var h:int=0;h<this.holes.length;h++) {
				
					 	if(this.holes[h].open) {
						 	var hole:fPlaneBounds = this.holes[h].bounds
						 	if(hole.width>=(2*obj.radius) && hole.height>=obj.height && hole.x<=x && (hole.x+hole.width)>=x && hole.y<=y && (hole.y+hole.height)>=y) {
							 		return null
						 	}
			 			}  	
				}				

				// Return fCollision point
				if(dz>0) return new fCollision(-1,-1,this.z-obj.height-0.01)
				else return new fCollision(-1,-1,this.z+0.01)
				
			}


			// Tests shadow
			/** @private */
			public override function testShadow(other:fRenderableElement,x:Number,y:Number,z:Number):Number {

				 try {
				 	if(other is fFloor) return this.testFloorShadow(other as fFloor,x,y,z)
			   	if(other is fWall) return this.testWallShadow(other as fWall,x,y,z)
			   	if(other is fObject) return this.testObjectShadow(other as fObject,x,y,z)
			   } catch(e:Error) {
			   	return fCoverage.SHADOWED
			   }
					
				 // Else
				 return fCoverage.NOT_SHADOWED	
			}

			// Tests if other floor projects shadow over this one
			private function testFloorShadow(other:Object,x:Number,y:Number,z:Number):Number {
			   
			   var len:int
			   
			   if(other.z>this.z && other.z<z) {
			     
			      var dz:Number = 1+(other.z-this.z)/(z-other.z)
			      
			      var pLeft:Number = x+(other.x-x)*dz
			      if(pLeft>(this.x+this.width)) return fCoverage.NOT_SHADOWED
			
			      var pUp:Number = y+(other.y-y)*dz
			   		if(pUp>(this.y+this.depth)) return fCoverage.NOT_SHADOWED
			
			      var pDown:Number = y+(other.y+other.depth-y)*dz
			   		if(pDown<this.y) return fCoverage.NOT_SHADOWED
			
			      var pRight:Number = x+(other.x+other.width-x)*dz
					  if(pRight<this.x) return fCoverage.NOT_SHADOWED
						
			      if(pUp<=this.y && pDown>=(this.y+this.depth) && pLeft<=this.x && pRight>=(this.x+this.width)) {
			      	
			      	  // Test holes
			      	  if(other is fFloor) {
			      	  	len = other.holes.length
			      	  	for(var h:int=0;h<len;h++) {
			      	  		if(this.testFloorShadow(other.holes[h].bounds,x,y,z)!=fCoverage.NOT_SHADOWED) return fCoverage.SHADOWED
			      	    }
			      	  }
			      	
			      		return fCoverage.COVERED
			      }
			      else return fCoverage.SHADOWED
			   }   
			   else return fCoverage.NOT_SHADOWED
			
			}
			
			// Tests if wall casts shadow upon this floor from given coordinates
			private function testWallShadow(wall:Object,x:Number,y:Number,z:Number):Number {
			
			   if(wall.top<=this.z || wall.z>=z) return fCoverage.NOT_SHADOWED
			   
			   if(wall.vertical) {
			
			      if(wall.x<=x) {
			
			         if(wall.x<this.x) return fCoverage.NOT_SHADOWED
			
			         if(wall.top<z) {
			   				  var dz:Number = 1+(wall.top-this.z)/(z-wall.top)
			         	  var pLeft:Number = -1+x+(wall.x-x)*dz
			     	      if(pLeft>(this.x+this.width)) return fCoverage.NOT_SHADOWED
							 }
							 else pLeft = this.x
			
			         if(wall.y0>(this.y+this.depth)) {
			         		var pUp:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pLeft,1,pLeft,-1).y-1
			         		if(pUp>(this.y+this.depth)) return fCoverage.NOT_SHADOWED
			         }
			         if(wall.y1<this.y) {
			         		var pDown:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pLeft,1,pLeft,-1).y+1
			         		if(pDown<this.y) return fCoverage.NOT_SHADOWED
							 }				 
							 
							 if(wall.z>this.z) {
						 	 		var dzb:Number = 1+(wall.z-this.z)/(z-wall.z)
									var pRight:Number = 1+x+(wall.x-x)*dzb
								  if(pRight<this.x) return fCoverage.NOT_SHADOWED
			         }
			
			         return fCoverage.SHADOWED
			
			      } else {
			
			         if(wall.x>(this.x+this.width)) {
			         	return fCoverage.NOT_SHADOWED
			         }
			
			         if(wall.top<z) {
			   				  dz = 1+(wall.top-this.z)/(z-wall.top)
			   	        pLeft = 1+x+(wall.x-x)*dz
			            if(pLeft<this.x) {
			            	return fCoverage.NOT_SHADOWED
			            }
			         }
			         else pLeft = this.x+this.width
			         
			         if(wall.y0>(this.y+this.depth)) {
			         		pUp = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pLeft,1,pLeft,-1).y-1
			         		if(pUp>(this.y+this.depth)) {
			         			return fCoverage.NOT_SHADOWED
			         		}
			         }
			         
			         if(wall.y1<this.y) {
			         		pDown = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pLeft,1,pLeft,-1).y+1
			         		if(pDown<this.y) {
			         			return fCoverage.NOT_SHADOWED
			         		}
	         		 }
			
							 if(wall.z>this.z) {
						 	 		dzb = 1+(wall.z-this.z)/(z-wall.z)
									pRight = -1+x+(wall.x-x)*dzb
								  if(pRight>(this.x+this.width)) return fCoverage.NOT_SHADOWED
							 }
							 
			         return fCoverage.SHADOWED
			
			      }
			
			   } else {
			   
			      if(wall.y<y) {
			
			         if(wall.y<this.y) return fCoverage.NOT_SHADOWED
			
			         if(wall.top<z) {
			   				  dz = 1+(wall.top-this.z)/(z-wall.top)
					        pUp = -1+y+(wall.y-y)*dz
			            if(pUp>(this.y+this.depth)) return fCoverage.NOT_SHADOWED
			         }
			         else pUp = this.y         
			
							 if(wall.x0>(this.x+this.width)) {
			         		pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pUp,-1,pUp).x-1
			         		if(pLeft>(this.x+this.width)) return fCoverage.NOT_SHADOWED
			         }
			         if(wall.x1<this.x) {
			         		pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pUp,-1,pUp).x+1
			         		if(pRight<this.x) return fCoverage.NOT_SHADOWED
							 }
							
							 if(wall.z>this.z) {
						 	 		dzb = 1+(wall.z-this.z)/(z-wall.z)
									pDown = 1+y+(wall.y-y)*dzb
								  if(pDown<this.y) return fCoverage.NOT_SHADOWED
							 }
			
			         return fCoverage.SHADOWED
			
			      } else {
			
			         if(wall.y>(this.y+this.depth)) return fCoverage.NOT_SHADOWED
			
			         if(wall.top<z) {
			   				 dz = 1+(wall.top-this.z)/(z-wall.top)
				         pUp = 1+y+(wall.y-y)*dz
			  	       if(pUp<this.y) return fCoverage.NOT_SHADOWED
							 }
							 else pUp = this.y+this.depth				 
			
							 if(wall.x0>(this.x+this.width)) {
			         		pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pUp,-1,pUp).x-1
			         		if(pLeft>(this.x+this.width)) return fCoverage.NOT_SHADOWED
			         }
			         if(wall.x1<this.x) {
			         		pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pUp,-1,pUp).x+1
			         		if(pRight<this.x) return fCoverage.NOT_SHADOWED
							 }
			
							 if(wall.z>this.z) {
						 	 		dzb = 1+(wall.z-this.z)/(z-wall.z)
									pDown = -1+y+(wall.y-y)*dzb
								  if(pDown>(this.y+this.depth)) return fCoverage.NOT_SHADOWED
							 }
			
			         return fCoverage.SHADOWED
			         
			      }
			
			   }
			
			
			}
			
			// Tests if object casts shadow upon this floor from given coordinates
			private function testObjectShadow(obj:fObject,x:Number,y:Number,z:Number):Number {
			
			   // Simple cases
			   if(obj.top<=this.z || obj.z>=z) return fCoverage.NOT_SHADOWED
			   if(obj.y<this.y && y>obj.y) return fCoverage.NOT_SHADOWED
			   if(obj.y>(this.y+this.depth) && y<obj.y) return fCoverage.NOT_SHADOWED
			   if(obj.x<this.x && x>obj.x) return fCoverage.NOT_SHADOWED
			   if(obj.x>(this.x+this.width) && x<obj.x) return fCoverage.NOT_SHADOWED
				 
				 // Get first polygon (object)
				 var proj:fObjectProjection = obj.getProjection(this.z,x,y,z)
				 if(proj==null) return fCoverage.NOT_SHADOWED
				 
				 
				 var poly1:Array = proj.polygon
				 
				 // Check fCollision
				 var result:Boolean = polygonUtils.checkPolygonCollision(poly1,this.polyClip)
				
				 if(result) return fCoverage.SHADOWED
				 else return fCoverage.NOT_SHADOWED
			
			
			}

			/** @private */
			public override function processRenderStart(light:fLight):void {

			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
			   
			   // fLight limits
			   if(light.size==Infinity) {
			      
			      lightStatus.lUp = this.y-1
			      lightStatus.lDown = this.y+this.depth+1
			      lightStatus.lLeft = this.x-1
			      lightStatus.lRight = this.x+this.width+1
			      
			   } else {
			
			      lightStatus.lUp = Math.max(light.y-light.size,this.y-1)
			      lightStatus.lDown = Math.min(light.y+light.size,this.y+this.depth+1)   
			      lightStatus.lLeft = Math.max(light.x-light.size,this.x-1)   
			      lightStatus.lRight = Math.min(light.x+light.size,this.x+this.width+1)
			
			   }
			
			}
			
			// Render ( draw ) light
			/** @private */
			public override function renderLight(light:fLight):void {
			
			   var status:fLightStatus = this.lightStatuses[light.uniqueId]
			   var lClip:Sprite = this.lightClips[light.uniqueId]
				
			   if(status.lightZ != light.z) {
			      status.lightZ = light.z
			      this.setLightZ(light)
			   }    
			
			   // Move light
	   	   this.setLightCoordinates(light,light.x-this.x,light.y-this.y)
			
			}
			
			// Calculates and projects shadows upon this floor
			/** @private */
			public override function renderShadowInt(light:fLight,other:fRenderableElement,msk:Sprite):void {
				
			   if(other is fFloor) this.renderFloorShadow(light,other as fFloor,msk)
			   if(other is fWall) this.renderWallShadow(light,other as fWall,msk)
			   if(other is fObject) this.renderObjectShadow(light,other as fObject,msk)
			}
			
			/** 
			* Resets shadows. This is called when the fEngine.shadowQuality value is changed
			* @private
			*/
			public override function resetShadowsInt():void {
				for(var i in fFloor.objectProjectionCache) {
					var a:Array = fFloor.objectProjectionCache[i]
					for(var j in a) {
						 try {
						 	var clip:Sprite = a[j]
						 	clip.parent.parent.removeChild(clip.parent)
						 	delete a[j]
						 } catch (e:Error) {}
					}
					delete fFloor.objectProjectionCache[i]
				}
			}

			// Calculates and projects shadows of objects upon this floor
			private function renderObjectShadow(light:fLight,other:fObject,msk:Sprite):void {
			   
				 // Too far away ?
				 if((other.z-this.z)>fObject.SHADOWRANGE) return

				 // Get projection
				 var proj:fObjectProjection = other.getProjection(this.z,light.x,light.y,light.z)
				 
				 if(proj==null) return

				 // Cache or new Movieclip ?
				 if(!fFloor.objectProjectionCache[this.uniqueId+"_"+light.uniqueId]) {
				 		fFloor.objectProjectionCache[this.uniqueId+"_"+light.uniqueId] = new Array()
				 }
				 var cache:Array = fFloor.objectProjectionCache[this.uniqueId+"_"+light.uniqueId]
				 if(!cache[other.uniqueId]) {
				 		cache[other.uniqueId] = other.getShadow(this)
				 		if(!other.simpleShadows) cache[other.uniqueId].transform.colorTransform = new ColorTransform(0,0,0,1,0,0,0,0)
				 }
				 
				 var distance:Number = (other.z-this.z)/fObject.SHADOWRANGE

				 // Draw
				 var clip:Sprite = cache[other.uniqueId]
				 msk.addChild(clip.parent)
				 clip.alpha = 1-distance

				 // Rotate and deform
		 		 clip.parent.x = proj.origin.x-this.x
				 clip.parent.y = proj.origin.y-this.y
				 if(!other.simpleShadows) {
				 		clip.height = proj.size*(1+fObject.SHADOWSCALE*distance)
				 		clip.scaleX = 1+fObject.SHADOWSCALE*distance
				 		clip.parent.rotation = 90+mathUtils.getAngle(light.x,light.y,other.x,other.y)
				 }
				 
			}
			
			// Delete character shadows upon this floor
			/** @private */
			public override function unrenderShadowAlone(light:fLight,other:fRenderableElement):void {
			   
			   // Select mask
			   try {

					var msk:Sprite
					var o:fCharacter = other as fCharacter
			   	if(o.simpleShadows) msk = this.simpleShadowsLayer
			   	else msk = this.lightShadows[light.uniqueId]
			   
			 	 	var cache = fFloor.objectProjectionCache[this.uniqueId+"_"+light.uniqueId]
			 	 	var clip:Sprite = cache[other.uniqueId]
			 	 	msk.removeChild(clip.parent)
			 	 } catch(e:Error) {
			 	 }
			 	 

			}

			// Calculates and projects shadows of another floor upon this floor
			private function renderFloorShadow(light:fLight,other:fFloor,msk:Sprite):void {
			   
			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
			   var len:int
			
			   // Draw mask
			   msk.graphics.beginFill(0x000000,100)
			   
			   // Read cache or write cache ?
			   if(fFloor.floorProjectionCache.x!=light.x || fFloor.floorProjectionCache.y!=light.y
			      || fFloor.floorProjectionCache.z!=light.z || fFloor.floorProjectionCache.fl!=other ) {
			   	
					  // New Key
			   		fFloor.floorProjectionCache.x=light.x 	
			   		fFloor.floorProjectionCache.y=light.y 	
			   		fFloor.floorProjectionCache.z=light.z 	
			   		fFloor.floorProjectionCache.fl=other
			
			   		// New value
			   		fFloor.floorProjectionCache.points = this.calculateFloorProjection(light.x,light.y,light.z,other.bounds)
			   		fFloor.floorProjectionCache.holes = []
					  for(h=0;h<other.holes.length;h++) {
					 		fFloor.floorProjectionCache.holes[h] = this.calculateFloorProjection(light.x,light.y,light.z,other.holes[h].bounds)
					  }
			
			   }
			
				 var points:fFloorProjection = fFloor.floorProjectionCache.points
			   var pUp:Number = Math.max(points.pUp,lightStatus.lUp)
			   var pDown:Number = Math.min(points.pDown,lightStatus.lDown)
			   var pLeft:Number = Math.max(points.pLeft,lightStatus.lLeft)
			   var pRight:Number = Math.min(points.pRight,lightStatus.lRight)
			   msk.graphics.moveTo(pLeft-this.x,pUp-this.y)
				 msk.graphics.lineTo(pLeft-this.x,pDown-this.y)
				 msk.graphics.lineTo(pRight-this.x,pDown-this.y)
				 msk.graphics.lineTo(pRight-this.x,pUp-this.y)

		
				 // For each hole, draw light
				 len = other.holes.length
				 
				 for(var h:int=0;h<len;h++) {
				 	
				 		if(other.holes[h].open) {
					 		points = fFloor.floorProjectionCache.holes[h]
				    	pUp = Math.max(points.pUp,lightStatus.lUp)
			      	pDown = Math.min(points.pDown,lightStatus.lDown)
			      	pLeft = Math.max(points.pLeft,lightStatus.lLeft)
			      	pRight = Math.min(points.pRight,lightStatus.lRight)
			      	msk.graphics.moveTo(pLeft-this.x,pUp-this.y)
				    	msk.graphics.lineTo(pLeft-this.x,pDown-this.y)
				    	msk.graphics.lineTo(pRight-this.x,pDown-this.y)
				    	msk.graphics.lineTo(pRight-this.x,pUp-this.y)
				    }
				 }
			
			   msk.graphics.endFill()

			}

			private function calculateFloorProjection(x:Number,y:Number,z:Number,other:fPlaneBounds):fFloorProjection {
			
			   // Calculate shadow projection
			   var dz:Number = 1+(other.z-this.z)/(z-other.z)
			
			   var pUp:Number = y+(other.y-y)*dz-1
			   var pDown:Number = y+(other.y+other.depth-y)*dz+1
			   var pLeft:Number = x+(other.x-x)*dz-1
			   var pRight:Number = x+(other.x+other.width-x)*dz+1
			
			   return new fFloorProjection(pUp,pDown,pLeft,pRight)
			
			}
			
			// Calculates and draws the shadow of a given wall from a given light
			private function renderWallShadow(light:fLight,wall:fWall,msk:Sprite):void {
			   
			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
				 var len:int
			   
				 var cache:fWallProjectionCache = fFloor.wallProjectionCache[this.uniqueId+"_"+wall.uniqueId]
				 if(!cache) cache = fFloor.wallProjectionCache[this.uniqueId+"_"+wall.uniqueId] = new fWallProjectionCache()
				 	
			   // Update cache ?
			   if(cache.x!=light.x || cache.y!=light.y || cache.z!=light.z) {
			   	
					  // New Key
			   		cache.x=light.x 	
			   		cache.y=light.y 	
			   		cache.z=light.z 	
			
			   		// New value
			   		cache.points = this.calculateWallProjection(light.x,light.y,light.z,wall.bounds)
			   		cache.holes = []
			   		len = wall.holes.length
					  for(h=0;h<len;h++) {
					 		cache.holes[h] = this.calculateWallProjectionHole(light.x,light.y,light.z,wall.holes[h].bounds)
					  }
			
				 }
			
				 // Clipping viewport
				 var vp:vport = new vport()
				 vp.x_min = lightStatus.lLeft
				 vp.x_max = lightStatus.lRight
				 vp.y_min = lightStatus.lUp
				 vp.y_max = lightStatus.lDown
				 
				 var points:Array = polygonUtils.clipPolygon(cache.points,vp)	 
				 //points = cache.points 

				 if(points.length>0) {
				 
 				 		// Draw mask
 				 		msk.graphics.beginFill(0x000000,100)

				 		if((wall.vertical && wall.x<light.x) || (!wall.vertical && wall.y<light.y)) {
				 			  msk.graphics.moveTo(points[0].x-this.x,points[0].y-this.y)
				 			  for(var i:Number=1;i<points.length;i++) {
				 			  	msk.graphics.lineTo(points[i].x-this.x,points[i].y-this.y)
			 			    }
				 			  msk.graphics.lineTo(points[0].x-this.x,points[0].y-this.y)
				 		} else {
				 			  msk.graphics.moveTo(points[points.length-1].x-this.x,points[points.length-1].y-this.y)
				 			  for(i=points.length-2;i>=0;i--) {
				 			  	msk.graphics.lineTo(points[i].x-this.x,points[i].y-this.y)
				 			  }
				 			  msk.graphics.lineTo(points[points.length-1].x-this.x,points[points.length-1].y-this.y)
				 		} 
			   		
				 		
				 		// For each hole, draw light
				 		len = cache.holes.length
				 		for(var h:int=0;h<len;h++) {
			   		
							 	if(wall.holes[h].open) {
							 		
							 		// Clip
							  	points = polygonUtils.clipPolygon(cache.holes[h],vp)	 
				 			  	if(points.length>0) {
					 			  	msk.graphics.moveTo(points[0].x-this.x,points[0].y-this.y)
				 			  		for(i=1;i<points.length;i++) {
					 			  		msk.graphics.lineTo(points[i].x-this.x,points[i].y-this.y)
				 			  		}
				 			  		msk.graphics.lineTo(points[0].x-this.x,points[0].y-this.y)
				 					}
				 					
				 				}
				 				
				 		}
				    
		 		 		// Clear mask
		 		 		msk.graphics.endFill() 
				    
				 }
				 
				 
			}
			
			private function calculateWallProjection(x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			
				 var ret:Array = []
			
			   if(wall.vertical) {
			
						if(wall.x==x) x++
						
						if(wall.top<z) {
								var dz:Number = 1+(wall.top-this.z)/(z-wall.top)
			      		var pLeft:Number = x+(wall.x-x)*dz
			      }
			      else {
			      		if(wall.x<x) pLeft = 0
			      		if(wall.x>x) pLeft = this.scene.width
						}
			
			      var pUp:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pLeft,1,pLeft,-1).y-1
			     	ret[ret.length] = new Point(pLeft, pUp)
			     
			      var pDown:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pLeft,1,pLeft,-1).y+1
			     	ret[ret.length] = new Point(pLeft,pDown)
			
						if(wall.z>this.z) {
					 			var dzb:Number = 1+(wall.z-this.z)/(z-wall.z)
							  var pRight:Number = x+(wall.x-x)*dzb
			      		pUp = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pRight,1,pRight,-1).y-1
			      		pDown = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pRight,1,pRight,-1).y+1
			      		ret[ret.length] = new Point(pRight,pDown)
			      		ret[ret.length] = new Point(pRight,pUp)
			      } else {
			      		ret[ret.length] = new Point(wall.x+1,wall.y1-1)
			      		ret[ret.length] = new Point(wall.x+1,wall.y0-1)
						}
			
			
			   } else {
			   	
						if(wall.y==y) y++
			
						if(wall.top<z) {
				   	   dz = 1+(wall.top-this.z)/(z-wall.top)
						   pUp = y+(wall.y-y)*dz
			      } 
			      else {
			      	 if(wall.y<y) pUp = 0
			      	 if(wall.y>y) pUp = this.scene.depth
					  }
					  
			      pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pUp,-1,pUp).x+1
			      ret[ret.length] = new Point(pLeft, pUp)
			
						if(wall.z>this.z) {
							 dzb = 1+(wall.z-this.z)/(z-wall.z)
							 pDown = y+(wall.y-y)*dzb
			      	 pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pDown,-1,pDown).x-1
			         pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pDown,-1,pDown).x+1
						   ret[ret.length] = new Point(pLeft,pDown)
			         ret[ret.length] = new Point(pRight,pDown)
						} else {
			         ret[ret.length] = new Point(wall.x0+1,wall.y-1)
				       ret[ret.length] = new Point(wall.x1+1,wall.y-1)
			      }
			
			      pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pUp,-1,pUp).x+1
			      ret[ret.length] = new Point(pRight,pUp)
			
			   }
			   
			   // Projection must be closed
			   ret[ret.length] = new Point(ret[0].x,ret[0].y)

			   return ret
			
			}
			
			private function calculateWallProjectionHole(x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			
				 var ret:Array = []
			
			   if(wall.vertical) {
			
						if(wall.x==x) x++
						
						if(wall.top<z) {
								var dz:Number = 1+(wall.top-this.z)/(z-wall.top)
			      		var pLeft:Number = x+(wall.x-x)*dz
			      }
			      else {
			      		if(wall.x<x) pLeft = 0
			      		if(wall.x>x) pLeft = this.scene.width
						}
			
			      var pUp:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pLeft,1,pLeft,-1).y-1
			      var pDown:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pLeft,1,pLeft,-1).y+1
			
			      ret[ret.length] = new Point(pLeft,pUp)
			      ret[ret.length] = new Point(pLeft,pDown)
			
						if(wall.z<=this.z) {
			      		ret[ret.length] = new Point(wall.x+0.5,wall.y1)
			      		ret[ret.length] = new Point(wall.x+0.5,wall.y0)
					  } else
						if(wall.z<z) {
					 			var dzb:Number = 1+(wall.z-this.z)/(z-wall.z)
							  var pRight:Number = x+(wall.x-x)*dzb
			      		pUp = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pRight,1,pRight,-1).y-1
			      		pDown = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pRight,1,pRight,-1).y+1
			      		ret[ret.length] = new Point(pRight,pDown)
			      		ret[ret.length] = new Point(pRight,pUp)
			      } else {
			      		return []
						}
			
			
			   } else {
			   
						if(wall.y==y) y++
			
						if(wall.top<z) {
				   	   dz = 1+(wall.top-this.z)/(z-wall.top)
						   pUp = y+(wall.y-y)*dz
			      } 
			      else {
			      	 if(wall.y<y) pUp = 0
			      	 if(wall.y>y) pUp = this.scene.depth
					  }
					  
			      pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pUp,-1,pUp).x+1
			      ret[ret.length] = new Point(pLeft,pUp)
			
						if(wall.z<=this.z) {
							 ret[ret.length] = new Point(wall.x0,wall.y+0.5)
			         ret[ret.length] = new Point(wall.x1,wall.y+0.5)
					  } else
						if(wall.z<z) {
							 dzb = 1+(wall.z-this.z)/(z-wall.z)
							 pDown = y+(wall.y-y)*dzb
			      	 pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pDown,-1,pDown).x-1
			         pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pDown,-1,pDown).x+1
						   ret[ret.length] = new Point(pLeft,pDown)
			         ret[ret.length] = new Point(pRight,pDown)
						} else {
			         return []
			      }
			
			      pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pUp,-1,pUp).x+1
			      ret[ret.length] = new Point(pRight,pUp)
			
			   }
			   

			   // Projection must be closed
			   ret[ret.length] = new Point(ret[0].x,ret[0].y)

			   return ret
			   
			
			}
			
			/** @private */
			public override function setLightZ(light:fLight):void {
				 this.setLightDistance(light,Math.abs(light.z-this.z))
			}

			// fLight leaves element
			/** @private */
			public override function lightOut(light:fLight):void {
			
			   // Hide container
			   if(this.lightStatuses[light.uniqueId]) this.hideLight(light)
			   
			   // Hide shadows
				 if(fFloor.objectProjectionCache[this.uniqueId+"_"+light.uniqueId]) {
				 		var cache = fFloor.objectProjectionCache[this.uniqueId+"_"+light.uniqueId]
				 		for(var i in cache) {
				 			try {
				 				cache[i].parent.parent.removeChild(cache[i].parent)
				 			} catch(e:Error) {
				 			}
				 		}			   
				 }
			   
			}

			/** @private */
			public function disposeFloor():void {

	    	this.polyClip = null
	    	this.bounds = null
				this.lastCharacterCollision = null
				this.resetShadowsInt()
				this.disposePlane()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposeFloor()
			}		

			
		}
}
