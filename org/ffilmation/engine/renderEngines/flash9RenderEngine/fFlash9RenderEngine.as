package org.ffilmation.engine.renderEngines.flash9RenderEngine {
	
		// Imports
		import flash.events.*
		import flash.geom.*
		import flash.display.*

		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers.*

		/**
		* This is ffilmation's default flash9 isometric renderer
		* @private
		*/
		public class fFlash9RenderEngine implements fEngineRenderEngine {
		
				// Private properties
				
				/** The scene rendered by this renderer */
				private var scene:fScene
				
				/** The Sprite where this scene will be drawn  */
				private var container:Sprite

				/** An array of all elementRenderers in this scene. An elementRenderer is a class that renders an specific element, for example a wallRenderer is associated to a fWall	*/
				private var renderers:Array
				
		  	/** Viewport width */
		  	private var viewWidth:Number = 0

		  	/** Viewport height */
		  	private var viewHeight:Number = 0

				
				/**
				* Class constructor
				*/
				public function fFlash9RenderEngine(scene:fScene,container:Sprite):void {
						
					// Init items
					this.scene = scene
					this.container = container
					this.renderers = new Array
					
				}
				
				/**
				* This method is called when the scene is to be displayed.
				*/
				public function initialize():void {
		  	 	 
					this.scene.environmentLight.addEventListener(fLight.COLORCHANGE,this.processGlobalColorChange,false,0,true)
					this.scene.environmentLight.addEventListener(fLight.INTENSITYCHANGE,this.processGlobalIntensityChange,false,0,true)
					this.scene.environmentLight.addEventListener(fLight.RENDER,this.processGlobalIntensityChange,false,0,true)

				}

				/**
				* This method initializes the render engine for an element in the scene.
				*/
				public function initRenderFor(element:fRenderableElement):MovieClip {
					
					var renderer:fFlash9ElementRenderer = this.createRendererFor(element)
					element.customData.flash9Renderer.renderGlobalLight(this.scene.environmentLight)
					return element.customData.flash9Renderer.container
		  	 	 
				}

				/**
				* This method removes an element from the render engine
				*/
				public function stopRenderFor(element:fRenderableElement):void {
					
		  	 	// Delete renderer
		  	 	this.renderers[element.uniqueId].dispose() 
		  	 	delete this.renderers[element.uniqueId]
		  	 	element.customData.flash9Renderer = null
		  	 	
		  	 	// Free graphics
		  	 	this.recursiveDelete(element.container)
		  	 	
				}

				/**
				* This method returns the asset from the library that was used to display the element.
				* It gets written as the "flashClip" property of the element.
				*/
				public function getAssetFor(element:fRenderableElement):MovieClip {
					return element.customData.flash9Renderer.flashClip
				}

				/**
				* This method updates the position of a character's sprite
				*/
				public function updateCharacterPosition(char:fCharacter):void {
					char.customData.flash9Renderer.place()
				}

				/**
				* This method updates the position of a bullet's sprite
				*/
				public function updateBulletPosition(bullet:fBullet):void {
					bullet.customData.flash9Renderer.place()
				}

			  /**
			  * This method renders an element visible
			  **/
			  public function showElement(element:fRenderableElement):void {
					element.customData.flash9Renderer.show()
			  }

			  /**
			  * This method renders an element invisible
			  **/
			  public function hideElement(element:fRenderableElement):void {
					element.customData.flash9Renderer.hide()
			  }

			  /**
			  * This method enables mouse events for an element
			  **/
			  public function enableElement(element:fRenderableElement):void {
					element.customData.flash9Renderer.enableMouseEvents()
			  }

			  /**
			  * This method disables mouse events for an element
			  **/
			  public function disableElement(element:fRenderableElement):void {
					element.customData.flash9Renderer.disableMouseEvents()
			  }

				/**
				* When a moving light reaches an element, this method is executed
				*/
				public function lightIn(element:fRenderableElement,light:fOmniLight):void {
					element.customData.flash9Renderer.lightIn(light)
				}

				/**
				* When a moving light moves out of an element, this method is executed
				*/
				public function lightOut(element:fRenderableElement,light:fOmniLight):void {
					element.customData.flash9Renderer.lightOut(light)
				}

				/**
				* When a light is to be reset ( new size )
				*/
				public function lightReset(element:fRenderableElement,light:fOmniLight):void {
					element.customData.flash9Renderer.lightReset(light)
				}


				/**
				* This is the renderStart call.
				*/
				public function renderStart(element:fRenderableElement,light:fOmniLight):void {
					element.customData.flash9Renderer.renderStart(light)
				}
				
				/**
				* This is the renderLight call.
				*/
				public function renderLight(element:fRenderableElement,light:fOmniLight):void {
					element.customData.flash9Renderer.renderLight(light)
				}

				/**
				* This is the renderShadow call.
				*/
				public function renderShadow(element:fRenderableElement,light:fOmniLight,shadow:fRenderableElement):void {
					element.customData.flash9Renderer.renderShadow(light,shadow)
				}

				/**
				* This is the renderFinish call.
				*/
				public function renderFinish(element:fRenderableElement,light:fOmniLight):void {
					element.customData.flash9Renderer.renderFinish(light)
				}
		
				/**
				* This is the updateShadow call.
				*/
				public function updateShadow(element:fRenderableElement,light:fOmniLight,shadow:fRenderableElement):void {
					element.customData.flash9Renderer.updateShadow(light,shadow)
				}

				/**
				* When an element is removed or hidden, or moves out of another element's range, its shadows need to be removed too
				*/
				public function removeShadow(element:fRenderableElement,light:fOmniLight,shadow:fRenderableElement):void {
					element.customData.flash9Renderer.removeShadow(light,shadow)
				}

				/**
				* When the quality settings for the engine's shadows are changed, this method is called so old shadows are removed.
				* There is no need for the renderer to redraw all shadows in this method: The engine rerenders the whole scene after
				* this has been executed.
				*/
				public function resetShadows():void {
					for(var i in this.renderers) this.renderers[i].resetShadows()
				}

				/**
				* Updates the render to show a given camera's position
				*/
				public function setCameraPosition(camera:fCamera):void {

					var p:Point = fScene.translateCoords(camera.x,camera.y,camera.z)
					var rect:Rectangle = new Rectangle()
					rect.width = this.viewWidth
					rect.height = this.viewHeight
					rect.x = -this.viewWidth/2+p.x
					rect.y = -this.viewHeight/2+p.y
					this.container.scrollRect = rect

				}
				
				/**
				* Updates the viewport size. This call will be immediately followed by a setCameraPosition call
				* @see org.ffilmation.engine.interfaces.fRenderEngine#setCameraPosition
				*/
				public function setViewportSize(width:Number,height:Number):void {
					
					this.viewWidth = width
					this.viewHeight = height
				}

				/**
				* Starts acclusion related to one character
				* @param element Element where occlusion is applied
				* @param character Character causing the occlusion
				*/
				public function startOcclusion(element:fRenderableElement,character:fCharacter):void {
					element.customData.flash9Renderer.startOcclusion(character)
				}
				
				/**
				* Updates acclusion related to one character
				* @param element Element where occlusion is applied
				* @param character Character causing the occlusion
				*/
				public function updateOcclusion(element:fRenderableElement,character:fCharacter):void {
					element.customData.flash9Renderer.updateOcclusion(character)
				}
      	
				/**
				* Stops acclusion related to one character
				* @param element Element where occlusion is applied
				* @param character Character causing the occlusion
				*/
				public function stopOcclusion(element:fRenderableElement,character:fCharacter):void {
					element.customData.flash9Renderer.stopOcclusion(character)
				}

				/**
				* This method returns the element under a Stage coordinate, and a 3D translation of the 2D coordinates passed as input.
				*/
				public function translateStageCoordsToElements(x:Number,y:Number):Array {
					
					var objects:Array = this.container.getObjectsUnderPoint(new Point(x,y))
					if(objects.length==0) return null
					
					var ret:Array = new Array
					var found:Array = new Array
					
					for(var i:Number=0;i<objects.length;i++) {
						
							var obj:DisplayObject = objects[i]
							
							// Search for element containing this DisplayObject
							var el:fRenderableElement = null
							while(el==null && obj!=this.container && obj!=null) {
								if(obj is MovieClip) {
									 var m:MovieClip = obj as MovieClip
									 if(m.fElement) el = m.fElement
								}
								obj = obj.parent
							}
							
							if(el!=null && found.indexOf(el)<0 /*&& this.currentOccluding.indexOf(el)<0*/) {
							
									// Avoid repeated results
									found.push(el)
        	
									// Get local coordinate
									var p:Point = new Point(x,y)
									if(el is fPlane) {
										var r:fFlash9PlaneRenderer = (el.customData.flash9Renderer as fFlash9PlaneRenderer)
										if(r.baseContainer.stage)	p = r.baseContainer.globalToLocal(p)
										else p = r.finalBitmap.globalToLocal(p)
									}
									else p = el.container.globalToLocal(p)
									
									// Push data
									if(el is fFloor) ret.push(new fCoordinateOccupant(el,el.x+p.x,el.y+p.y,el.z))
									if(el is fWall) {
										var w:fWall = el as fWall
										if(w.vertical) ret.push(new fCoordinateOccupant(w,w.x,w.y0+p.x,w.z+w.pixelHeight-p.y))
										else ret.push(new fCoordinateOccupant(w,w.x0+p.x,w.y,w.z+w.pixelHeight-p.y))
									}
									if(el is fObject) ret.push(new fCoordinateOccupant(el,el.x+p.x,el.y,el.z-p.y))
							}
							
					}
					
					// Elements in front go first in the Array
					ret.reverse()
					
					if(ret.length==0) return null
					else return ret

				}

				/** 
				* Frees all allocated resources. This is called when the scene is hidden or destroyed.
				*/
				public function dispose():void {
					
					// Stop listeners
					this.scene.environmentLight.removeEventListener(fLight.COLORCHANGE,this.processGlobalColorChange)
					this.scene.environmentLight.removeEventListener(fLight.INTENSITYCHANGE,this.processGlobalIntensityChange)
					this.scene.environmentLight.removeEventListener(fLight.RENDER,this.processGlobalIntensityChange)
					
					// Delete resources
					for(var i in this.renderers) this.renderers[i].dispose()
					this.renderers = new Array
					this.recursiveDelete(this.container)
				}
				
				
				// INTERNAL
				
				/**
				* This method retrieves the projected Sprite corresponding to a given element and floor size
				* @private
				*/
				public function getObjectSpriteProjection(element:fObject,floorz:Number,x:Number,y:Number,z:Number):fObjectProjection {
					return element.customData.flash9Renderer.getSpriteProjection(floorz,x,y,z)
				}

				/**
				* This method retrieves the Sprite representing the shadow of a given fObject
				* @private
				*/
				public function getObjectShadow(element:fObject,request:fRenderableElement):fObjectShadow {
					return element.customData.flash9Renderer.getShadow(request)
				}
				
				/**
				* This method returns an unused shadow to the pool
				* @private
				*/
				public function returnObjectShadow(element:fObject,sh:fObjectShadow):void {
					element.customData.flash9Renderer.returnShadow(sh)
				}


				/**
				* This event listener is executed when the global light changes its intensity
				*/
				private function processGlobalIntensityChange(evt:Event):void {
					for(var i in this.renderers) this.renderers[i].processGlobalIntensityChange(evt.target as fGlobalLight)
				}
		
				/**
				* This event listener is executed when the global light changes its color
				*/
				private function processGlobalColorChange(evt:Event):void {
					for(var i in this.renderers) this.renderers[i].processGlobalColorChange(evt.target as fGlobalLight)
				}

				/**
				* Creates the renderer associated to a renderableElement. The renderer is created if it doesn't exist.
				*/
				private function createRendererFor(element:fRenderableElement):fFlash9ElementRenderer {
					
					//Create renderer if it doesn't exist
					if(!this.renderers[element.uniqueId]) {
				 		
				 		var spr:MovieClip = new MovieClip()
		   	 		this.container.addChild(spr)			   

						if(element is fFloor) element.customData.flash9Renderer = new fFlash9FloorRenderer(this,spr,element as fFloor)
						if(element is fWall) element.customData.flash9Renderer = new fFlash9WallRenderer(this,spr,element as fWall)
						if(element is fObject) element.customData.flash9Renderer = new fFlash9ObjectRenderer(this,spr,element as fObject)
						if(element is fBullet) element.customData.flash9Renderer = new fFlash9BulletRenderer(this,spr,element as fBullet)
						
						this.renderers[element.uniqueId] = element.customData.flash9Renderer
						
					}
					
					// Return it
					return this.renderers[element.uniqueId]
					
				}

				// Recursively deletes all DisplayObjects in the container hierarchy
				private function recursiveDelete(d:DisplayObjectContainer):void {
						
						if(d.numChildren!=0) do {
							var c:DisplayObject = d.getChildAt(0)
							if(c!=null) {
								c.cacheAsBitmap = false
								if(c is DisplayObjectContainer) this.recursiveDelete(c as DisplayObjectContainer)
								if(c is MovieClip) c.stop()
								if(c is Bitmap) (c as Bitmap).bitmapData.dispose()
								if(c is Shape) (c as Shape).graphics.clear()
								d.removeChild(c)
							}
						} while(d.numChildren!=0 && c!=null)
					
				}				


		}
		
}
