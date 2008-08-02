// Character class
package org.ffilmation.engine.logicSolvers.projectionSolver {
	
		// Imports
		import flash.geom.Point
		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*

		/** 
		* This class calculates projections from one element into other elements. The results are used mainly to render shadows but can
		* also be applied to visibility calculations.
		* @private
		*/
		public class fProjectionSolver {

			/** 
			* This method calculates the projection of any element into an imaginary plane at a given Z
			* @return An Array of Points
			*/
			public static function calculateProjection(originx:Number,originy:Number,originz:Number,element:fRenderableElement,destinyZ:Number):Array {
				
				if(element is fFloor) return fProjectionSolver.calculateFloorProjection(originx,originy,originz,(element as fFloor).bounds,destinyZ)
				if(element is fWall) return fProjectionSolver.calculateWallProjection(originx,originy,originz,(element as fWall).bounds,destinyZ,element.scene)
				if(element is fObject) return fProjectionSolver.calculateObjectProjection(originx,originy,originz,element as fObject,destinyZ)
				return null
					
			}

			/** 
			* This method calculates the projection of a floor into an imaginary plane at a given Z
			* @return An Array of Points
			*/
			public static function calculateFloorProjection(x:Number,y:Number,z:Number,floor:fPlaneBounds,destinyZ:Number):Array {

			   var dz:Number = 1+(floor.z-destinyZ)/(z-floor.z)
			
			   var pUp:Number = y+(floor.y-y)*dz-1
			   var pDown:Number = y+(floor.y+floor.depth-y)*dz+1
			   var pLeft:Number = x+(floor.x-x)*dz-1
			   var pRight:Number = x+(floor.x+floor.width-x)*dz+1
			   
			   var ret:Array = new Array
			   ret.push(new Point(pLeft,pUp))
			   ret.push(new Point(pRight,pUp))
			   ret.push(new Point(pRight,pDown))
			   ret.push(new Point(pLeft,pDown))

			   // Projection must be closed
			   ret.push(ret[0])
			   return ret

			}

			/** 
			* This method calculates the projection of a wall into an imaginary plane at a given Z
			* @return An Array of Points
			*/
			public static function calculateWallProjection(x:Number,y:Number,z:Number,wall:fPlaneBounds,destinyZ:Number,scene:fScene):Array {

				 var ret:Array = []
			
			   if(wall.vertical) {
			
						if(wall.x==x) x++
						
						if(wall.top<z) {
								var dz:Number = 1+(wall.top-destinyZ)/(z-wall.top)
			      		var pLeft:Number = x+(wall.x-x)*dz
			      }
			      else {
			      		if(wall.x<x) pLeft = 0
			      		if(wall.x>x) pLeft = scene.width
						}
			
			      var pUp:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pLeft,1,pLeft,-1).y-1
			     	ret.push(new Point(pLeft, pUp))
			     
			      var pDown:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pLeft,1,pLeft,-1).y+1
			     	ret.push(new Point(pLeft,pDown))
			
						if(wall.z>destinyZ) {
					 			var dzb:Number = 1+(wall.z-destinyZ)/(z-wall.z)
							  var pRight:Number = x+(wall.x-x)*dzb
			      		pUp = mathUtils.linesIntersect(x,y,wall.x,wall.y0,pRight,1,pRight,-1).y-1
			      		pDown = mathUtils.linesIntersect(x,y,wall.x,wall.y1,pRight,1,pRight,-1).y+1
			      		ret.push(new Point(pRight,pDown))
			      		ret.push(new Point(pRight,pUp))
			      } else {
			      		ret.push(new Point(wall.x+1,wall.y1-1))
			      		ret.push(new Point(wall.x+1,wall.y0-1))
						}
			
			
			   } else {
			   	
						if(wall.y==y) y++
			
						if(wall.top<z) {
				   	   dz = 1+(wall.top-destinyZ)/(z-wall.top)
						   pUp = y+(wall.y-y)*dz
			      } 
			      else {
			      	 if(wall.y<y) pUp = 0
			      	 if(wall.y>y) pUp = scene.depth
					  }
					  
			      pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pUp,-1,pUp).x+1
			      ret.push(new Point(pLeft, pUp))
			
						if(wall.z>destinyZ) {
							 dzb = 1+(wall.z-destinyZ)/(z-wall.z)
							 pDown = y+(wall.y-y)*dzb
			      	 pLeft = mathUtils.linesIntersect(x,y,wall.x0,wall.y,1,pDown,-1,pDown).x-1
			         pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pDown,-1,pDown).x+1
						   ret.push(new Point(pLeft,pDown))
			         ret.push(new Point(pRight,pDown))
						} else {
			         ret.push(new Point(wall.x0+1,wall.y-1))
				       ret.push(new Point(wall.x1+1,wall.y-1))
			      }
			
			      pRight = mathUtils.linesIntersect(x,y,wall.x1,wall.y,1,pUp,-1,pUp).x+1
			      ret.push(new Point(pRight,pUp))
			
			   }
			   
			   // Projection must be closed
			   ret.push(ret[0])
			   return ret
			
			}

			/** 
			* This method calculates the projection of an object into an imaginary plane at a given Z
			* @return An Array of Points
			*/
			public static function calculateObjectProjection(x:Number,y:Number,z:Number,obj:fObject,destinyZ:Number):Array {

				 var zbase:Number = obj.z
				 var ztop:Number = obj.top
				 var r:Number = obj.radius
				 var height:Number = obj.height
				 
				 // Get 2D vector from point to object
				 var vec:Vector = new Vector(obj.x-x,obj.y-y)
				 vec.normalize()
				 
				 var dist:Number = mathUtils.distance(x,y,obj.x,obj.y)
				 
				 // Calculate projection from coordinates to base of
				 var dzI:Number = (zbase-destinyZ)/(z-zbase)
				 var projSizeI:Number = dist*dzI

				 // Calculate projection from coordinates to top of object
				 if(ztop<z) {
				 		var dzF:Number = (ztop-destinyZ)/(z-ztop)
				 		var projSizeF:Number = dist*dzF
			
					  // Projection size
						var projSize:Number = projSizeF-projSizeI
						if(projSize>fObject.MAXSHADOW*height || projSize<=0) projSize=fObject.MAXSHADOW*height

				 } else {
				 		projSize=fObject.MAXSHADOW*height
				 }

				 // Calculate origin point
				 var origin:Point = new Point(obj.x+vec.x*projSizeI,obj.y+vec.y*projSizeI)
				 
				 // Get perpendicular vector
				 var perp:Vector = vec.getPerpendicular() 
         
				 // Get first 2 points
				 var p1:Point = new Point(origin.x+r*perp.x,origin.y+r*perp.y)
				 var p2:Point = new Point(origin.x-r*perp.x,origin.y-r*perp.y)
				 
				 // Use normalized direction vector and use to find the 2 other points				 
				 var p3:Point = new Point(p2.x+vec.x*projSize,p2.y+vec.y*projSize)
				 var p4:Point = new Point(p1.x+vec.x*projSize,p1.y+vec.y*projSize)
				 				 
				 var ret:Array = [p1,p2,p3,p4]

			   // Projection must be closed
			   ret.push(ret[0])
			   return ret
			   
			}

			/** 
			* This method calculates the projection of a floor into an horizontal wall
			* @return An Array of Points
			*/
			public static function calculateFloorProjectionIntoHorizontalWall(target:fWall,x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			   
				 var ret:Array = []
				 
			   try {
			   	
			   		var shadowHeight:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,target.y,1,target.y,-1).y
			   		var shadowLeft:Number = mathUtils.linesIntersect(x,z,wall.x,wall.z,1,shadowHeight,-1,shadowHeight).x    
			   		var shadowRight:Number = mathUtils.linesIntersect(x,z,wall.x+wall.width,wall.z,1,shadowHeight,-1,shadowHeight).x    
			   		
			   		// Floor level 
			   		var floorfLevel:Number = 0
			   		var dz:Number = 1+(wall.z-target.z)/(z-wall.z)
			 	 		var pDown:Number = y+(wall.y+wall.depth-y)*dz
			   		
			   		if(target.y>pDown) {
			   		
			   		   floorfLevel = mathUtils.linesIntersect(y,z,wall.y+wall.depth,wall.z,target.y,1,target.y,-1).y
			   		   var shadowFLeft:Number = mathUtils.linesIntersect(x,z,wall.x,wall.z,1,floorfLevel,-1,floorfLevel).x    
			   		   var shadowFRight:Number = mathUtils.linesIntersect(x,z,wall.x+wall.width,wall.z,1,floorfLevel,-1,floorfLevel).x    
			   		
			   		   ret[ret.length] = new Point((shadowFRight-target.x0),-floorfLevel+target.z)
			   		   ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight+target.z)         
			   		   ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight+target.z)         
			   		   ret[ret.length] = new Point((shadowFLeft-target.x0),-floorfLevel+target.z)
			   		
			   		} else {
			   		   
				 		   var pLeft:Number = x+(wall.x-x)*dz
				 		   var pRight:Number = x+(wall.x+wall.width-x)*dz
			   		   ret[ret.length] = new Point((pRight-target.x0),0)
			   		   ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight+target.z)         
			   		   ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight+target.z) 
			   		   ret[ret.length] = new Point((pLeft-target.x0),0)
			   		
			   		}
			   
			   } catch(e:Error) {
			   	
			   		ret = new Array
			   }
			
				 return ret   
			
			}
			
			/** 
			* This method calculates the projection of a floor into a vertical wall
			* @return An Array of Points
			*/
			public static function calculateFloorProjectionIntoVerticalWall(target:fWall,x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			
				 var ret:Array = []
			
			   try {

			   		var shadowHeight:Number = mathUtils.linesIntersect(x,z,wall.x+wall.width,wall.z,target.x,1,target.x,-1).y
			   		var shadowUp:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,1,shadowHeight,-1,shadowHeight).x    
			   		var shadowDown:Number = mathUtils.linesIntersect(y,z,wall.y+wall.depth,wall.z,1,shadowHeight,-1,shadowHeight).x    
			   		
			   		// Floor level 
			   		var floorfLevel:Number = 0
			   		var dz:Number = 1+(wall.z-target.z)/(z-wall.z)
			 	 		var pLeft:Number = x+(wall.x-x)*dz
			   		
			   		if(target.x<pLeft) {
			   		
			   		   floorfLevel = mathUtils.linesIntersect(x,z,wall.x,wall.z,target.x,1,target.x,-1).y
			   		   var shadowFUp:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,1,floorfLevel,-1,floorfLevel).x
			   		   var shadowFDown:Number = mathUtils.linesIntersect(y,z,wall.y+wall.depth,wall.z,1,floorfLevel,-1,floorfLevel).x
			   		
			   		   ret[ret.length] = new Point((shadowFDown-target.y0),-floorfLevel+target.z)
			   		   ret[ret.length] = new Point((shadowDown-target.y0),-shadowHeight+target.z)         
			   		   ret[ret.length] = new Point((shadowUp-target.y0),-shadowHeight+target.z)         
			   		   ret[ret.length] = new Point((shadowFUp-target.y0),-floorfLevel+target.z)
			   		
			   		 } else {
			   		
			   			 var pUp:Number = y+(wall.y-y)*dz
			   			 var pDown:Number = y+(wall.y+wall.depth-y)*dz
			   		   ret[ret.length] = new Point((pDown-target.y0),0)
			   		   ret[ret.length] = new Point((shadowDown-target.y0),-shadowHeight+target.z)         
			   		   ret[ret.length] = new Point((shadowUp-target.y0),-shadowHeight+target.z)
			   		   ret[ret.length] = new Point((pUp-target.y0),0)
			   		
			   		 }

				 } catch(e:Error) {
				 	
				 			ret = new Array
				 			
				 }
			   
			   return ret
			   
			}

			/** 
			* This method calculates the projection of a wall into an horizontal wall
			* @return An Array of Points
			*/
			public static function calculateWallProjectionIntoHorizontalWall(target:fWall,x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			
				 var ret:Array = []
			
			   if(wall.vertical) {
			
			     if(wall.x<x) {
			
			        if(y>wall.y1) var shadowLeft:Number = Math.max(mathUtils.linesIntersect(x,y,wall.x,wall.y1,target.x0,target.y,target.x1,target.y).x,target.x0)
			        else shadowLeft = target.x0
			
			        var shadowRight:Number = mathUtils.linesIntersect(x,y,wall.x,wall.y0,target.x0,target.y,target.x1,target.y).x
							// Top of shadow
			        var shadowHeight1:Number = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowRight,1,shadowRight,-1).y
			        var shadowHeight2:Number = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowLeft,1,shadowLeft,-1).y
							// Bottom of shadow
			        var shadowHeight3:Number = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowRight,1,shadowRight,-1).y
			        var shadowHeight4:Number = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowLeft,1,shadowLeft,-1).y
			
			        ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight3+target.z)
			        ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight1+target.z)
			        ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight2+target.z)        
			        ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight4+target.z)
			
			     } else if(wall.x>x) {
			        
			        if(y>wall.y1) shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x,wall.y1,target.x0,target.y,target.x1,target.y).x,target.x1)
			        else shadowRight = target.x1
			
			        shadowLeft = mathUtils.linesIntersect(x,y,wall.x,wall.y0,target.x0,target.y,target.x1,target.y).x    
							// Top of shadow
			        shadowHeight1 = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowLeft,1,shadowLeft,-1).y
			        shadowHeight2 = mathUtils.linesIntersect(x,z,wall.x,wall.top,shadowRight,1,shadowRight,-1).y
							// Bottom of shadow
			        shadowHeight3 = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowLeft,1,shadowLeft,-1).y
			        shadowHeight4 = mathUtils.linesIntersect(x,z,wall.x,wall.z,shadowRight,1,shadowRight,-1).y
			
			        ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight4+target.z)
			        ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight2+target.z)         
			        ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight1+target.z)
			        ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight3+target.z)
			     
			     }
			
			   } else if(wall.y!=y) {
			
			      shadowHeight1 = Math.min(target.top,mathUtils.linesIntersect(y,z,wall.y,wall.top,target.y,1,target.y,-1).y)
			      shadowHeight2 = Math.max(target.z,mathUtils.linesIntersect(y,z,wall.y,wall.z,target.y,1,target.y,-1).y)
			      shadowLeft = Math.max(mathUtils.linesIntersect(x,y,wall.x0,wall.y,target.x0,target.y,target.x1,target.y).x,target.x0)
			      shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x1,wall.y,target.x0,target.y,target.x1,target.y).x,target.x1)
			      
			      ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight2+target.z)
			      ret[ret.length] = new Point((shadowRight-target.x0),-shadowHeight1+target.z)         
			      ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight1+target.z)         
			      ret[ret.length] = new Point((shadowLeft-target.x0),-shadowHeight2+target.z)
			      
			   }
			
				 // Projection must be closed
			   ret[ret.length] = new Point(ret[0].x,ret[0].y)
			   
				 return ret
			
			}

			/** 
			* This method calculates the projection of a wall into a vertical wall
			* @return An Array of Points
			*/
			public static function calculateWallProjectionIntoVerticalWall(target:fWall,x:Number,y:Number,z:Number,wall:fPlaneBounds):Array {
			   
				 var ret:Array = []
			
			   if(!wall.vertical) {
			
			     if(wall.y<y) {
			
			         if(x<wall.x0) var shadowLeft:Number = Math.max(mathUtils.linesIntersect(x,y,wall.x0,wall.y,target.x,target.y0,target.x,target.y1).y,target.y0)
			         else shadowLeft = target.y0
			         
			         var shadowRight:Number = mathUtils.linesIntersect(x,y,wall.x1,wall.y,target.x,target.y0,target.x,target.y1).y
							 // Top of shadow
			         var shadowHeight2:Number = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowLeft,1,shadowLeft,-1).y
			         var shadowHeight1:Number = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowRight,1,shadowRight,-1).y
							 // Bottom of shadow
			         var shadowHeight4:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowLeft,1,shadowLeft,-1).y
			         var shadowHeight3:Number = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowRight,1,shadowRight,-1).y
			         
			         ret[ret.length] = new Point((shadowRight-target.y0),-shadowHeight3+target.z)
			         ret[ret.length] = new Point((shadowRight-target.y0),-shadowHeight1+target.z)
			         ret[ret.length] = new Point((shadowLeft-target.y0),-shadowHeight2+target.z)        
			         ret[ret.length] = new Point((shadowLeft-target.y0),-shadowHeight4+target.z)
			         
			     } else if(wall.y>y) {
			        
			         if(x<wall.x0) shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x0,wall.y,target.x,target.y0,target.x,target.y1).y,target.y1)
			         else shadowRight = target.y1
			         
			         shadowLeft = mathUtils.linesIntersect(x,y,wall.x1,wall.y,target.x,target.y0,target.x,target.y1).y    
							 // Top of shadow
			         shadowHeight1 = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowLeft,1,shadowLeft,-1).y
			         shadowHeight2 = mathUtils.linesIntersect(y,z,wall.y,wall.top,shadowRight,1,shadowRight,-1).y
							 // Bottom of shadow
			         shadowHeight3 = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowLeft,1,shadowLeft,-1).y
			         shadowHeight4 = mathUtils.linesIntersect(y,z,wall.y,wall.z,shadowRight,1,shadowRight,-1).y
			         
			         ret[ret.length] = new Point((shadowRight-target.y0),-shadowHeight4+target.z)
			         ret[ret.length] = new Point((shadowRight-target.y0),-shadowHeight2+target.z)         
			         ret[ret.length] = new Point((shadowLeft-target.y0),-shadowHeight1+target.z)
			         ret[ret.length] = new Point((shadowLeft-target.y0),-shadowHeight3+target.z)
			         
			     }
			
			   } else if(wall.x!=x) {
			
			      shadowHeight1 = Math.min(target.top,mathUtils.linesIntersect(x,z,wall.x,wall.top,target.x,1,target.x,-1).y)
			      shadowHeight2 = Math.max(target.z,mathUtils.linesIntersect(x,z,wall.x,wall.z,target.x,1,target.x,-1).y)
			      shadowLeft = Math.max(mathUtils.linesIntersect(x,y,wall.x,wall.y0,target.x,target.y0,target.x,target.y1).y,target.y0)
			      shadowRight = Math.min(mathUtils.linesIntersect(x,y,wall.x,wall.y1,target.x,target.y0,target.x,target.y1).y,target.y1)
			
			      ret[ret.length] = new Point((shadowRight-target.y0),-shadowHeight2+target.z)
			      ret[ret.length] = new Point((shadowRight-target.y0),-shadowHeight1+target.z)         
			      ret[ret.length] = new Point((shadowLeft-target.y0),-shadowHeight1+target.z)
			      ret[ret.length] = new Point((shadowLeft-target.y0),-shadowHeight2+target.z)
			
			   }
			
				 // Projection must be closed
			   ret[ret.length] = new Point(ret[0].x,ret[0].y)
				 return ret
				 
			}



		}

}
