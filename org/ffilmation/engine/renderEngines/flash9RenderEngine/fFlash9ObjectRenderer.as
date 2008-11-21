// Basic renderable element class

package org.ffilmation.engine.renderEngines.flash9RenderEngine {
	
		// Imports
		import org.ffilmation.utils.*
	  import flash.display.*
	  import flash.events.*	
		import flash.utils.*
		import flash.geom.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.logicSolvers.projectionSolver.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers.*

		/**
		* This class renders an fObject
		* @private
		*/
		public class fFlash9ObjectRenderer extends fFlash9ElementRenderer {
			
			// Private properties
	    private var baseObj:MovieClip
			private var lights:Array
			private var glight:fGlobalLight
			private var allShadows:Array
			private var currentSprite:MovieClip
			private var currentSpriteIndex:Number = -1
			private var occlusionCount:Number = 0

			// These reflects how shadows are rendered
			public var simpleShadows:Boolean = false
			public var eraseShadows:Boolean = true
			
			// Protected properties
			protected var projectionCache:fObjectProjectionCache
			
			/** @private */
	    public var shadowObj:Class
			
			// Constructor
			/** @private */
			function fFlash9ObjectRenderer(rEngine:fFlash9RenderEngine,container:MovieClip,element:fObject):void {
				
				 // Attach base clip
				 this.baseObj = new MovieClip()
				 container.addChild(this.baseObj)
				 this.baseObj.mouseEnabled = false
		     
				 // Previous
				 super(rEngine,element,this.baseObj,container)

				 // Shadows
				 this.resetShadows()

				 // Light control
				 this.lights = new Array()
			 
			 	 // Projection cache
			 	 this.projectionCache = new fObjectProjectionCache
			 	 
			 	 // Cache as bitmap non-animated objects
			 	 this.container.cacheAsBitmap = element.animated!=true
			 	 
			 	 // Show and hide listeners, to redraw shadows
			 	 element.addEventListener(fRenderableElement.SHOW,this.showListener,false,0,true)
			 	 element.addEventListener(fRenderableElement.HIDE,this.hideListener,false,0,true)
			 	 element.addEventListener(fObject.NEWORIENTATION,this.rotationListener,false,0,true)
			 	 element.addEventListener(fObject.GOTOANDPLAY,this.gotoAndPlayListener,false,0,true)
			 	 element.addEventListener(fObject.GOTOANDSTOP,this.gotoAndStopListener,false,0,true)
			 	 if(element is fCharacter) {
			 	 		element.addEventListener(fElement.MOVE,this.moveListener,false,0,true)
			 	 }
			 	 
				 this.occlusionCount = 0
				 
			 	 // Draw initial sprite
				 this.rotationListener(new Event("Dummy"))
				 
			}

			/**
			* Place asset its proper position
			*/
			public override function place():void {

			   // Place in position
			   var coords:Point = fScene.translateCoords(this.element.x,this.element.y,this.element.z)
			   this.container.x = coords.x
			   this.container.y = coords.y
			   
			}
			
			/**
			* Listens to an object changing rotation and updates all sprites
			*/
			private function rotationListener(evt:Event):void {
				
				var el:fObject = this.element as fObject
				var correctedAngle:Number = el._orientation/360
				var newSprite:Number = Math.floor(correctedAngle*el.sprites.length)
				
				if(this.currentSpriteIndex!=newSprite) {
					
					// Update display model
					try {
						var lastFrame:Number = this.currentSprite.currentFrame
						this.baseObj.removeChild(this.currentSprite)
					} catch(e:Error) {
						lastFrame = 1
					}
					var clase:Class = el.sprites[newSprite].sprite as Class
					this.currentSprite = new clase() as MovieClip
					this.baseObj.addChild(this.currentSprite)
					this.currentSprite.mouseEnabled = false
					this.currentSprite.gotoAndPlay(lastFrame)
					this.flashClip = this.element.flashClip = this.currentSprite
					
					// Update shadow model
			    if(!this.simpleShadows) {

							var l:Number = this.allShadows.length
				  		var shadowClase:Class = el.sprites[newSprite].shadow as Class
							for(var i:Number=0;i<l;i++) {
								
							  var info:fObjectShadow = this.allShadows[i]
								var n:MovieClip = new shadowClase() as MovieClip
								info.shadow.removeChild(info.clip)
								info.shadow.addChild(n)
								info.clip = n
								n.gotoAndPlay(lastFrame)
								
							}
					
					}
					
					this.currentSpriteIndex = newSprite
				
					if(this.eraseShadows) {
					
							// Update shadows
							l = this.allShadows.length
							for(i=0;i<l;i++) {
								if(this.allShadows[i].clip.stage) {
									
									var p:fRenderableElement = this.allShadows[i].request
							 		if(p is fPlane) {
							 			try { p.customData.flash9Renderer.undoCache(true) } catch(e:Error) {trace(e)}
							 		}				
							 	}
							}
				  }
				
				}
				
			}

			/** 
			* When a character moves, the cache needs to be reset
			*/
			private function moveListener(evt:Event):void {
				
				 	// Delete projection cache
			 	 	this.projectionCache = new fObjectProjectionCache
					
			}


			/** 
			* This method syncs shadows to the base movieClip
			*/
			private function gotoAndStopListener(evt:Event):void {
				
			    // No animated shadows in this mode
			    if(this.simpleShadows) return

					var l:Number = this.allShadows.length
					for(var i:Number=0;i<l;i++) this.allShadows[i].clip.gotoAndStop(this.flashClip.currentFrame)
					
			}

			/** 
			* This method syncs shadows to the base movieClip
			*/
			private function gotoAndPlayListener(evt:Event):void {
				
			    // No animated shadows in this mode
			    if(this.simpleShadows) return

					var l:Number = this.allShadows.length
					for(var i:Number=0;i<l;i++) this.allShadows[i].clip.gotoAndPlay(this.flashClip.currentFrame)
					
			}


			/** 
			* This method will redraw this object's shadows when it is shown
			*/
			private function showListener(evt:Event):void {
				 var l:Number = this.allShadows.length
				 for(var i:Number=0;i<l;i++) {
				 	this.allShadows[i].clip.visible = true
					if(this.eraseShadows && this.allShadows[i].clip.stage) {
						var p:fRenderableElement = this.allShadows[i].request
				 		if(p is fPlane) {
				 			try { p.customData.flash9Renderer.undoCache(true) } catch(e:Error) {trace(e)}
				 		}				
				 	}
				 }
			}
			
			/** 
			* This method will erase this object's shadows when it is hidden
			*/
			private function hideListener(evt:Event):void {
				 var l:Number = this.allShadows.length
				 for(var i:Number=0;i<l;i++) {
				 	this.allShadows[i].clip.visible = false
					if(this.eraseShadows && this.allShadows[i].clip.stage) {
						var p:fRenderableElement = this.allShadows[i].request
				 		if(p is fPlane) {
				 			try { p.customData.flash9Renderer.undoCache(true) } catch(e:Error) {trace(e)}
				 		}				
				 	}
				 }
			}

			/*
			* Returns a Shadow representation of this object, so
			* the other elements can draw this shadow on themselves 
			*
			* @param request The renderableElement requesting the shadow
			*
			* @return A movieClip instance ready to attach to the element that has to show the shadow of this object
			*/
			public function getShadow(request:fRenderableElement):fObjectShadow {
				
				 var shadow:Sprite = new Sprite()
				 var par:Sprite = new Sprite()
				 var clip:MovieClip
				 par.addChild(shadow)
				 var el:fObject = this.element as fObject

				 // Return either the proper shadow or a simple spot depending on quality settings
				 if(!this.simpleShadows) {
				 		
				 		var clase:Class = el.sprites[this.currentSpriteIndex].shadow as Class
				 		clip = new clase() as MovieClip
				 		clip.gotoAndPlay(this.currentSprite.currentFrame)
				 		
				 } else {
				 	  clip = new MovieClip()
				 		movieClipUtils.circle(clip.graphics,0,0,1.5*el.radius,20,0x000000,100-this.glight.intensity)
				 }
		 		 
		 		 shadow.addChild(clip)
		 		 
		 		 var ret:fObjectShadow = new fObjectShadow(shadow,clip,request)
				 this.allShadows.push(ret)
				 return ret

			}

			/*
			* Deletes a shadow representation. It is called when this shadow is no longer needed
			*
			* @param sh The shadow we return
			*
			*/
			public function returnShadow(sh:fObjectShadow):void {
				
				 var pos:Number = this.allShadows.indexOf(sh)
				 this.allShadows.splice(pos,1)
				 sh.dispose()

			}


			/** 
			* Resets shadows. This is called when the fEngine.shadowQuality value is changed
			*/
			public override function resetShadows():void {

				 this.simpleShadows = false
				 if(fEngine.shadowQuality==fShadowQuality.BASIC || (this.element is fCharacter && fEngine.shadowQuality==fShadowQuality.NORMAL)) this.simpleShadows = true
				 
				 this.eraseShadows = false
				 if(fEngine.shadowQuality==fShadowQuality.BEST || (!(this.element is fCharacter) && fEngine.shadowQuality==fShadowQuality.GOOD)) this.eraseShadows = true
				 
				 if(this.allShadows) for(var i:Number=0;i<this.allShadows.length;i++) {
				 	this.allShadows[i].dispose()
				 	delete this.allShadows[i]
				 }
				 this.allShadows = new Array

			}
		
			/*
			* Calculates the projection of this object to a given floor Z
			*/
			public function getSpriteProjection(floorz:Number,x:Number,y:Number,z:Number):fObjectProjection {
				
				 // Test cache
				 if(this.projectionCache.test(floorz,x,y,z)) {
				 		
				 		//trace("Read cache")
				 		
				 } else {

				 		//trace("Write cache")
				 		if(this.element.z>floorz && z<this.element.z) {
				 			
				 			// No projection
				 			this.projectionCache.update(floorz,x,y,z,null)
				 			return this.projectionCache.projection
				 			
				 		}
				 
				 		// Create new value 
				 		var ret = new fObjectProjection()
				 		ret.polygon = fProjectionSolver.calculateProjection(x,y,z,this.element,floorz)
				 		ret.origin = new Point((ret.polygon[0].x+ret.polygon[1].x)/2,(ret.polygon[0].y+ret.polygon[1].y)/2)
				 		ret.end = new Point((ret.polygon[2].x+ret.polygon[3].x)/2,(ret.polygon[2].y+ret.polygon[3].y)/2)
				 		ret.size = Point.distance(ret.origin,ret.end)
				 		this.projectionCache.update(floorz,x,y,z,ret)
	
				 }
				 
		 		 return this.projectionCache.projection
				
			}

			/**
			* Redraws lights in this Object
			*/
			private function paintLights():void {
				
				 var res:ColorTransform = new ColorTransform

				 res.concat(this.glight.color)
				 
				 for(var i:String in this.lights) {
				 	  
				 	  if(this.lights[i].light.scene!=null) {
				 	  	var n:ColorTransform = this.lights[i].getTransform()
				 			res.redMultiplier += n.redMultiplier
				 			res.blueMultiplier += n.blueMultiplier
				 			res.greenMultiplier += n.greenMultiplier
				 			res.redOffset += n.redOffset
				 			res.blueOffset += n.blueOffset
				 			res.greenOffset += n.greenOffset
				 		}
				 }
				 
				 // Clamp
		 		 res.redMultiplier = Math.min(1,res.redMultiplier)
		 		 res.blueMultiplier = Math.min(1,res.blueMultiplier)
	 		   res.greenMultiplier = Math.min(1,res.greenMultiplier)
		 		 res.redOffset = Math.min(128,res.redOffset)
		 		 res.blueOffset = Math.min(128,res.blueOffset)
	 		   res.greenOffset = Math.min(128,res.greenOffset)
				 
				 this.baseObj.transform.colorTransform = res
			}

			/** 
			* Sets global light
			*/
			public override function renderGlobalLight(light:fGlobalLight):void {
				 this.glight = light
				 this.paintLights()
			}

			/** 
			* Global light changes intensity
			*/
			public override function processGlobalIntensityChange(light:fGlobalLight):void {
				 this.paintLights()
			}

			/**
			* Global light changes color
			*/
			public override function processGlobalColorChange(light:fGlobalLight):void {
				 this.paintLights()
			}
			
			/** 
			*	Light reaches element
			*/
			public override function lightIn(light:fLight):void {
					
				 // Already there ?
			   if(this.lights && !this.lights[light.uniqueId]) {
			   	this.lights[light.uniqueId] = new fLightWeight(this.element as fObject,light)
			   	light.addEventListener(fLight.COLORCHANGE,this.processLightIntensityChange,false,0,true)
					light.addEventListener(fLight.INTENSITYCHANGE,this.processLightIntensityChange,false,0,true)
			   }
				
			}
			
			/** 
			*	Light leaves element
			*/
			public override function lightOut(light:fLight):void {
			
				 if(this.lights && this.lights[light.uniqueId]) {
				 	delete this.lights[light.uniqueId]
				 	this.paintLights()
			   	light.removeEventListener(fLight.COLORCHANGE,this.processLightIntensityChange)
					light.removeEventListener(fLight.INTENSITYCHANGE,this.processLightIntensityChange)
				 }
			
			}
			
			private function processLightIntensityChange(e:Event) {
				trace("1")
				this.paintLights()
			}
			
			
			/**
			* Render start
			 */
			public override function renderStart(light:fLight):void {
			
				 // Already there ?	
			   if(!this.lights[light.uniqueId]) this.lights[light.uniqueId] = new fLightWeight(this.element as fObject,light)

			}
			
			/**
			* Render ( draw ) light
			*/
			public override function renderLight(light:fLight):void {
			
		     this.lights[light.uniqueId].updateWeight()
			
			}
			
			/**
			* Renders shadows of other elements upon this element
			*/
			public override function renderShadow(light:fLight,other:fRenderableElement):void {
			   
			
			}

			/**
			* Ends render
			*/
			public override function renderFinish(light:fLight):void {
					this.paintLights()
			}
			
			/**
			* Starts acclusion related to one character
			*/
			public override function startOcclusion(character:fCharacter):void {
					this.occlusionCount++
					this.container.alpha = character.occlusion/100
			}

			/**
			* Updates acclusion related to one character
			*/
			public override function updateOcclusion(character:fCharacter):void {
			}

			/**
			* Stops acclusion related to one character
			*/
			public override function stopOcclusion(character:fCharacter):void {
					this.occlusionCount--
					if(this.occlusionCount==0) this.container.alpha = 1
			}

			/** @private */
			public function disposeObjectRenderer():void {

				// Lights
				for(var i:Number=0;i<this.lights.length;i++) delete this.lights[i]
				this.lights = null
				this.glight = null
				this.currentSprite = null
				if(this.projectionCache) this.projectionCache.dispose()
				this.projectionCache = null
				this.resetShadows()

			 	// Events
			 	this.element.removeEventListener(fRenderableElement.SHOW,this.showListener)
			 	this.element.removeEventListener(fRenderableElement.HIDE,this.hideListener)
			 	this.element.removeEventListener(fObject.NEWORIENTATION,this.rotationListener)
			 	this.element.removeEventListener(fObject.GOTOANDPLAY,this.gotoAndPlayListener)
			 	this.element.removeEventListener(fObject.GOTOANDSTOP,this.gotoAndStopListener)
			 	if(this.element is fCharacter) this.element.removeEventListener(fElement.MOVE,this.moveListener)
				
    		// Gfx
    		fFlash9RenderEngine.recursiveDelete(this.baseObj)
    		this.baseObj = null

				this.disposeRenderer()


			}

			/** @private */
			public override function dispose():void {
				this.disposeObjectRenderer()
			}		



		}
		
		
}