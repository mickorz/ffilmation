package org.ffilmation.engine.core {
	
		// Imports
		import org.ffilmation.utils.*
	  import flash.display.*
	  import flash.events.*	
		import flash.utils.*
		import flash.filters.DisplacementMapFilter
		import flash.filters.DisplacementMapFilterMode
		import flash.geom.Point
		import flash.geom.Matrix
		import org.ffilmation.engine.helpers.*
	  
		/**
		* <p>fPlanes are the 2d surfaces that provide the main structure for any scene. Once created, planes can't be altered
		* as the render engine relies heavily on precalculations that depend on the structure of the scene.</p>
		*
		* <p>Planes cannot be instantiated directly. Instead, fWall and fFloor are used.</p>
		*
		* <p>fPlane contains all the lighting, occlusions and shadowcasting code. They also support bump mapping</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT</p>
		*/
		public class fPlane extends fRenderableElement {
		
			// Static properties

			// Private properties
			private var lightC:Sprite								  // All lights
			private var environmentC:Shape				    // Global
			private var black:Shape				  				  // No light
			private var diffuse:DisplayObject					// Diffuse map
			private var holesC:Sprite				    			// Holes
			private var bumpMap:BumpMap								// Bump maps
			private var bumpMapData:BitmapData
			private var displacer:DisplacementMapFilter
			private var spriteToDraw:Sprite
			private var baseContainer:DisplayObjectContainer
			
			private var behind:DisplayObjectContainer  // Elements behind the wall will added here
			private var infront:DisplayObjectContainer // Elements in front of the wall will added here
			
			private var tMatrix:Matrix
			private var tMatrixB:Matrix
			private var origWidth:Number
			private var origHeight:Number
			private var	cacheTimer:Timer
			private var firstBump:Boolean = true
			
			// Internal
			
			/** @private */
			public var lightClips:Object            // List of containers used to represent lights (interior)
			/** @private */
			public var lightMasks:Object            // List of containers representing the light mask / shape
			/** @private */
			public var lightShadows:Object          // Container where geometry shadows are drawn
			/** @private */
			public var lightBumps:Object           	// Bump map layers
			/** @private */
			public var zIndex:Number								// zIndex

			
			/** 
			* Array of holes in this plane. 
			* You can't create holes dynamically, they must be in the plane's definition, but you can open and close them as you wish
			*
		  * @see org.ffilmation.engine.core.fHole
			*/
			public var holes:Array									// Array of holes in this plane
			
	
			/** 
			* Material applied to this plane
			*/
			public var material:fMaterial
						
			/** @private */
			public var lightStatuses:Object      		// References to light status


		  // Events

			// Constructor
			/** @private */
			function fPlane(defObj:XML,scene:fScene,width:Number,height:Number,spriteToDraw:Sprite,spriteToShowHide:MovieClip):void {
				
				 // Prepare material
				 this.scene = scene
				 this.material = new fMaterial(defObj.@src,width,height,this)
				 
				 // Previous
				 super(defObj,scene,diffuse,spriteToShowHide)
				 
 			   this.diffuse = this.material.getDiffuse()
 			   
 			   var d:Sprite = this.diffuse as Sprite
 			   d.mouseEnabled = false
 			   d.mouseChildren = false

				 // Properties
			   this.origWidth = diffuse.width
			   this.origHeight = diffuse.height
			   this.spriteToDraw = spriteToDraw

				 // This is the Sprite where all light layers are generated. This Sprite is not deformed
				 // This Sprite is attached to the deformed sprite that is visible onscreen
				 this.baseContainer = new Sprite()
				 this.behind = new Sprite()
				 this.infront = new Sprite()
			   this.baseContainer.addChild(this.behind)
			   this.baseContainer.addChild(diffuse)
			   this.baseContainer.addChild(this.infront)
			   this.spriteToDraw.addChild(this.baseContainer)

			   // LIGHT
			   this.lightClips = new Object  
			   this.lightStatuses = new Object   		
			   this.lightMasks = new Object   		
			   this.lightShadows = new Object   		
			   this.lightBumps = new Object   		
			   this.lightC = new Sprite()
			   this.holesC = new Sprite()
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
			   this.baseContainer.addChild(this.holesC)
			   this.holesC.blendMode = BlendMode.ERASE
				 this.holesC.mouseEnabled = false

			   // Holes
			   this.holes = this.material.getHoles()
			   for(var i:Number=0;i<this.holes.length;i++) {
   					 this.holes[i].addEventListener(fHole.OPEN,this.openHole)
				 		 this.holes[i].addEventListener(fHole.CLOSE,this.closeHole)
				 		 this.holes[i].open = false
			   }
				 this.redrawHoles()

			   // Cache as Bitmap with Timer cache
			   // The cache is disabled while the Plane is being modified and a timer is set to re-enable it
			   // if the plane doesn't change in a while
			   //if(this.holes.length==0)
			   this.container.cacheAsBitmap = true
				 this.cacheTimer = new Timer(100,1)
         this.cacheTimer.addEventListener(TimerEvent.TIMER, cacheTimerListener)

			}

			/**
			* This method listens to holes beign opened
			*/
			private function openHole(event:Event):void {
				
				try {
					var hole:fHole = event.target as fHole
					if(hole.block) {
						this.behind.removeChild(hole.block)
						this.redrawLights()
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
						this.redrawLights()
					}
				} catch(e:Error) {
					
				}

			}

			/**
			* Redraws all lights when a hole has been opened/closed
			*/
			private function redrawLights():void {
				  
					this.redrawHoles()
					for(var i:Number=0;i<this.scene.lights.length;i++) {
						var l:fLight = this.scene.lights[i]
						if(l) l.render()
					}
			}

			// Mouse management
			/** @private */
			public override function disableMouseEvents():void {
				this.container.mouseEnabled = false
				this.spriteToDraw.mouseEnabled = false
			}

			/** @private */
			public override function enableMouseEvents():void {
				this.container.mouseEnabled = true
				this.spriteToDraw.mouseEnabled = true
			}

			/** @private */
			public function iniBump():void {

			   // Bump map ?
	       try {

				 		var ptt:DisplayObject = this.material.getBump()
						
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

			// Planes don't move
			/** @private */
			public override function moveTo(x:Number,y:Number,z:Number):void {
			  throw new Error("Filmation Engine Exception: You can't move a fPlane. ("+this.id+")"); 
		  }


			/** @private */
			public function setZ(zIndex:Number):void {
			   this.zIndex = zIndex
			   this.setDepth(zIndex)
			}

			/** @private */
			public override function setGlobalLight(light:fGlobalLight):void {
				
				 this.black.graphics.clear()
				 this.black.graphics.beginFill(0x000000,1)
		 	   this.black.graphics.moveTo(0,0)
			 	 this.black.graphics.lineTo(0,this.origHeight)
			 	 this.black.graphics.lineTo(this.origWidth,this.origHeight)
			 	 this.black.graphics.lineTo(this.origWidth,0)
			 	 this.black.graphics.lineTo(0,0)

/*				 // For each hole, draw hole in black
				 for(var h:Number=0;h<this.holes.length;h++) {
					
					 	if(this.holes[h].open) {
						 	var hole:fPlaneBounds = this.holes[h].bounds
				 	  	this.black.graphics.moveTo(hole.xrel,hole.yrel)
				 	  	this.black.graphics.lineTo(hole.xrel+hole.width,hole.yrel)
				 	  	this.black.graphics.lineTo(hole.xrel+hole.width,hole.yrel+hole.height)
			 		  	this.black.graphics.lineTo(hole.xrel,hole.yrel+hole.height)
			 	  		this.black.graphics.lineTo(hole.xrel,hole.yrel)
			 	  	}
				 }*/

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

/*				 // For each hole, draw environment
				 for(h=0;h<this.holes.length;h++) {
					
					 	if(this.holes[h].open) {
						 	hole = this.holes[h].bounds
				 	  	this.environmentC.graphics.moveTo(hole.xrel,hole.yrel)
				 	  	this.environmentC.graphics.lineTo(hole.xrel+hole.width,hole.yrel)
			 	  		this.environmentC.graphics.lineTo(hole.xrel+hole.width,hole.yrel+hole.height)
			 	  		this.environmentC.graphics.lineTo(hole.xrel,hole.yrel+hole.height)
			 	  		this.environmentC.graphics.lineTo(hole.xrel,hole.yrel)
			 	  	}
			 	  	
				 } */

				 this.environmentC.graphics.endFill()
	       this.setDimensions(this.environmentC)

		 		 light.addEventListener(fLight.INTENSITYCHANGE,this.processGlobalIntensityChange)
				 light.addEventListener(fLight.RENDER,this.processGlobalIntensityChange)
			}


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
 				 for(var h:Number=0;h<this.holes.length;h++) {

					 	if(this.holes[h].open) {
						 	var hole:fPlaneBounds = this.holes[h].bounds
							this.holesC.graphics.beginFill(0x000000,1)
				 	  	this.holesC.graphics.moveTo(hole.xrel,hole.yrel)
				 	  	this.holesC.graphics.lineTo(hole.xrel+hole.width,hole.yrel)
			 	  		this.holesC.graphics.lineTo(hole.xrel+hole.width,hole.yrel+hole.height)
			 	  		this.holesC.graphics.lineTo(hole.xrel,hole.yrel+hole.height)
			 	  		this.holesC.graphics.lineTo(hole.xrel,hole.yrel)
			 	  		this.holesC.graphics.endFill()
			 	  	}
	       }
				
			}			


			/** @private */
			public override function processGlobalIntensityChange(evt:Event):void {
				
				 	 var light:Object = evt.target
					 this.environmentC.alpha = light.intensity/100
			}


			// Creates masks and containers for a new light, and updates lightStatus
			/** @private */
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
				 
				 this.lightBumps[light.uniqueId] = lay
				 light_c.blendMode = BlendMode.ADD
				 
				 // Create mask
				 var msk:Shape = new Shape()
				 lay.addChild(msk)
			   this.createLightClip(light,msk)
			   this.lightMasks[light.uniqueId] = msk
			   msk.blendMode = BlendMode.NORMAL
				 
				 // Create shadow container
			   var shd:Sprite = new Sprite()
			   lay.addChild(shd)
			   this.lightShadows[light.uniqueId] = shd
			   shd.blendMode = BlendMode.ERASE

			
			}
			
			// Creates light geometry instance in a given container
			/** @private */
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
			
			// Gives geometry container the proper dimensions
			/** @private */
			public function setDimensions(lClip:DisplayObject):void {
		  }

			// Makes light visible
			/** @private */
			public override function showLight(light:fLight):void {
			
			   var lClip:Sprite = this.lightClips[light.uniqueId]
			   this.lightC.addChild(lClip)
				
			}
			
			// Makes light invisible
			/** @private */
			public override function hideLight(light:fLight):void {
			
			   var lClip:Sprite = this.lightClips[light.uniqueId]
			   this.lightC.removeChild(lClip)
			
			}
			
			// Redraws light for a new distante to plane
			/** @private */
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

			/** @private */
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

			/** @private */
			public function processfLightIntensityChange(event:Event):void {
				  this.applyfLightIntensityChange(event.target as fLight)
			}

			/** @private */
			public function applyfLightIntensityChange(light:fLight):void {
   				var lClip:Shape = this.lightMasks[light.uniqueId]
					this.createLightClip(light,lClip)
			}

			// fLight reaches element
			/** @private */
			public override function lightIn(light:fLight):void {
			
			   // Show container
				 if(this.lightStatuses[light.uniqueId]) this.showLight(light)
			   
			}
			
			// fLight leaves element
			/** @private */
			public override function lightOut(light:fLight):void {
			
			   // Hide container
			   if(this.lightStatuses[light.uniqueId]) this.hideLight(light)
			   
			}

			// Starts render process
			/** @private */
			public override function renderStart(light:fLight):void {
			
			   // Create light ?
			   if(!this.lightStatuses[light.uniqueId]) this.lightStatuses[light.uniqueId] = new fLightStatus(this,light)
			   var lightStatus:fLightStatus = this.lightStatuses[light.uniqueId]
				
			   if(!lightStatus.created) {
			      lightStatus.created = true
			      this.addOmniLight(lightStatus)
			      this.lightIn(light)
			   }
			   
			   // Disable cache. Once the render is finished, a timeout is set that will
			   // restore cacheAsbitmap if the object doesn't change for a few seconds.
       	 this.cacheTimer.stop()
       	 this.container.cacheAsBitmap = false
       	 if(this.holes.length!=0) this.baseContainer.blendMode = BlendMode.LAYER
       	 this.lightBumps[light.uniqueId].cacheAsBitmap = false

			   // Init shadows
 			   var msk:Sprite = this.lightShadows[light.uniqueId]
			   msk.graphics.clear()
			  
				 // For each hole, draw mask
				 for(var h:Number=0;h<this.holes.length;h++) {
					
					 	if(this.holes[h].open) {
						 	var hole:fPlaneBounds = this.holes[h].bounds
						 	msk.graphics.beginFill(0x000000,1)
				 	  	msk.graphics.moveTo(hole.xrel,hole.yrel)
				 	  	msk.graphics.lineTo(hole.xrel+hole.width,hole.yrel)
			 		  	msk.graphics.lineTo(hole.xrel+hole.width,hole.yrel-hole.height)
			 	  		msk.graphics.lineTo(hole.xrel,hole.yrel-hole.height)
			 	  		msk.graphics.lineTo(hole.xrel,hole.yrel)
			 	  		msk.graphics.endFill()
			 	  	}
			 	  	
				 }

			   // More
			   this.processRenderStart(light)
			
			}

			/** @private */
			public function processRenderStart(light:fLight):void {

			}

			// Renders shadows of other elements upon this fElement
			/** @private */
			public override function renderShadow(light:fLight,other:fRenderableElement):void {
			   
			   // Select mask
			   var msk:Sprite = this.lightShadows[light.uniqueId]
			
				 // Render
				 this.renderShadowInt(light,other,msk)
			
			}

			/** @private */
			public override function renderShadowAlone(light:fLight,other:fRenderableElement):void {
			   
			   try {
			    
			    // Disable cache. Once the render is finished, a timeout is set that will
			    // restore cacheAsbitmap if the object doesn't change for a few seconds.
       	  this.cacheTimer.stop()
       	 	this.container.cacheAsBitmap = false
       	  if(this.holes.length!=0) this.baseContainer.blendMode = BlendMode.LAYER
       	  this.lightBumps[light.uniqueId].cacheAsBitmap = false

			    // Select mask
			   	var msk:Sprite = this.lightShadows[light.uniqueId]
				 			
				 	// Render
				  this.renderShadowInt(light,other,msk)
				 } catch(e:Error) { }
				 
				 // Start cache timer
				 this.cacheTimer.start()
				 
			}

			/** @private */
			public function renderShadowInt(light:fLight,other:fRenderableElement,msk:Sprite):void {
			}

			// Ends render
			/** @private */
			public override function renderFinish(light:fLight):void {
      	 this.cacheTimer.start()
			}

			/** @private */
			public function cacheTimerListener(event:TimerEvent):void {
         if(this.holes.length!=0) this.baseContainer.blendMode = BlendMode.NORMAL
         this.container.cacheAsBitmap = true
		   	 for(var i in this.lightBumps) this.lightBumps[i].cacheAsBitmap = true
			}

			/** @private */
			public function setLightZ(light:fLight):void {
			}


		}

}
