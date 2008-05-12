// WALL

package org.ffilmation.engine.elements {
	
		// Imports
		import flash.display.*
		import flash.utils.*
		import flash.geom.Point
		import flash.geom.Matrix
		import flash.geom.ColorTransform
		import flash.geom.Rectangle
		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*

		/**
		* <p>Walls are created when the scene is processed</p>
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT.</p>
		*/
		public class fWall extends fPlane {
			
			// Static properties. Render cache
			private static var objectRenderCache:Object = []
			
			// Public properties

			/**
			* This is the tranformation matrix for vertical walls
			*/
			public static var verticalMatrix = new Matrix(0.706974983215332,0.35248100757598877,0,fEngine.DEFORMATION,0,0)	
			
			/**
			* This is the tranformation matrix for horizontal walls
			*/
			public static var horizontalMatrix = new Matrix(0.706974983215332,-0.35248100757598877,0,fEngine.DEFORMATION,0,0)

			/**
			* A wall can be either horizontal ( goes along x axis ) or vertical ( goes along y axis )
			*/
			public var vertical:Boolean			

			/** @private */
			public var horizontal:Boolean
			/** @private */
			public var i:Number
			/** @private */
			public var j:Number

			/** @private */
			public var size:Number

			/**
			* Wall length in pixels.
			*/
			public var pixelSize:Number

			/**
			* Wall height ( real height, position along z-axis )
			*/
			public var pixelHeight:Number
			/** @private */
			public var height:Number
			/** @private */
	    public var bounds: fPlaneBounds
			/** @private */
			private var lastCharacterCollision:fPlaneBounds

			// Private properties
	    private var polyClip:Array

			// Constructor
			/** @private */
			function fWall(container:MovieClip,defObj:XML,scene:fScene):void {
				
				 // Vertical ?
			   this.vertical = (defObj.@direction=="vertical")   					 // Orientation
			   this.horizontal = !this.vertical   					 							 
			   
				 // Generate Sprites
				 var mask:Sprite = new Sprite()
				 var destination:Sprite = new Sprite()
				 container.addChild(mask)
				 mask.mouseEnabled = false
				 mask.addChild(destination)

			   // Deform wall to match perspective
			   if(this.vertical) container.transform.matrix = fWall.verticalMatrix	
				 else container.transform.matrix = fWall.horizontalMatrix

			   // Dimensions, parse size and snap to gride
			   this.size = Math.round(defObj.@size/scene.gridSize)  			 // Size ( in cells )
			   this.pixelSize = this.size*scene.gridSize+1
			   this.height = this.pixelHeight = scene.levelSize*Math.round(defObj.@height/scene.levelSize)      

				 // Previous
				 super(defObj,scene,this.pixelSize,this.pixelHeight,destination,container)

			   // Specific coordinates
			   this.i = Math.round(this.x/scene.gridSize)                  // Grid coordinates
			   this.j = Math.round(this.y/scene.gridSize)
			   this.x0 = this.x1 = this.i*scene.gridSize
			   this.y0 = this.y1 = this.j*scene.gridSize
			   this.z = scene.levelSize*Math.round(this.z/scene.levelSize)
			   this.top = this.z + this.height

			   if(this.vertical) {                                         // Position
			      this.x = scene.gridSize*this.i
			      this.y = scene.gridSize*(this.j+(this.size/2))
			      this.y1 = scene.gridSize*(this.j+this.size)
			   } else {
			      this.x = scene.gridSize*(this.i+(this.size/2))
			      this.x1 = scene.gridSize*(this.i+this.size)
			      this.y = scene.gridSize*this.j
			   }                                                                 
			            
				 // Bounds
			   this.bounds = new fPlaneBounds()
			   this.bounds.top = this.top
			   this.bounds.z = this.z
				 if(this.vertical) {
				 	 this.bounds.vertical = true
				 	 this.bounds.x = this.x
				 	 this.bounds.y = this.y
				 	 this.bounds.x0 = this.x
				 	 this.bounds.x1 = this.x
				 	 this.bounds.y0 = this.y0
				 	 this.bounds.y1 = this.y1
				 } else {
				   this.bounds.vertical = false
				 	 this.bounds.x = this.x
				 	 this.bounds.y = this.y
				 	 this.bounds.x0 = this.x0
				 	 this.bounds.x1 = this.x1
				 	 this.bounds.y0 = this.y
				 	 this.bounds.y1 = this.y
			   }

				 // Scale
				 mask.scrollRect = new Rectangle(0, 0, this.pixelSize, -this.pixelHeight)
        
			   // Create polygon bounds, for clipping algorythm
				 this.polyClip = [ new Point(this.x,this.y0),
				 							     new Point(this.x,this.y1),
				 							     new Point(this.x,this.y1),
				 							     new Point(this.x,this.y0) ]
			   
			
			}
			
			// Methods
		
			// Gives geometry container the proper dimensions
			/** @private */
			public override function setDimensions(lClip:DisplayObject):void {
				lClip.width = this.pixelSize
				lClip.height = this.pixelHeight
				lClip.y = -this.pixelHeight
		  }

			/** @private */
			public override function place():void {
			   // Place in position
			   var coords:Point = this.scene.translateCoords(this.x0,this.y0,this.z)
			   this.container.x = coords.x
			   this.container.y = coords.y
			}
			
			/** @private */
			public override function distanceTo(x:Number,y:Number,z:Number):Number {
			
				 if(z>this.top) {
			
				   if(this.vertical) {
			  	    if(y<this.y0) return mathUtils.distance3d(x,y,z,this.x,this.y0,this.top)
			      	if(y>this.y1) return mathUtils.distance3d(x,y,z,this.x,this.y1,this.top)
			    	  return mathUtils.distance3d(x,y,z,this.x,y,this.top)
			   	 } else {
			        if(x<this.x0) return mathUtils.distance3d(x,y,z,this.x0,this.y,this.top)
			        if(x>this.x1) return mathUtils.distance3d(x,y,z,this.x1,this.y,this.top)
			        return mathUtils.distance3d(x,y,z,x,this.y,this.top)
			     }
			
				 } else if(z<this.z) {
			
				   if(this.vertical) {
							if(y<this.y0) return mathUtils.distance3d(x,y,z,this.x,this.y0,this.z)
							if(y>this.y1) return mathUtils.distance3d(x,y,z,this.x,this.y1,this.z)
			    	  return mathUtils.distance3d(x,y,z,this.x,y,this.z)
			   	 } else {
			        if(x<this.x0) return mathUtils.distance3d(x,y,z,this.x0,this.y,this.z)
			        if(x>this.x1) return mathUtils.distance3d(x,y,z,this.x1,this.y,this.z)
			        return mathUtils.distance3d(x,y,z,x,this.y,this.z)
			     }
			  
			   } else {
			  
				   if(this.vertical) {
			  	    if(y<this.y0) return mathUtils.distance(x,y,this.x,this.y0)
			      	if(y>this.y1) return mathUtils.distance(x,y,this.x,this.y1)
			    	  return mathUtils.distance(x,y,this.x,y)
			   	 } else {
			        if(x<this.x0) return mathUtils.distance(x,y,this.x0,this.y)
			        if(x>this.x1) return mathUtils.distance(x,y,this.x1,this.y)
			        return mathUtils.distance(x,y,x,this.y)
			     }
			
			   }
			
			
			}
			

			// Confirm impact from a bullet
			/** @private */
			public override function confirmImpact(x:Number,y:Number,z:Number,dx:Number,dy:Number,dz:Number):fPlaneBounds {
				
				var w:fPlaneBounds

				if(!this.solid) return null
				
				// Loop through holes and see if point is inside one
				if(this.vertical) {
					for(var h:int=0;h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	var hole:fPlaneBounds = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.y0<=y && hole.y1>=y) {
							 		return null
							 	}
			 				}	  	
					}				
			  } else {
					for(h=0;h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	hole = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.x0<=x && hole.x1>=x) {
							 		return null
							 	}
			 				}	  	
					}				
			  }
				
				var lastCharacterCollision:fPlaneBounds = null

				// Check previous positions to detect if we were inside a hole or not
				if(this.vertical) {
					for(h=0;h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	hole = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.y0<=(y-dy) && hole.y1>=(y-dy)) {
							 		lastCharacterCollision = hole
							 	}
			 				}	  	
					}				
			  } else {
					for(h=0;h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	hole = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.x0<=(x-dx) && hole.x1>=(x-dx)) {
							 		lastCharacterCollision = hole
							 	}
			 				}	  	
					}				
			  }

				// Return fCollision
				if(lastCharacterCollision!=null) {
					w = new fPlaneBounds
					w.x0 = lastCharacterCollision.x1
					w.x1 = lastCharacterCollision.x0
					w.y0 = lastCharacterCollision.y1
					w.y1 = lastCharacterCollision.y0
					return w
				} else {
					return this.bounds
				}

			}


			// Test primary collision between an object and this wall
			/** @private */
			public override function testPrimaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {

				var obj:fObject = other as fObject
				var x:Number, y:Number, z:Number
				var any:Boolean
				var radius:Number = obj.radius

				if(this.vertical) {
					
					if(dx>0 && (obj.x>this.x || ((obj.x+radius)<this.x)) ) return null
					if(dx<0 && (obj.x<this.x || ((obj.x-radius)>this.x)) ) return null
					
					y = obj.y
					z = obj.z

					// Loop through holes and see if bottom point is inside one
					any = false
					for(var h:int=0;!any && h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
						 		var hole:fPlaneBounds = this.holes[h].bounds
						 		if(hole.z<=z && hole.top>=z && hole.y0<=y && hole.y1>=y) {
							 		any = true
						 		} 
						 	}
			 		  	
					}
					
					// There was a fCollision 
					if(!any) {
						if(dx>0) return new fCollision(this.x-radius-0.01,-1,-1)
						else return new fCollision(this.x+radius+0.01,-1,-1)
					}
			  
					// Loop through holes and see if top point is inside one
					z = obj.top
					any = false
					for(h=0;!any && h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	hole = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.y0<=y && hole.y1>=y) {
							 		any = true
							 	} 
							}
			 		  	
					}
					
					// There was a fCollision 
					if(!any) {
						if(dx>0) return new fCollision(this.x-radius-0.01,-1,-1)
						else return new fCollision(this.x+radius+0.01,-1,-1)
					}
	
					return null

			  } else {
			  	
					if(dy>0 && (obj.y>this.y || ((obj.y+radius)<this.y)) ) return null
					if(dy<0 && (obj.y<this.y || ((obj.y-radius)>this.y)) ) return null
					
					x = obj.x
					z = obj.z

					// Loop through holes and see if bottom point is inside one
					any = false
					for(h=0;!any && h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
						 		hole = this.holes[h].bounds
						 		if(hole.z<=z && hole.top>=z && hole.x0<=x && hole.x1>=x) {
						 			any = true
						 		}
						 	}
			 		  	
					}
					
					// There was a fCollision 
					if(!any) {
						if(dy>0) return new fCollision(-1,this.y-radius-0.01,-1)
						else return new fCollision(-1,this.y+radius+0.01,-1)
					}
					
					// Loop through holes and see if top point is inside one
					z = obj.top
					any = false
					for(h=0;!any && h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
								hole = this.holes[h].bounds
						 		if(hole.z<=z && hole.top>=z && hole.x0<=x && hole.x1>=x) {
						 			any = true
						 		}
			 		  	}	
					}
					
					// There was a fCollision 
					if(!any) {
						if(dy>0) return new fCollision(-1,this.y-radius-0.01,-1)
						else return new fCollision(-1,this.y+radius+0.01,-1)
					}

					return null

			  }

			}

			// Test secondary collision between an object and this wall
			/** @private */
			public override function testSecondaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {

				var obj:fObject = other as fObject
				var x:Number, y:Number, z:Number
				var any:Boolean, ret:fCollision

				var radius:Number = obj.radius
				var oheight:Number = obj.height

				if(this.vertical) {
					
					// Are we inside the wall ? Then we must be in a hole
					if( ((obj.x+obj.radius)<this.x) || ((obj.x-radius)>this.x) ) return null
					
					y = obj.y
					x = obj.x
					z = (obj.z+obj.top)/2

					// Loop through holes find which one are we inside of
					any = false
					for(var h:int=0;!any && h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	var hole:fPlaneBounds = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.y0<=y && hole.y1>=y) {
							 		any = true
							 	} 
							}
			 		  	
					}
					
					// We are inside one
					if(any) {
						
						ret = new fCollision(-1,-1,-1)
						if(dy<0 && ((y-radius)<hole.y0)) ret.y = hole.y0+radius+0.01
						if(dy>0 && ((y+radius)>hole.y1)) ret.y = hole.y1-radius-0.01
						if(dz<0 && obj.z<=hole.z) ret.z = hole.z+0.01
						if(dz>0 && obj.top>=hole.top) ret.z = hole.top-oheight-0.01
						return ret
						
					} else return null

			  } else {
			  	
					// Are we inside the wall ? Then we must be in a hole
					if( ((obj.y+radius)<this.y) || ((obj.y-radius)>this.y) ) return null
					
					y = obj.y
					x = obj.x
					z = (obj.z+obj.top)/2

					// Loop through holes and find which one are we inside of
					any = false
					for(h=0;!any && h<this.holes.length;h++) {
					
						 	if(this.holes[h].open) {
							 	hole = this.holes[h].bounds
							 	if(hole.z<=z && hole.top>=z && hole.x0<=x && hole.x1>=x) {
							 		any = true
							 	}
							}
			 		  	
					}
					
					// We are inside one
					if(any) {
						
						ret = new fCollision(-1,-1,-1)
						if(dx<0 && ((x-radius)<hole.x0)) ret.x = hole.x0+radius+0.01
						if(dx>0 && ((x+radius)>hole.x1)) ret.x = hole.x1-radius-0.01
						if(dz<0 && obj.z<=hole.z) ret.z = hole.z+0.01
						if(dz>0 && obj.top>=hole.top) ret.z = hole.top-oheight-0.01
						return ret
						
					} else return null

			  }

			}


		  // Tests shadow
			/** @private */
			public override function testShadow(other:fRenderableElement,x:Number,y:Number,z:Number):Number {

				 if(other is fFloor) {
							if(this.vertical) return this.testFloorShadowVertical(other as fFloor,x,y,z)
							else return this.testFloorShadowHorizontal(other as fFloor,x,y,z)
				 }
			   if(other is fWall) {
							if(this.vertical) return this.testWallShadowVertical(other as fWall,x,y,z)
							else return this.testWallShadowHorizontal(other as fWall,x,y,z)
				 }
			   if(other is fObject) {
							if(this.vertical) return this.testObjectShadowVertical(other as fObject,x,y,z)
							else return this.testObjectShadowHorizontal(other as fObject,x,y,z)
				 }

				 // Else
				 return fCoverage.NOT_SHADOWED	

			}

			private function testFloorShadowHorizontal(other:Object,x:Number,y:Number,z:Number):Number {
			
				 var len:int
				 
				 // If floor is above wall
				 if(other.z>this.z && other.z<z) {
			   
				   var dz:Number = 1+(other.z-this.z)/(z-other.z)
				   var pUp:Number = y+(other.y-y)*dz
			     var pDown:Number = y+(other.y+other.depth-y)*dz
				   var pLeft:Number = x+(other.x-x)*dz
				   var pRight:Number = x+(other.x+other.width-x)*dz
			
			   	if((this.y<pUp) || (this.y>pDown) || (this.x0>pRight) || (this.x1<pLeft)) {
			
			  	    // Outside range
				      return fCoverage.NOT_SHADOWED
			
			   	} else {
			
							if(mathUtils.segmentsIntersect(x,z,pLeft,this.z,this.x0,this.top,this.x1,this.top) ||
							   mathUtils.segmentsIntersect(x,z,pRight,this.z,this.x0,this.top,this.x1,this.top) ||
							   mathUtils.segmentsIntersect(x,z,pRight,this.z,this.x0,this.top,this.x0,this.z) ||
							   mathUtils.segmentsIntersect(x,z,pLeft,this.z,this.x1,this.z,this.x1,this.top) ||
							   mathUtils.segmentsIntersect(y,z,pUp,this.z,this.y,this.top+2,this.y,this.z) ||
							   mathUtils.segmentsIntersect(y,z,pDown,this.z,this.y,this.top+2,this.y,this.z)) {
							   	return fCoverage.SHADOWED
							}
							else {
			
			      	  // Test holes
			      	  if(other is fFloor) {
			      	  	len = other.holes.length
			      	  	for(var h:int=0;h<len;h++) {
			      	  		if(this.testFloorShadowHorizontal(other.holes[h].bounds,x,y,z)!=fCoverage.NOT_SHADOWED) return fCoverage.SHADOWED
			      	  	}
			      	  }
			
								return fCoverage.COVERED
							}
				   }
			
				 }
			
				 // If floor is below wall
				 if(other.z<this.z && other.z>z) {
				 	
				 } 
			
				 return fCoverage.NOT_SHADOWED
			
			
			}
			
			private function testFloorShadowVertical(other:Object,x:Number,y:Number,z:Number):Number {
			   
				 var len:int
				 
				 // If floor is above wall
				 if(other.z>this.z && other.z<z) {
			
				   var dz:Number = 1+(other.z-this.z)/(z-other.z)
			   	 var pUp:Number = y+(other.y-y)*dz
			   	 var pDown:Number = y+(other.y+other.depth-y)*dz
			   	 var pLeft:Number = x+(other.x-x)*dz
			     var pRight:Number = x+(other.x+other.width-x)*dz
			
			
			      if((this.y0>pDown) || (this.y1<pUp) || (this.x>pRight)|| (this.x<pLeft)) {
			
			         // Outside range
			         return fCoverage.NOT_SHADOWED
			
			      } else {
			
						   if(mathUtils.segmentsIntersect(y,z,pUp,this.z,this.y0,this.top,this.y1,this.top) ||
						      mathUtils.segmentsIntersect(y,z,pDown,this.z,this.y0,this.top,this.y1,this.top) ||
						      mathUtils.segmentsIntersect(y,z,pUp,this.z,this.y1,this.z,this.y1,this.top) ||
						      mathUtils.segmentsIntersect(y,z,pDown,this.z,this.y0,this.z,this.y0,this.top) ||
							    mathUtils.segmentsIntersect(x,z,pRight,this.z,this.x,this.top+2,this.x,this.z) ||
							    mathUtils.segmentsIntersect(x,z,pLeft,this.z,this.x,this.top+2,this.x,this.z)) {
							    	return fCoverage.SHADOWED
							 }
						   else {
			
			      	  // Test holes
			      	  if(other is fFloor) {
			      	  	len = other.holes.length
			      	  	for(var h:int=0;h<len;h++) {
			      	  		if(this.testFloorShadowVertical(other.holes[h].bounds,x,y,z)!=fCoverage.NOT_SHADOWED) return fCoverage.SHADOWED
			      	  	}
			      	  }
			
						   	return fCoverage.COVERED
						   }
			
			      }
				 }
			
				 // If floor is below wall
				 if(other.z<this.z && other.z>z) {
				 	
				 } 
			
				 return fCoverage.NOT_SHADOWED
			
			}
			
			private function testWallShadowHorizontal(other:Object,x:Number,y:Number,z:Number):Number {
			
			   var dz:Number = 1+(other.top-this.z)/(z-other.top)
			
			   if(other.vertical) {               
			
			      if(other.y1>this.y && other.y0<=(y) && ((other.x>x && other.x<this.x1) || (other.x<x && other.x>this.x0))) { 
			
						   if(other.top<z) {
				  			  var pUp:Number = y+(other.y0-y)*dz
			   	  			if(pUp>=this.y) return fCoverage.NOT_SHADOWED
						   }      	
			
			         var inter:Number = mathUtils.linesIntersect(x,y,other.x,other.y0,this.x0,this.y,this.x1,this.y).x
			
			         if((inter>=this.x0 && inter<=this.x1) || 
			            mathUtils.segmentsIntersect(x,y,this.x0,this.y,other.x,other.y0,other.x,other.y1) || 
			            mathUtils.segmentsIntersect(x,y,this.x1,this.y,other.x,other.y0,other.x,other.y1)) {
			            
			            return fCoverage.SHADOWED
			         }  
			      }
			
			   } else {
			   	
			      if(other.y>this.y && other.y<=(y)) { 
			
						   if(other.top<z) {
				  			  pUp = y+(other.y-y)*dz
			   	  			if(pUp>=this.y) return fCoverage.NOT_SHADOWED
						   }      	
			
			         inter = mathUtils.linesIntersect(x,y,other.x0,other.y,this.x0,this.y,this.x1,this.y).x
			
			         if((inter>this.x0 && inter<this.x1) || 
			            mathUtils.segmentsIntersect(x,y,this.x0,this.y,other.x0,other.y,other.x1,other.y) || 
			            mathUtils.segmentsIntersect(x,y,this.x1,this.y,other.x0,other.y,other.x1,other.y)) {
			            
			            return fCoverage.SHADOWED
			         }  
			      }
			
			   }
			
			   return fCoverage.NOT_SHADOWED
			
			}
			
			private function testWallShadowVertical(other:Object,x:Number,y:Number,z:Number):Number {
			
			   var dz:Number = 1+(other.top-this.z)/(z-other.top)
			
			   if(other.vertical) {               
			
			      if(other.x<this.x && other.x>(x)) { 
			      	
						   if(other.top<z) {
				  			  var pRight:Number = x+(other.x-x)*dz
			   	  			if(pRight<=this.x) return fCoverage.NOT_SHADOWED
						   }      	
						   
			         var inter:Number = mathUtils.linesIntersect(x,y,other.x,other.y0,this.x,this.y0,this.x,this.y1).y
			
			         if((inter>this.y0 && inter<this.y1) || 
			            mathUtils.segmentsIntersect(x,y,this.x,this.y0,other.x,other.y0,other.x,other.y1) || 
			            mathUtils.segmentsIntersect(x,y,this.x,this.y1,other.x,other.y0,other.x,other.y1)) {
			            
			            return fCoverage.SHADOWED
			         }  
			      }
			
			   } else {
			      
			
			      if(other.x0<this.x && other.x1>(x) && ((other.y>y && other.y<this.y1) || (other.y<y && other.y>this.y0))) {
			
						   if(other.top<z) {
				  			  pRight = x+(other.x1-x)*dz
			   	  			if(pRight<=this.x) return fCoverage.NOT_SHADOWED
						   }      	
			
			         inter = mathUtils.linesIntersect(x,y,other.x0,other.y,this.x,this.y0,this.x,this.y1).y
			
			         if((inter>this.y0 && inter<this.y1) || 
			            mathUtils.segmentsIntersect(x,y,this.x,this.y0,other.x0,other.y,other.x1,other.y) || 
			            mathUtils.segmentsIntersect(x,y,this.x,this.y1,other.x0,other.y,other.x1,other.y)) {
			            
			            return fCoverage.SHADOWED
			         }  
			      }
			
			   }
			  
			   return fCoverage.NOT_SHADOWED
			
			}

			private function testObjectShadowHorizontal(other:fObject,x:Number,y:Number,z:Number):Number {

			   // Simple cases
			   if(other.y<this.y && y>other.y) return fCoverage.NOT_SHADOWED
			   if(other.y>this.y && y<other.y) return fCoverage.NOT_SHADOWED

				 // Get first polygon (object)
				 var proj:fObjectProjection = other.getProjection(this.z,x,y,z)
				 if(proj==null) return fCoverage.NOT_SHADOWED

				 var poly1:Array = proj.polygon
				 
				 // Check fCollision
				 var result:Boolean = ((mathUtils.segmentsIntersect(this.x0,this.y,this.x1,this.y,other.x,other.y,proj.end.x,proj.end.y)!=null) ||
				 											 (mathUtils.segmentsIntersect(this.x0,this.y,this.x1,this.y,poly1[0].x,poly1[0].y,poly1[3].x,poly1[3].y)!=null) ||
				 											 (mathUtils.segmentsIntersect(this.x0,this.y,this.x1,this.y,poly1[1].x,poly1[1].y,poly1[2].x,poly1[2].y)!=null))
				                      
				 if(result) return fCoverage.SHADOWED
				 else return fCoverage.NOT_SHADOWED

	  	}
	  
			private function testObjectShadowVertical(other:fObject,x:Number,y:Number,z:Number):Number {

			   // Simple cases
			   if(other.x<this.x && x>other.x) return fCoverage.NOT_SHADOWED
			   if(other.x>this.x && y<other.x) return fCoverage.NOT_SHADOWED
				 
				 // Get first polygon (object)
				 var proj:fObjectProjection = other.getProjection(this.z,x,y,z)
				 if(proj==null) return fCoverage.NOT_SHADOWED
				 
				 var poly1:Array = proj.polygon
				 
				 // Check fCollision
				 var result:Boolean = ((mathUtils.segmentsIntersect(this.x,this.y0,this.x,this.y1,other.x,other.y,proj.end.x,proj.end.y)!=null) ||
				                       (mathUtils.segmentsIntersect(this.x,this.y0,this.x,this.y1,poly1[0].x,poly1[0].y,poly1[3].x,poly1[3].y)!=null) ||
				                       (mathUtils.segmentsIntersect(this.x,this.y0,this.x,this.y1,poly1[1].x,poly1[1].y,poly1[2].x,poly1[2].y)!=null))
				
				 if(result) return fCoverage.SHADOWED
				 else return fCoverage.NOT_SHADOWED

	  	}
	  
			
			// Render ( draw ) light
			/** @private */
			public override function renderLight(light:fLight):void {

					if(this.vertical) this.renderLightVertical(light)
					else this.renderLightHorizontal(light)

		  }
			
			private function renderLightVertical(light:fLight):void {
			
			   var status:fLightStatus = this.lightStatuses[light.id]
			   var lClip:Sprite = this.lightClips[light.id]
			     
			   if(light.size!=Infinity) {
			      
			      // If distance to light changed, redraw masks
			      if(status.lightZ != light.x) {
			      	 this.setLightDistance(light,Math.abs(light.x-this.x))
			         status.lightZ = light.x
			      }
			   }   
			   
			   // Move light
			   this.setLightCoordinates(light,(light.y-this.y0),(this.z-light.z))
			
			}
			
			private function renderLightHorizontal(light:fLight):void {
			
			   var status:fLightStatus = this.lightStatuses[light.id]
			   var lClip:Sprite = this.lightClips[light.id]
			
			   if(light.size!=Infinity) {
			
			      // If distance to light changed, redraw masks
			      if(status.lightZ != light.y) {
			      	 this.setLightDistance(light,Math.abs(light.y-this.y))
			         status.lightZ = light.y
			      }
			   
			   }
			   
	   	   // Move light
			   this.setLightCoordinates(light,(light.x-this.x0),(this.z-light.z))
			
			}
			
			// Calculates and projects shadows upon this floor
			/** @private */
			public override function renderShadowInt(light:fLight,other:fRenderableElement,msk:Sprite):void {
			   if(other is fFloor) this.renderFloorShadow(light,other as fFloor,msk)
			   if(other is fWall) this.renderWallShadow(light,other as fWall,msk)
			   if(other is fObject) this.renderObjectShadow(light,other as fObject,msk)
			}


			// Delete character shadows upon this wall
			public override function unrenderShadowAlone(light:fLight,other:fRenderableElement):void {
			   
			   // Select mask
			   try {
			   	var msk:Sprite = this.lightShadows[light.id]

			 	 	var cache = fWall.objectRenderCache[this.id+"_"+light.id]
			 	 	var clip:Sprite = cache[other.id]
			 	 	msk.removeChild(clip)
			 	 } catch (e:Error) { }

			}


			// Calculates and projects shadows of a floor upon this wall
			/** @private */
			public function renderFloorShadow(light:fLight,other:fFloor,msk:Sprite):void {
			
			   var lightStatus:fLightStatus = this.lightStatuses[light.id] 
			   var x:Number = light.x, y:Number = light.y, z:Number = light.z
			   var len:int,len2:int
			
			   msk.graphics.beginFill(0x000000,100)   
			
				 if(this.vertical) var points:Object = this.calculateFloorProjectionVertical(light.x,light.y,light.z,other.bounds)
				 else points = this.calculateFloorProjectionHorizontal(light.x,light.y,light.z,other.bounds)
				 
			   msk.graphics.moveTo(points[0].x,points[0].y)
			   
			   len = points.length
				 for(var i:int=1;i<len;i++) msk.graphics.lineTo(points[i].x,points[i].y)
			
			
				 // For each hole, draw light
				 len = other.holes.length
				 for(var h:int=0;h<len;h++) {
					 	
					 	if(other.holes[h].open) {
					 		if(this.vertical) points = this.calculateFloorProjectionVertical(light.x,light.y,light.z,other.holes[h].bounds)
					  	else points = this.calculateFloorProjectionHorizontal(light.x,light.y,light.z,other.holes[h].bounds)
					 	
				 	  	if(points.length>0) {
					 	  	msk.graphics.moveTo(points[0].x,points[0].y)
				 	  		len2 = points.length
				 	  		for(i=1;i<len2;i++) msk.graphics.lineTo(points[i].x,points[i].y)
				 			}
				 		}
				 }
			
				 msk.graphics.endFill()

			}
			
			private function calculateFloorProjectionHorizontal(x:Number,y:Number,z:Number,other:fPlaneBounds):Array {
			   
				 var ret:Array = []
				 
			   try {
			   	
			   		var shadowHeight:Number = mathUtils.linesIntersect(y,z,other.y,other.z,this.y,1,this.y,-1).y
			   		var shadowLeft:Number = mathUtils.linesIntersect(x,z,other.x,other.z,1,shadowHeight,-1,shadowHeight).x    
			   		var shadowRight:Number = mathUtils.linesIntersect(x,z,other.x+other.width,other.z,1,shadowHeight,-1,shadowHeight).x    
			   		
			   		// Floor level 
			   		var floorfLevel:Number = 0
			   		var dz:Number = 1+(other.z-this.z)/(z-other.z)
			 	 		var pDown:Number = y+(other.y+other.depth-y)*dz
			   		
			   		if(this.y>pDown) {
			   		
			   		   floorfLevel = mathUtils.linesIntersect(y,z,other.y+other.depth,other.z,this.y,1,this.y,-1).y
			   		   var shadowFLeft:Number = mathUtils.linesIntersect(x,z,other.x,other.z,1,floorfLevel,-1,floorfLevel).x    
			   		   var shadowFRight:Number = mathUtils.linesIntersect(x,z,other.x+other.width,other.z,1,floorfLevel,-1,floorfLevel).x    
			   		
			   		   ret[ret.length] = new Point((shadowFRight-this.x0),-floorfLevel+this.z)
			   		   ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight+this.z)         
			   		   ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight+this.z)         
			   		   ret[ret.length] = new Point((shadowFLeft-this.x0),-floorfLevel+this.z)
			   		
			   		} else {
			   		   
				 		   var pLeft:Number = x+(other.x-x)*dz
				 		   var pRight:Number = x+(other.x+other.width-x)*dz
			   		   ret[ret.length] = new Point((pRight-this.x0),0)
			   		   ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight+this.z)         
			   		   ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight+this.z) 
			   		   ret[ret.length] = new Point((pLeft-this.x0),0)
			   		
			   		}
			   
			   } catch(e:Error) {
			   	
			   		ret = new Array
			   }
			
				 return ret   
			
			}
			
			private function calculateFloorProjectionVertical(x:Number,y:Number,z:Number,other:fPlaneBounds):Array {
			
				 var ret:Array = []
			
			   try {

			   		var shadowHeight:Number = mathUtils.linesIntersect(x,z,other.x+other.width,other.z,this.x,1,this.x,-1).y
			   		var shadowUp:Number = mathUtils.linesIntersect(y,z,other.y,other.z,1,shadowHeight,-1,shadowHeight).x    
			   		var shadowDown:Number = mathUtils.linesIntersect(y,z,other.y+other.depth,other.z,1,shadowHeight,-1,shadowHeight).x    
			   		
			   		// Floor level 
			   		var floorfLevel:Number = 0
			   		var dz:Number = 1+(other.z-this.z)/(z-other.z)
			 	 		var pLeft:Number = x+(other.x-x)*dz
			   		
			   		if(this.x<pLeft) {
			   		
			   		   floorfLevel = mathUtils.linesIntersect(x,z,other.x,other.z,this.x,1,this.x,-1).y
			   		   var shadowFUp:Number = mathUtils.linesIntersect(y,z,other.y,other.z,1,floorfLevel,-1,floorfLevel).x
			   		   var shadowFDown:Number = mathUtils.linesIntersect(y,z,other.y+other.depth,other.z,1,floorfLevel,-1,floorfLevel).x
			   		
			   		   ret[ret.length] = new Point((shadowFDown-this.y0),-floorfLevel+this.z)
			   		   ret[ret.length] = new Point((shadowDown-this.y0),-shadowHeight+this.z)         
			   		   ret[ret.length] = new Point((shadowUp-this.y0),-shadowHeight+this.z)         
			   		   ret[ret.length] = new Point((shadowFUp-this.y0),-floorfLevel+this.z)
			   		
			   		 } else {
			   		
			   			 var pUp:Number = y+(other.y-y)*dz
			   			 var pDown:Number = y+(other.y+other.depth-y)*dz
			   		   ret[ret.length] = new Point((pDown-this.y0),0)
			   		   ret[ret.length] = new Point((shadowDown-this.y0),-shadowHeight+this.z)         
			   		   ret[ret.length] = new Point((shadowUp-this.y0),-shadowHeight+this.z)
			   		   ret[ret.length] = new Point((pUp-this.y0),0)
			   		
			   		 }

				 } catch(e:Error) {
				 	
				 			ret = new Array
				 			
				 }
			   
			   return ret
			   
			}
			
			// Calculates and projects shadows of given wall and light
			/** @private */
			public function renderWallShadow(light:fLight,wall:fWall,msk:Sprite):void {
			
			   var lightStatus:fLightStatus = this.lightStatuses[light.id] 
			   var x:Number = light.x, y:Number = light.y, z:Number = light.z
			   var len:int,len2:int
			
			   msk.graphics.beginFill(0x000000,100)   
			
				 try {
				 	
				 		if(this.vertical) var points:Array = this.calculateWallProjectionVertical(light.x,light.y,light.z,wall.bounds)
				 		else points = this.calculateWallProjectionHorizontal(light.x,light.y,light.z,wall.bounds)
			   		
				 		// Clipping viewport
				 		var vp:vport = new vport()
				 		vp.x_min = 0
				 		vp.x_max = this.pixelSize
				 		vp.y_min = -this.height
				 		vp.y_max = 0
				 		 
				 		points = polygonUtils.clipPolygon(points,vp)
			   		msk.graphics.moveTo(points[0].x,points[0].y)
			   		len=points.length
				 		for(var i:int=1;i<len;i++) msk.graphics.lineTo(points[i].x,points[i].y)
			   		
			   		
				 		// For each hole, draw light
				 		len = wall.holes.length
				 		for(var h:int=0;h<len;h++) {
			   		
							if(wall.holes[h].open) { 	
							 	if(this.vertical) points = this.calculateWallProjectionVertical(light.x,light.y,light.z,wall.holes[h].bounds)
							  else points = this.calculateWallProjectionHorizontal(light.x,light.y,light.z,wall.holes[h].bounds)
							 	
				 				points = polygonUtils.clipPolygon(points,vp)	 
			   		
				 			  if(points.length>0) {
				 			  	msk.graphics.moveTo(points[0].x,points[0].y)
				 			  	len2 = points.length
				 			  	for(i=1;i<len2;i++) msk.graphics.lineTo(points[i].x,points[i].y)
				 				}
				 			}

				 		}
			
				 } catch (e:Error) {
				 	
				 }
				 
				 msk.graphics.endFill()


			}
			
			private function calculateWallProjectionHorizontal(x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			
				 var ret:Array = []
			
			   if(wall.vertical) {
			
			     if(wall.x<x) {
			
			        if(y>wall.y1) var shadowLeft:Number = Math.max(mathUtils.linesIntersect(x,y,wall.x,wall.y1,this.x0,this.y,this.x1,this.y).x,this.x0)
			        else shadowLeft = this.x0
			
			        var shadowRight:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y0,this.x0,this.y,this.x1,this.y).x
							// Top of shadow
			        var shadowHeight1:Number = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowRight,1,shadowRight,-1).y
			        var shadowHeight2:Number = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowLeft,1,shadowLeft,-1).y
							// Bottom of shadow
			        var shadowHeight3:Number = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowRight,1,shadowRight,-1).y
			        var shadowHeight4:Number = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowLeft,1,shadowLeft,-1).y
			
			        ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight3+this.z)
			        ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight1+this.z)
			        ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight2+this.z)        
			        ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight4+this.z)
			
			     } else if(wall.x>x) {
			        
			        if(y>wall.y1) shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x,wall.y1,this.x0,this.y,this.x1,this.y).x,this.x1)
			        else shadowRight = this.x1
			
			        shadowLeft = mathUtils.linesIntersect(x,y,wall.x,wall.y0,this.x0,this.y,this.x1,this.y).x    
							// Top of shadow
			        shadowHeight1 = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowLeft,1,shadowLeft,-1).y
			        shadowHeight2 = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowRight,1,shadowRight,-1).y
							// Bottom of shadow
			        shadowHeight3 = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowLeft,1,shadowLeft,-1).y
			        shadowHeight4 = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowRight,1,shadowRight,-1).y
			
			        ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight4+this.z)
			        ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight2+this.z)         
			        ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight1+this.z)
			        ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight3+this.z)
			     
			     }
			
			   } else if(wall.y!=y) {
			
			      shadowHeight1 = Math.min(this.top,mathUtils.linesIntersect(y,z,wall.y,wall.top,this.y,1,this.y,-1).y)
			      shadowHeight2 = Math.max(this.z,mathUtils.linesIntersect(y,z,wall.y,wall.z,this.y,1,this.y,-1).y)
			      shadowLeft = Math.max(mathUtils.linesIntersect(x,y,wall.x0,wall.y,this.x0,this.y,this.x1,this.y).x,this.x0)
			      shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x1,wall.y,this.x0,this.y,this.x1,this.y).x,this.x1)
			      
			      ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight2+this.z)
			      ret[ret.length] = new Point((shadowRight-this.x0),-shadowHeight1+this.z)         
			      ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight1+this.z)         
			      ret[ret.length] = new Point((shadowLeft-this.x0),-shadowHeight2+this.z)
			      
			   }
			
				 // Projection must be closed
			   ret[ret.length] = new Point(ret[0].x,ret[0].y)
			   
				 return ret
			
			}
			
			private function calculateWallProjectionVertical(x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			   
				 var ret:Array = []
			
			   if(!wall.vertical) {
			
			     if(wall.y<y) {
			
			         if(x<wall.x0) var shadowLeft:Number = Math.max(mathUtils.linesIntersect(x,y,wall.x0,wall.y,this.x,this.y0,this.x,this.y1).y,this.y0)
			         else shadowLeft = this.y0
			         
			         var shadowRight:Number = mathUtils.linesIntersect(x,y,wall.x1,wall.y,this.x,this.y0,this.x,this.y1).y
							 // Top of shadow
			         var shadowHeight2:Number = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowLeft,1,shadowLeft,-1).y
			         var shadowHeight1:Number = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowRight,1,shadowRight,-1).y
							 // Bottom of shadow
			         var shadowHeight4:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowLeft,1,shadowLeft,-1).y
			         var shadowHeight3:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowRight,1,shadowRight,-1).y
			         
			         ret[ret.length] = new Point((shadowRight-this.y0),-shadowHeight3+this.z)
			         ret[ret.length] = new Point((shadowRight-this.y0),-shadowHeight1+this.z)
			         ret[ret.length] = new Point((shadowLeft-this.y0),-shadowHeight2+this.z)        
			         ret[ret.length] = new Point((shadowLeft-this.y0),-shadowHeight4+this.z)
			         
			     } else if(wall.y>y) {
			        
			         if(x<wall.x0) shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x0,wall.y,this.x,this.y0,this.x,this.y1).y,this.y1)
			         else shadowRight = this.y1
			         
			         shadowLeft = mathUtils.linesIntersect(x,y,wall.x1,wall.y,this.x,this.y0,this.x,this.y1).y    
							 // Top of shadow
			         shadowHeight1 = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowLeft,1,shadowLeft,-1).y
			         shadowHeight2 = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowRight,1,shadowRight,-1).y
							 // Bottom of shadow
			         shadowHeight3 = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowLeft,1,shadowLeft,-1).y
			         shadowHeight4 = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowRight,1,shadowRight,-1).y
			         
			         ret[ret.length] = new Point((shadowRight-this.y0),-shadowHeight4+this.z)
			         ret[ret.length] = new Point((shadowRight-this.y0),-shadowHeight2+this.z)         
			         ret[ret.length] = new Point((shadowLeft-this.y0),-shadowHeight1+this.z)
			         ret[ret.length] = new Point((shadowLeft-this.y0),-shadowHeight3+this.z)
			         
			     }
			
			   } else if(wall.x!=x) {
			
			      shadowHeight1 = Math.min(this.top,mathUtils.linesIntersect(x,z,wall.x,wall.top,this.x,1,this.x,-1).y)
			      shadowHeight2 = Math.max(this.z,mathUtils.linesIntersect(x,z,wall.x,wall.z,this.x,1,this.x,-1).y)
			      shadowLeft = Math.max(mathUtils.linesIntersect(x,y,wall.x,wall.y0,this.x,this.y0,this.x,this.y1).y,this.y0)
			      shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x,wall.y1,this.x,this.y0,this.x,this.y1).y,this.y1)
			
			      ret[ret.length] = new Point((shadowRight-this.y0),-shadowHeight2+this.z)
			      ret[ret.length] = new Point((shadowRight-this.y0),-shadowHeight1+this.z)         
			      ret[ret.length] = new Point((shadowLeft-this.y0),-shadowHeight1+this.z)
			      ret[ret.length] = new Point((shadowLeft-this.y0),-shadowHeight2+this.z)
			
			   }
			
				 // Projection must be closed
			   ret[ret.length] = new Point(ret[0].x,ret[0].y)
				 return ret
				 
			}
			
			// Calculates and projects shadows of objects upon this wall
			private function renderObjectShadow(light:fLight,other:fObject,msk:Sprite):void {
				 
				 //trace("Shadow from "+other.id+" to "+this.id+" and light "+light.id)

				 // Calculate projection
				 var proj:fObjectProjection
				 if(light.z<other.z) proj = other.getProjection(this.top,light.x,light.y,light.z)
				 else proj = other.getProjection(this.z,light.x,light.y,light.z)
				 
				 if(this.vertical) {
				 		var intersect:Point = mathUtils.linesIntersect(this.x,this.y0,this.x,this.y1,proj.origin.x,proj.origin.y,proj.end.x,proj.end.y)
				 		var intersect2:Point = mathUtils.linesIntersect(this.x,this.z,this.x,this.top,proj.origin.x,this.z,light.x,light.z)
				 		var intersect3:Point = mathUtils.linesIntersect(this.x,this.z,this.x,this.top,proj.end.x,this.z,other.x,other.top)
				 } else {
				 		intersect = mathUtils.linesIntersect(this.x0,this.y,this.x1,this.y,proj.origin.x,proj.origin.y,proj.end.x,proj.end.y)
				 		intersect2 = mathUtils.linesIntersect(this.y,this.z,this.y,this.top,proj.origin.y,this.z,light.y,light.z)
				 		intersect3 = mathUtils.linesIntersect(this.y,this.z,this.y,this.top,proj.end.y,this.z,other.y,other.top)
				 }

				 // If no intersection ( parallell lines ) return
				 if(intersect==null) return
				 
				 // Cache or new Movieclip ?
				 if(!fWall.objectRenderCache[this.id+"_"+light.id]) {
				 		fWall.objectRenderCache[this.id+"_"+light.id] = new Object()
				 }
				 var cache = fWall.objectRenderCache[this.id+"_"+light.id]
				 if(!cache[other.id]) {
				 		cache[other.id] = other.getShadow(this)
				 		cache[other.id].transform.colorTransform = new ColorTransform(0,0,0,1,0,0,0,0)
				 }
				 
				 // Draw
				 var clip:Sprite = cache[other.id]
				 msk.addChild(clip)
				 
				 if(this.vertical) clip.x = intersect.y-this.y0
				 else clip.x = intersect.x-this.x0

		 		 clip.y = (this.z-intersect2.y)
				 clip.height = (intersect3.y-intersect2.y)
				 
			}

			// fLight leaves element
			/** @private */
			public override function lightOut(light:fLight):void {
			
			   // Hide container
			   if(this.lightStatuses[light.id]) this.hideLight(light)
			   
			   // Hide shadows
				 if(fWall.objectRenderCache[this.id+"_"+light.id]) {
				 		var cache = fWall.objectRenderCache[this.id+"_"+light.id]
				 		for(var i in cache) {
				 			try {
				 				cache[i].parent.removeChild(cache[i])
				 			} catch(e:Error) {
				 			
				 			}
				 		}			   
				 }
			   
			}

		}

}