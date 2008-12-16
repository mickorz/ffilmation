package org.ffilmation.engine.renderEngines.flash9RenderEngine {
	
		// Imports
		import flash.display.*
		import flash.utils.*
		import flash.geom.Point
		import flash.geom.Matrix
		import flash.geom.Rectangle
		import flash.geom.ColorTransform
		import flash.utils.getDefinitionByName

		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.logicSolvers.projectionSolver.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers.*

		/**
		* This class renders an fFloor
		* @private
		*/
		public class fFlash9FloorRenderer extends fFlash9PlaneRenderer {
		
			// Static properties and Render cache
			private static var floorProjectionCache:fFloorProjectionCache = new fFloorProjectionCache()
			private static var wallProjectionCache:Dictionary = new Dictionary(true)
			private static var objectProjectionCache:Dictionary = new Dictionary(true)
			public static var matrix:Matrix = new Matrix(0.7071075439453125,-0.35355377197265625,0.7071075439453125,0.35355377197265625,0,0)
						
			// Public properties
	    public var polyClip:Array

			// Constructor
			function fFlash9FloorRenderer(rEngine:fFlash9RenderEngine,container:MovieClip,element:fFloor):void {
			
				 // Generate sprite
				 var destination:Sprite = objectPool.getInstanceOf(Sprite) as Sprite
				 container.addChild(destination)
			   
				 // Set specific wall dimensions
			   this.scrollR = new Rectangle(0, 0, element.width, element.depth)
				 this.planeDeform = fFlash9FloorRenderer.matrix
				 
			   // Previous
				 super(rEngine,element,element.width,element.depth,destination,container)
			   
				 // Create polygon bounds, for clipping algorythm
				 this.polyClip = [ new Point(element.x,element.y),
				 							     new Point(element.x+element.width,element.y),
				 							     new Point(element.x+element.width,element.y+element.depth),
				 							     new Point(element.x,element.y+element.depth) ]
			
			}

			/**
			* Gives geometry container the proper dimensions
			*/
			public override function setDimensions(lClip:DisplayObject):void {
				lClip.width = (this.element as fFloor).width
				lClip.height = (this.element as fFloor).depth
		  }

			/**
			* Place asset its proper position
			*/
			public override function place():void {
			   // Place in position
			   var coords:Point = fScene.translateCoords(this.element.x,this.element.y,this.element.z)
			   this.container.x = coords.x
			   this.container.y = coords.y+1
			   
			}

			/**
			* Extra functionality to render start
			*/
			public override function processRenderStart(light:fLight):void {

			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
			   var element:fFloor = this.element as fFloor
			   
			   // Light limits
			   if(light.size==Infinity) {
			      
			      lightStatus.lUp = element.y-1
			      lightStatus.lDown = element.y+element.depth+1
			      lightStatus.lLeft = element.x-1
			      lightStatus.lRight = element.x+element.width+1
			      
			   } else {
			
			      var n1:Number = light.y-light.size
			      var n2:Number = element.y-1
			      lightStatus.lUp = (n1>n2) ? n1 : n2
			      n1 = light.y+light.size
			      n2 = element.y+element.depth+1
			      lightStatus.lDown = (n1<n2) ? n1 : n2
			      n1 = light.x-light.size
			      n2 = element.x-1
			      lightStatus.lLeft = (n1>n2) ? n1 : n2 
			      n1 = light.x+light.size
			      n2 = element.x+element.width+1
			      lightStatus.lRight = (n1<n2) ? n1 : n2
			
			   }
			
			}
			
			/**
			* Render ( draw ) light
			*/
			public override function renderLight(light:fLight):void {
			
			   var status:fLightStatus = this.lightStatuses[light.uniqueId]
			   var lClip:Sprite = this.lightClips[light.uniqueId]
				
			   if(status.lightZ != light.z) {
			      status.lightZ = light.z
			      var d:Number = light.z-this.element.z
			      this.setLightDistance(light,(d>0)?d:-d)
			   }    
			
			   // Move light
	   	   this.setLightCoordinates(light,light.x-this.element.x,light.y-this.element.y)
			
			}
			
			/**
			* Calculates and projects shadows upon this floor
			*/
			public override function renderShadowInt(light:fLight,other:fRenderableElement,msk:Sprite):void {
				
			   if(other is fFloor) this.renderFloorShadow(light,other as fFloor,msk)
			   if(other is fWall) this.renderWallShadow(light,other as fWall,msk)
			   if(other is fObject) this.renderObjectShadow(light,other as fObject,msk)
			}
			
			/** 
			* Resets shadows. This is called when the fEngine.shadowQuality value is changed
			*/
			public override function resetShadowsInt():void {
				for(var i in fFlash9FloorRenderer.objectProjectionCache) {
					var a:Dictionary = fFlash9FloorRenderer.objectProjectionCache[i]
					for(var j in a) {
						 try {
						 	var clip:Sprite = a[j].shadow
						 	clip.parent.parent.removeChild(clip.parent)
							this.rEngine.returnObjectShadow(a[j])
			 	 			delete a[j]
						 } catch (e:Error) {
						  //trace("Floor reset error: "+e)	
						 }
					}
					delete fFlash9FloorRenderer.objectProjectionCache[i]
				}
			}

			/**
			* Calculates and projects shadows of objects upon this floor
			*/
			private function renderObjectShadow(light:fLight,other:fObject,msk:Sprite):void {
			   
				 // Too far away ?
				 if((other.z-this.element.z)>fObject.SHADOWRANGE) return

				 // Get projection
				 var proj:fObjectProjection = this.rEngine.getObjectSpriteProjection(other,this.element.z,light.x,light.y,light.z)
				 
				 if(proj==null) return

			   // Simple shadows ?
			   var simpleShadows:Boolean = (other.customData.flash9Renderer as fFlash9ObjectRenderer).simpleShadows
			   var eraseShadows:Boolean = (other.customData.flash9Renderer as fFlash9ObjectRenderer).eraseShadows

				 // Cache or new Movieclip ?
				 if(!fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId]) {
				 		fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId] = new Dictionary(true)
				 }
				 var cache:Dictionary = fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId]
				 if(!cache[other.uniqueId]) {
				 		cache[other.uniqueId] = this.rEngine.getObjectShadow(other,this.element)
				 		if(!simpleShadows) cache[other.uniqueId].shadow.transform.colorTransform = new ColorTransform(0,0,0,1,0,0,0,0)
				 }
				 
				 var distance:Number = (other.z-this.element.z)/fObject.SHADOWRANGE

				 // Draw
				 var clip:Sprite = cache[other.uniqueId].shadow
				 msk.addChild(clip.parent)
				 clip.alpha = 1-distance
				 
				 // Rotate and deform
		 		 clip.parent.x = proj.origin.x-this.element.x
				 clip.parent.y = proj.origin.y-this.element.y
				 if(!simpleShadows) {
				 		clip.height = proj.size*(1+fObject.SHADOWSCALE*distance)
				 		clip.scaleX = 1+fObject.SHADOWSCALE*distance
				 		clip.parent.rotation = 90+mathUtils.getAngle(light.x,light.y,other.x,other.y)
				 }
				 
				 // Adjust alpha if necessary
				 if(light.size!=Infinity && !eraseShadows && !simpleShadows) {
				 		var distToLight:Number = mathUtils.distance(light.x,light.y,other.x,other.y)
				 		var distToLightBorder:Number = (this.lightMasks[light.uniqueId].width/2)-distToLight
				 	  if(distToLightBorder<clip.height) {
				 	  	var fade:Number = 1-((clip.height-distToLightBorder)/clip.height)
				 	  	clip.alpha *= fade
				 	  }
				 }


			}
			
			/**
			* Delete character shadows upon this floor
			*/
			public override function removeShadow(light:fLight,other:fRenderableElement):void {
			   
					var o:fCharacter = other as fCharacter
			   	
			 	 	var cache:Dictionary = fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId]
			 	 	var clip:Sprite = cache[other.uniqueId].shadow
			 	 	if(clip.parent.parent) clip.parent.parent.removeChild(clip.parent)
	 	 	
			 	 	this.rEngine.returnObjectShadow(cache[other.uniqueId])
			 	 	delete cache[other.uniqueId]

			}

			/**
			* Calculates and projects shadows of another floor upon this floor
			*/
			private function renderFloorShadow(light:fLight,other:fFloor,msk:Sprite):void {
			   
			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
			   var len:int
			
			   // Draw mask
			   msk.graphics.beginFill(0x000000,100)
			   
			   // Read cache or write cache ?
			   if(fFlash9FloorRenderer.floorProjectionCache.x!=light.x || fFlash9FloorRenderer.floorProjectionCache.y!=light.y
			      || fFlash9FloorRenderer.floorProjectionCache.z!=light.z || fFlash9FloorRenderer.floorProjectionCache.fl!=other ) {
			   	
					  // New Key
			   		fFlash9FloorRenderer.floorProjectionCache.x=light.x 	
			   		fFlash9FloorRenderer.floorProjectionCache.y=light.y 	
			   		fFlash9FloorRenderer.floorProjectionCache.z=light.z 	
			   		fFlash9FloorRenderer.floorProjectionCache.fl=other
			
			   		// New value
			   		fFlash9FloorRenderer.floorProjectionCache.points = fProjectionSolver.calculateFloorProjection(light.x,light.y,light.z,other.bounds,this.element.z)
			   		fFlash9FloorRenderer.floorProjectionCache.holes = []
					  for(h=0;h<other.holes.length;h++) {
					 		fFlash9FloorRenderer.floorProjectionCache.holes[h] = fProjectionSolver.calculateFloorProjection(light.x,light.y,light.z,other.holes[h].bounds,this.element.z)
					  }
			
			   }
			
				 var points:Array = fFlash9FloorRenderer.floorProjectionCache.points
				 
				 
				 var n1:Number = points[0].x
				 var n2:Number = lightStatus.lLeft
			   var pLeft:Number = (n1>n2) ? n1 : n2
			   n1 = points[0].y
			   n2 = lightStatus.lUp
			   var pUp:Number = (n1<n2) ? n1 : n2
			   n1 = points[2].x
			   n2 = lightStatus.lRight
			   var pRight:Number = (n1<n2) ? n1 : n2
			   n1 = points[2].y
			   n2 = lightStatus.lDown
			   var pDown:Number = (n1<n2) ? n1 : n2
			   msk.graphics.moveTo(pLeft-this.element.x,pUp-this.element.y)
				 msk.graphics.lineTo(pLeft-this.element.x,pDown-this.element.y)
				 msk.graphics.lineTo(pRight-this.element.x,pDown-this.element.y)
				 msk.graphics.lineTo(pRight-this.element.x,pUp-this.element.y)

				 // For each hole, draw light
				 len = other.holes.length
				 
				 for(var h:int=0;h<len;h++) {
 				 	
				 		if(other.holes[h].open) {
					 		points = fFlash9FloorRenderer.floorProjectionCache.holes[h]
					 		
				 			n1 = points[0].x
				 			n2 = lightStatus.lLeft
			   			pLeft = (n1>n2) ? n1 : n2
			   			n1 = points[0].y
			   			n2 = lightStatus.lUp
			   			pUp = (n1<n2) ? n1 : n2
			   			n1 = points[2].x
			   			n2 = lightStatus.lRight
			   			pRight = (n1<n2) ? n1 : n2
			   			n1 = points[2].y
			   			n2 = lightStatus.lDown
			   			pDown = (n1<n2) ? n1 : n2
					 		
				    	msk.graphics.moveTo(pRight-this.element.x,pUp-this.element.y)
				    	msk.graphics.lineTo(pRight-this.element.x,pDown-this.element.y)
				    	msk.graphics.lineTo(pLeft-this.element.x,pDown-this.element.y)
			      	msk.graphics.lineTo(pLeft-this.element.x,pUp-this.element.y)
				    }
				 }
			
			   msk.graphics.endFill()

			}

			/**
			* Calculates and draws the shadow of a given wall from a given light
			*/
			private function renderWallShadow(light:fLight,wall:fWall,msk:Sprite):void {
			   
			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
				 var len:int
			   
				 var cache:fWallProjectionCache = fFlash9FloorRenderer.wallProjectionCache[this.element.uniqueId+"_"+wall.uniqueId]
				 if(!cache) cache = fFlash9FloorRenderer.wallProjectionCache[this.element.uniqueId+"_"+wall.uniqueId] = new fWallProjectionCache()
				 	
			   // Update cache ?
			   if(cache.x!=light.x || cache.y!=light.y || cache.z!=light.z) {
			   	
					  // New Key
			   		cache.x=light.x 	
			   		cache.y=light.y 	
			   		cache.z=light.z 	
			
			   		// New value
			   		cache.points = fProjectionSolver.calculateWallProjection(light.x,light.y,light.z,wall.bounds,this.element.z,this.scene)
			   		cache.holes = []
			   		len = wall.holes.length
					  for(h=0;h<len;h++) {
					 		cache.holes[h] = fProjectionSolver.calculateWallProjection(light.x,light.y,light.z,wall.holes[h].bounds,this.element.z,this.scene)
					  }
			
				 }
			
				 // Clipping viewport
				 var vp:vport = new vport()
				 vp.x_min = lightStatus.lLeft
				 vp.x_max = lightStatus.lRight
				 vp.y_min = lightStatus.lUp
				 vp.y_max = lightStatus.lDown
				 
				 var points:Array = polygonUtils.clipPolygon(cache.points,vp)	 

				 if(points.length>0) {
				 
 				 		// Draw mask
 				 		msk.graphics.beginFill(0x000000,100)

				 		msk.graphics.moveTo(points[0].x-this.element.x,points[0].y-this.element.y)
				 		for(var i:Number=1;i<points.length;i++) {
				 			msk.graphics.lineTo(points[i].x-this.element.x,points[i].y-this.element.y)
			 			}
				 		msk.graphics.lineTo(points[0].x-this.element.x,points[0].y-this.element.y)
				 		
				 		// For each hole, draw light
				 		len = cache.holes.length
				 		for(var h:int=0;h<len;h++) {
			   		
							 	if(wall.holes[h].open) {
							 		
							 		// Clip
							  	points = polygonUtils.clipPolygon(cache.holes[h],vp)	 
				 			  	if(points.length>0) {
					 			  	msk.graphics.moveTo(points[0].x-this.element.x,points[0].y-this.element.y)
				 			  		for(i=points.length-1;i>=0;i--) {
					 			  		msk.graphics.lineTo(points[i].x-this.element.x,points[i].y-this.element.y)
				 			  		}
				 					}
				 					
				 				}
				 				
				 		}
				    
		 		 		// Clear mask
		 		 		msk.graphics.endFill() 
				    
				 }
				 
				 
			}
			
			/**
			* Light leaves element
			*/
			public override function lightOut(light:fLight):void {
			
			   // Hide container
			   if(this.lightStatuses && this.lightStatuses[light.uniqueId]) {
			  	 var lClip:Sprite = this.lightClips[light.uniqueId]
			   	 this.lightC.removeChild(lClip)
			   }

			   // Hide shadows
				 if(fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId]) {
				 		var cache:Dictionary = fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId]
				 		for(var i in cache) {
							try {				 		
			 	 				var clip:Sprite = cache[i].shadow
			 	 				if(clip.parent.parent) clip.parent.parent.removeChild(clip.parent)
			 	 				this.rEngine.returnObjectShadow(cache[i])
			 	 				delete cache[i]
				 			} catch(e:Error) {	}	
				 		}		   
				 }
			   
		 		 this.undoCache(true)


			}

			/**
			* Light is to be reset
			*/
		  public override function lightReset(light:fLight):void {
		  	
		  	this.lightOut(light)
		  	delete this.lightStatuses[light.uniqueId]
		  	fFlash9RenderEngine.recursiveDelete(this.lightClips[light.uniqueId])
		  	delete this.lightClips[light.uniqueId]
		  	delete fFlash9FloorRenderer.objectProjectionCache[this.element.uniqueId+"_"+light.uniqueId]
		  	
			}


			/** @private */
			public function disposeFloorRenderer():void {

	    	this.polyClip = null
				this.resetShadowsInt()
				this.disposePlaneRenderer()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposeFloorRenderer()
			}		

			
		}
}
