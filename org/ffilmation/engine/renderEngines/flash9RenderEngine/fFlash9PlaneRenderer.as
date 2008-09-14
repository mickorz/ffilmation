package org.ffilmation.engine.renderEngines.flash9RenderEngine {
	
		// Imports
	  import flash.display.*
	  import flash.events.*	
		import flash.geom.*
		import flash.utils.*
		import flash.filters.DisplacementMapFilter
		import flash.filters.DisplacementMapFilterMode

		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.helpers.*
	  
		/**
		* This class renders fPlanes
		* @private
		*/
		public class fFlash9PlaneRenderer extends fFlash9ElementRenderer {
		
			// Private properties
			private var origWidth:Number
			private var origHeight:Number
			private var	cacheTimer:Timer

			protected var lightC:Sprite								 // All lights
			private var environmentC:Shape				     // Global
			private var black:Shape				  				   // No light
			private var diffuse:DisplayObject					 // Diffuse map
			private var holesC:Sprite				    			 // Holes
			private var simpleHolesC:Sprite				    

			private var spriteToDraw:Sprite
			public var baseContainer:DisplayObjectContainer
			private var behind:DisplayObjectContainer  // Elements behind the wall will added here
			private var infront:DisplayObjectContainer // Elements in front of the wall will added here
			
			private var bumpMap:BumpMap								 // Bump maps
			private var bumpMapData:BitmapData
			private var displacer:DisplacementMapFilter
			private var tMatrix:Matrix
			private var tMatrixB:Matrix
			private var firstBump:Boolean = true
			
			// Internal
			public var deformedSimpleShadowsLayer:Sprite
			public var simpleShadowsLayer:Sprite		   // Simple shadows go here
			public var lightClips:Object               // List of containers used to represent lights (interior)
			public var lightMasks:Object               // List of containers representing the light mask / shape
			public var lightShadows:Object             // Container where geometry shadows are drawn
			public var lightBumps:Object           	   // Bump map layers
			public var zIndex:Number = 0						   // zIndex
			public var scrollR:Rectangle							 // Scrollrectangle for this plane, to optimize viewing areas. It is written by fFloorRenderer and fWallRenderer
			public var planeDeform:Matrix						   // Transformation matrix for this plane that sets the proper perspective
			public var lightStatuses:Object      			 // References to light status
			
			// Occlusion related
			private var occlusionCount:Number = 0
			private var occlusionLayer:Sprite
			private var occlusionSpots:Object

			// Constructor
			function fFlash9PlaneRenderer(rEngine:fFlash9RenderEngine,element:fPlane,width:Number,height:Number,spriteToDraw:Sprite,spriteToShowHide:MovieClip):void {
				
 			   // Retrieve diffuse map
 			   this.diffuse = element.material.getDiffuse()
 			   var d:Sprite = this.diffuse as Sprite
 			   d.mouseEnabled = false
 			   d.mouseChildren = false

				 // Previous
				 super(rEngine,element,this.diffuse,spriteToShowHide)

				 // Properties
			   this.origWidth = diffuse.width
			   this.origHeight = diffuse.height
			   this.spriteToDraw = spriteToDraw

				 // This is the Sprite where all light layers are generated. This is the Sprite being deformed
				 // This Sprite is attached to the sprite that is visible onscreen
				 this.baseContainer = new Sprite()
				 this.behind = new Sprite()
				 this.infront = new Sprite()
			   this.baseContainer.addChild(this.behind)
			   this.baseContainer.addChild(this.diffuse)
			   this.baseContainer.addChild(this.infront)
			   this.spriteToDraw.addChild(this.baseContainer)
			   this.baseContainer.transform.matrix = this.planeDeform

			   // LIGHT
			   this.lightClips = new Object  
			   this.lightStatuses = new Object   		
			   this.lightMasks = new Object   		
			   this.lightShadows = new Object   		
			   this.lightBumps = new Object   		
			   this.lightC = new Sprite()
			   this.holesC = new Sprite()
			   this.simpleHolesC = new Sprite()
				 this.black = new Shape()
			   this.environmentC = new Shape()
 			   this.lightC.mouseEnabled = false
 			   this.lightC.mouseChildren = false

			   this.baseContainer.addChild(this.lightC)
			   this.lightC.addChild(this.black)
			   this.lightC.addChild(this.environmentC)
			   this.lightC.blendMode = BlendMode.MULTIPLY
 			   this.lightC.mouseEnabled = false
 			   this.lightC.mouseChildren = false
				 this.baseContainer.mouseEnabled = false

				 // Object shadows with qualities other than fShadowQuality.BEST will be drawn here instead of into each lights's ERASE layer
				 this.deformedSimpleShadowsLayer = new Sprite
				 this.deformedSimpleShadowsLayer.mouseEnabled = false
				 this.deformedSimpleShadowsLayer.mouseChildren = false
				 this.deformedSimpleShadowsLayer.transform.matrix = this.planeDeform
				 this.simpleShadowsLayer = new Sprite
				 this.simpleShadowsLayer.scrollRect = this.scrollR
				 this.spriteToDraw.addChild(this.deformedSimpleShadowsLayer)
				 this.deformedSimpleShadowsLayer.addChild(this.simpleShadowsLayer)

			   // Holes
			   for(var i:Number=0;i<element.holes.length;i++) {
   					 element.holes[i].addEventListener(fHole.OPEN,this.openHole,false,0,true)
				 		 element.holes[i].addEventListener(fHole.CLOSE,this.closeHole,false,0,true)
				 		 if(!element.holes[i].open && element.holes[i].block) this.behind.addChild(element.holes[i].block)				 		 	
			   }
				 this.redrawHoles()
				 
			   if(element.holes.length>0) {
			   		this.deformedSimpleShadowsLayer.addChild(this.simpleHolesC)
			   		this.deformedSimpleShadowsLayer.blendMode = BlendMode.LAYER
			   		this.simpleHolesC.blendMode = BlendMode.ERASE
				 		this.simpleHolesC.mouseEnabled = false
				 		
			   		this.baseContainer.addChild(this.holesC)
			   		this.holesC.blendMode = BlendMode.ERASE
				 		this.holesC.mouseEnabled = false
				 }
				 
				 // Occlusion
				 this.occlusionLayer = new Sprite
				 this.occlusionLayer.mouseEnabled = false
			   this.occlusionLayer.blendMode = BlendMode.ERASE
				 this.occlusionLayer.scrollRect = this.scrollR
				 this.occlusionSpots = new Object

			   // Cache as Bitmap with Timer cache
			   // The cache is disabled while the Plane is being modified and a timer is set to re-enable it
			   // if the plane doesn't change in a while
			   this.baseContainer.cacheAsBitmap = true
				 this.cacheTimer = new Timer(100,1)
         this.cacheTimer.addEventListener(TimerEvent.TIMER, cacheTimerListener,false,0,true)

			}

			/**
			* This method listens to holes beign opened
			*/
			private function openHole(event:Event):void {
				
				try {
					var hole:fHole = event.target as fHole
					if(hole.block) {
						this.behind.removeChild(hole.block)
						if(this.scene.IAmBeingRendered) this.redrawLights()
					}
				} catch(e:Error) {
					
				}

			}

			/**
			* This method listens to holes beign closed
			*/
			private function closeHole(event:Event):void {
				
				try {
					var hole:fHole = event.target as fHole
					if(hole.block) {
						this.behind.addChild(hole.block)
						if(this.scene.IAmBeingRendered) this.redrawLights()
					}
				} catch(e:Error) {
					
				}

			}

			/**
			* Redraws all lights when a hole has been opened/closed
			*/
			private function redrawLights():void {
				  
					this.redrawHoles()
					for(var i:Number=0;i<this.element.scene.lights.length;i++) {
						var l:fLight = this.element.scene.lights[i]
						if(l) l.render()
					}
			}

			/**
			* Mouse management
			*/
			public override function disableMouseEvents():void {
				this.container.mouseEnabled = false
				this.spriteToDraw.mouseEnabled = false
			}

			/**
			* Mouse management
			*/
			public override function enableMouseEvents():void {
				this.container.mouseEnabled = true
				this.spriteToDraw.mouseEnabled = true
			}

			/** 
			* Resets shadows. This is called when the fEngine.shadowQuality value is changed
			*/
			public override function resetShadows():void {
				 this.simpleShadowsLayer.graphics.clear()
				 this.resetShadowsInt()
			}
			public function resetShadowsInt():void {
			}

			/**
			* Creates bumpmapping for this plane
			*/
			public function iniBump():void {

			   // Bump map ?
	       try {

				 		var ptt:DisplayObject = (this.element as fPlane).material.getBump()
						
						this.bumpMapData = new BitmapData(this.container.width,this.container.height)
						this.tMatrix = this.container.transform.matrix.clone()
//						this.tMatrix.concat(this.spriteToDraw.transform.matrix)
						this.tMatrixB = this.tMatrix.clone()
				 		var bnds = this.container.getBounds(this.container.parent)
						this.tMatrix.ty = Math.round(-bnds.top)
						this.bumpMapData.draw(ptt,this.tMatrix)
						
				 		this.bumpMap = new BumpMap(this.bumpMapData)
				 		this.displacer = new DisplacementMapFilter();
				 		this.displacer.componentX = BumpMap.COMPONENT_X;
				 		this.displacer.componentY = BumpMap.COMPONENT_Y;
				 		this.displacer.mode =	DisplacementMapFilterMode.COLOR
				 		this.displacer.alpha =	0
				 		this.displacer.scaleX = -180;
				 		this.displacer.scaleY = -180;
				 		
//				 		var r:Bitmap = new Bitmap(this.bumpMap.outputData)
//				 		var r:Bitmap = new Bitmap(this.bumpMapData)
//				 		this.container.parent.addChild(r)

				 } catch (e:Error) {
				 		this.bumpMapData = null
				 		this.bumpMap = null
				 		this.displacer = null

				 }
			}

			/** 
			* Sets global light
			*/
			public override function renderGlobalLight(light:fGlobalLight):void {
				
				 this.black.graphics.clear()
				 this.black.graphics.beginFill(0x000000,1)
		 	   this.black.graphics.moveTo(0,0)
			 	 this.black.graphics.lineTo(0,this.origHeight)
			 	 this.black.graphics.lineTo(this.origWidth,this.origHeight)
			 	 this.black.graphics.lineTo(this.origWidth,0)
			 	 this.black.graphics.lineTo(0,0)

				 this.black.graphics.endFill()
	       this.setDimensions(this.black)
	       
				 // Draw environment light
				 this.environmentC.graphics.clear()
				 this.environmentC.graphics.beginFill(light.hexcolor,1)
		 	   this.environmentC.graphics.moveTo(0,0)
			 	 this.environmentC.graphics.lineTo(0,this.origHeight)
			 	 this.environmentC.graphics.lineTo(this.origWidth,this.origHeight)
			 	 this.environmentC.graphics.lineTo(this.origWidth,0)
			 	 this.environmentC.graphics.lineTo(0,0)

				 this.environmentC.graphics.endFill()
	       this.setDimensions(this.environmentC)

				 this.environmentC.alpha = light.intensity/100
				 this.simpleShadowsLayer.alpha = 1-this.environmentC.alpha

			}

			/**
			* Draws holes into material
			*/
			private function redrawHoles():void {
				
				 // Erases holes from light layers
				 this.holesC.graphics.clear()
				 this.holesC.graphics.beginFill(0x000000,1)
		 	   this.holesC.graphics.moveTo(0,0)
			 	 this.holesC.graphics.lineTo(0,this.origHeight)
			 	 this.holesC.graphics.lineTo(this.origWidth,this.origHeight)
			 	 this.holesC.graphics.lineTo(this.origWidth,0)
			 	 this.holesC.graphics.lineTo(0,0)
 	  		 this.holesC.graphics.endFill()
			 	 this.setDimensions(this.holesC)

				 this.holesC.graphics.clear()
				 var holes:Array = (this.element as fPlane).holes
				 
 				 for(var h:Number=0;h<holes.length;h++) {

					 	if(holes[h].open) {
						 	var hole:fPlaneBounds = holes[h].bounds
							this.holesC.graphics.beginFill(0x000000,1)
				 	  	this.holesC.graphics.moveTo(hole.xrel,hole.yrel)
				 	  	this.holesC.graphics.lineTo(hole.xrel+hole.width,hole.yrel)
			 	  		this.holesC.graphics.lineTo(hole.xrel+hole.width,hole.yrel+hole.height)
			 	  		this.holesC.graphics.lineTo(hole.xrel,hole.yrel+hole.height)
			 	  		this.holesC.graphics.lineTo(hole.xrel,hole.yrel)
			 	  		this.holesC.graphics.endFill()
			 	  	}
	       }
				
				 // Erases holes from simple sahdows layers
				 this.simpleHolesC.graphics.clear()
				 this.simpleHolesC.graphics.beginFill(0x000000,1)
		 	   this.simpleHolesC.graphics.moveTo(0,0)
			 	 this.simpleHolesC.graphics.lineTo(0,this.origHeight)
			 	 this.simpleHolesC.graphics.lineTo(this.origWidth,this.origHeight)
			 	 this.simpleHolesC.graphics.lineTo(this.origWidth,0)
			 	 this.simpleHolesC.graphics.lineTo(0,0)
 	  		 this.simpleHolesC.graphics.endFill()
			 	 this.setDimensions(this.simpleHolesC)

				 this.simpleHolesC.graphics.clear()
 				 for(h=0;h<holes.length;h++) {

					 	if(holes[h].open) {
						 	hole = holes[h].bounds
							this.simpleHolesC.graphics.beginFill(0x000000,1)
				 	  	this.simpleHolesC.graphics.moveTo(hole.xrel,hole.yrel)
				 	  	this.simpleHolesC.graphics.lineTo(hole.xrel+hole.width,hole.yrel)
			 	  		this.simpleHolesC.graphics.lineTo(hole.xrel+hole.width,hole.yrel+hole.height)
			 	  		this.simpleHolesC.graphics.lineTo(hole.xrel,hole.yrel+hole.height)
			 	  		this.simpleHolesC.graphics.lineTo(hole.xrel,hole.yrel)
			 	  		this.simpleHolesC.graphics.endFill()
			 	  	}
	       }


			}			

			/** 
			* Listens for changes in global light intensity
			*/
			public function processGlobalIntensityChange(evt:Event):void {
				
				 	 var light:Object = evt.target
					 this.environmentC.alpha = light.intensity/100
					 this.simpleShadowsLayer.alpha = 1-this.environmentC.alpha
			}

			/**
			* Creates masks and containers for a new light, and updates lightStatus
			*/
			public function addOmniLight(lightStatus:fLightStatus):void {
			
			   var light:fLight = lightStatus.light
			   lightStatus.lightZ = -2000
			
			   // Create container
			   var light_c:Sprite = new Sprite()
			   this.lightClips[light.uniqueId] = light_c

				 // Create layer
				 var lay:Sprite = new Sprite()
				 light_c.addChild(lay)
				 lay.cacheAsBitmap = true
				 //lay.blendMode = BlendMode.LAYER
				 lay.scrollRect = this.scrollR
				 
				 this.lightBumps[light.uniqueId] = lay
				 light_c.blendMode = BlendMode.ADD
				 
				 // Create mask
				 var msk:Shape = new Shape()
				 lay.addChild(msk)
			   this.createLightClip(light,msk)
			   this.lightMasks[light.uniqueId] = msk
			   //msk.blendMode = BlendMode.NORMAL
				 
				 // Create shadow container
			   var shd:Sprite = new Sprite()
			   lay.addChild(shd)
			   this.lightShadows[light.uniqueId] = shd
			   shd.blendMode = BlendMode.ERASE

			
			}
			
			/**
			* Creates light geometry instance in a given container
			*/
			private function createLightClip(light:fLight,lClip:Shape):void {
			
	       lClip.graphics.clear()

			   // Masked light
			   if(light.size!=Infinity) {
			      movieClipUtils.circle(lClip.graphics,0,0,light.size,light.decay,light.hexcolor,light.intensity)
			   } else {
			  		movieClipUtils.box(lClip.graphics,0,0,10,light.hexcolor,light.intensity)
	       		this.setDimensions(lClip)
				 }
			
			}
			
			/**
			* Gives geometry container the proper dimensions
			*/
			public function setDimensions(lClip:DisplayObject):void {
		  }

			
			/**
			* Redraws light to be at a new distante of plane
			*/
			public function setLightDistance(light:fLight,distance:Number,deform:Number=1):void {
			
			   if(light.size!=Infinity) {
			
			      // Redraw inner masks
			      var lClip:Shape = this.lightMasks[light.uniqueId]
			      var perc:Number = Math.cos(Math.asin((distance)/light.size))*deform
			      
			      // Correct displacement map
						if(fEngine.bumpMapping && light.bump) {
							
							if(this.firstBump) {
			 			  	this.iniBump()
			 			  	this.firstBump = false
							}
							if(this.bumpMap!=null) perc*=0.70
							 
						}
			      
			      lClip.alpha = lClip.scaleX = lClip.scaleY = perc
			      
			
			   }
			}

			/** 
			* Sets light to be a a new position in the plane
			*/
			public function setLightCoordinates(light:fLight,lx:Number,ly:Number):void {

				if(light.size!=Infinity) {

					var lClip:Shape = this.lightMasks[light.uniqueId]
					lClip.x = lx
					lClip.y = ly
				
					if(fEngine.bumpMapping && light.bump) {
						
						if(this.firstBump) {
			 			   this.iniBump()
			 			   this.firstBump = false
						}
						
						if(this.bumpMap!=null) {
							var r = lClip.getBounds(lClip.stage)
							var lw:Number = Math.round(r.width/2)
							var lh:Number = Math.round(r.height/2)
							
							// Snap to pixels so bumpmap doesn't flicker
							var pos:Point = new Point(lx,ly)
							var f:Point = lClip.parent.localToGlobal(pos)
							f.x = Math.round(f.x)
							f.y = Math.round(f.y)
							pos = lClip.parent.globalToLocal(f)
							lClip.x = pos.x
							lClip.y = pos.y
            	
							// Apply bump map
							pos = this.tMatrixB.deltaTransformPoint(pos)
							var p:Point = new Point(lw-pos.x,lh-pos.y)
							p.x = p.x
							p.y = p.y-this.tMatrix.ty
							displacer.mapBitmap = this.bumpMap.outputData
							displacer.mapPoint = p
							lClip.filters = [displacer]
						} else {
							lClip.filters = null
					  }
					} else {
						
						lClip.filters = null
						
					}
					
				} else {
						
						// Global lights are not bumpmapped as of this release
						
						
				}

			}

			/**
			* Listens to changes of a light's intensity
			*/
			private function processLightIntensityChange(event:Event):void {
				  var light:fLight = event.target as fLight
   				var lClip:Shape = this.lightMasks[light.uniqueId]
					this.createLightClip(light,lClip)
			}

			/** 
			*	Light reaches element
			*/
			public override function lightIn(light:fLight):void {
			
			   // Show container
				 if(this.lightStatuses && this.lightStatuses[light.uniqueId]) this.showLight(light)
				 
				 // Listen to intensity changes
		 		 light.addEventListener(fLight.INTENSITYCHANGE,this.processLightIntensityChange,false,0,true)
			   
			}
			
			/** 
			*	Light leaves element
			*/
			public override function lightOut(light:fLight):void {
			
			   // Hide container
			   if(this.lightStatuses[light.uniqueId]) this.hideLight(light)

				 // Stop listening to intensity changes
		 		 light.removeEventListener(fLight.INTENSITYCHANGE,this.processLightIntensityChange)
			   
			}

			/** 
			*	Shows light
			*/
			private function showLight(light:fLight):void {
			
			   var lClip:Sprite = this.lightClips[light.uniqueId]
			   this.lightC.addChild(lClip)
				
			}
			
			/** 
			*	Hides light
			*/
			private function hideLight(light:fLight):void {
			
			   var lClip:Sprite = this.lightClips[light.uniqueId]
			   this.lightC.removeChild(lClip)
			
			}



			/**
			* Starts render process
			*/
			public override function renderStart(light:fLight):void {
			
			   // Create light ?
			   if(!this.lightStatuses[light.uniqueId]) this.lightStatuses[light.uniqueId] = new fLightStatus(this.element as fPlane,light)
			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
				
			   if(!lightStatus.created) {
			      lightStatus.created = true
			      this.addOmniLight(lightStatus)
			      this.lightIn(light)
			   }
			   
			   // Disable cache. Once the render is finished, a timeout is set that will
			   // restore cacheAsbitmap if the object doesn't change for a few seconds.
       	 this.cacheTimer.stop()
       	 this.baseContainer.cacheAsBitmap = false
       	 if((this.element as fPlane).holes.length!=0) this.baseContainer.blendMode = BlendMode.LAYER
       	 this.lightBumps[light.uniqueId].cacheAsBitmap = false

			   // Init shadows
 			   var msk:Sprite = this.lightShadows[light.uniqueId]
			   msk.graphics.clear()
			  
			   // More
			   this.processRenderStart(light)
			
			}
			public function processRenderStart(light:fLight):void {

			}

			/**
			* Updates shadow of another elements upon this fElement
			*/
			public override function updateShadow(light:fLight,other:fRenderableElement):void {
			   
			   try {
			    
			   	var msk:Sprite
			   	if(other is fObject && fEngine.shadowQuality!=fShadowQuality.BEST) {
			   		msk = this.simpleShadowsLayer
			   	}
			   	else {
			   		msk = this.lightShadows[light.uniqueId]
			    	// Disable cache. Once the render is finished, a timeout is set that will
			    	// restore cacheAsbitmap if the object doesn't change for a few seconds.
       	  	this.cacheTimer.stop()
       	 		this.baseContainer.cacheAsBitmap = false
          	
       	  	if((this.element as fPlane).holes.length!=0) this.baseContainer.blendMode = BlendMode.LAYER
       	  	this.lightBumps[light.uniqueId].cacheAsBitmap = false
			   	}
				 			
				 	// Render
				  this.renderShadowInt(light,other,msk)
				 } catch(e:Error) { }
				 
				 // Start cache timer
				 this.cacheTimer.start()
				 
			}

			/**
			* Renders shadows of other elements upon this fElement
			*/
			public override function renderShadow(light:fLight,other:fRenderableElement):void {
			   
			   var msk:Sprite
			   if(other is fObject && fEngine.shadowQuality!=fShadowQuality.BEST) msk = this.simpleShadowsLayer
			   else msk = this.lightShadows[light.uniqueId]

				 // Render
				 this.renderShadowInt(light,other,msk)
			
			}
			public function renderShadowInt(light:fLight,other:fRenderableElement,msk:Sprite):void { }

			/**
			* Ends render
			*/
			public override function renderFinish(light:fLight):void {
      	 this.cacheTimer.start()
			}

			/**
			* This listener sets the cacheAsBitmap of a Plane back to true when it doesn't change for a while
			*/
			public function cacheTimerListener(event:TimerEvent):void {
         
         this.baseContainer.blendMode = BlendMode.NORMAL
         this.baseContainer.cacheAsBitmap = true
		   	 for(var i in this.lightBumps) this.lightBumps[i].cacheAsBitmap = true
			}

			/**
			* Starts acclusion related to one character
			*/
			public override function startOcclusion(character:fCharacter):void {
				
					if(this.occlusionCount==0) {
						this.baseContainer.addChild(this.occlusionLayer)
						this.disableMouseEvents()
					}
					this.occlusionCount++
					
					// Create spot if needed
					if(!this.occlusionSpots[character.uniqueId]) {
						var spr:Sprite = new Sprite()
						spr.mouseEnabled = false
						spr.mouseChildren = false
						
						var size:Number = 1.5*Math.max(character.radius,character.height)
						movieClipUtils.circle(spr.graphics,0,0,size,50,0xFFFFFF,character.occlusion)
						this.occlusionSpots[character.uniqueId] = spr
					}
					
					this.occlusionLayer.addChild(this.occlusionSpots[character.uniqueId])
					
			}

			/**
			* Updates acclusion related to one character
			*/
			public override function updateOcclusion(character:fCharacter):void {
					var spr:Sprite = this.occlusionSpots[character.uniqueId]
					var p:Point = new Point(0,-character.height/2)
					p = character.container.localToGlobal(p)
					p = this.occlusionLayer.globalToLocal(p)
					spr.x = p.x
					spr.y = p.y
			}

			/**
			* Stops acclusion related to one character
			*/
			public override function stopOcclusion(character:fCharacter):void {
					this.occlusionLayer.removeChild(this.occlusionSpots[character.uniqueId])
					this.occlusionCount--
					if(this.occlusionCount==0) {
						this.enableMouseEvents()
						this.baseContainer.removeChild(this.occlusionLayer)
					}
			}



			/** @private */
			public function disposePlaneRenderer():void {

        this.cacheTimer.removeEventListener(TimerEvent.TIMER, cacheTimerListener)
       	this.cacheTimer.stop()
			  // Holes
			  var element:fPlane = this.element as fPlane
			  for(var i:Number=0;i<element.holes.length;i++) {
   					element.holes[i].removeEventListener(fHole.OPEN,this.openHole)
				 		element.holes[i].removeEventListener(fHole.CLOSE,this.closeHole)
				 		if(!element.holes[i].open && element.holes[i].block) this.behind.removeChild(element.holes[i].block)				 		 	
			  }

				this.holesC = null
				this.bumpMap = null
				if(this.bumpMapData) this.bumpMapData.dispose()
				this.displacer = null
				this.infront = null
				this.tMatrix = null
				this.tMatrixB = null
				for(i=0;i<this.lightClips.length;i++) delete this.lightClips[i]
				this.lightClips = null
				for(i=0;i<this.lightMasks.length;i++) delete this.lightMasks[i]
				this.lightMasks = null
				for(i=0;i<this.lightShadows.length;i++) delete this.lightShadows[i]
				this.lightShadows = null
				for(i=0;i<this.lightBumps.length;i++) delete this.lightBumps[i]
				this.lightBumps = null
				for(var j in this.lightStatuses) delete this.lightStatuses[j]
				this.lightStatuses = null
				this.disposeRenderer()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposePlaneRenderer()
			}

		}

}
