// Basic renderable element class

package org.ffilmation.engine.elements {
	
		// Imports
		import org.ffilmation.utils.*
	  import flash.display.*
	  import flash.events.*	
		import flash.utils.*
		import flash.geom.*
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.collisionModels.*

		/** 
		* <p>An Object is a graphic element that is part of the the environment and is not projected in any way.
		* The library item is attached to the scene as is. Objects cast and receive shadows.</p>
		*
		* <p>Trees, statues and furniture are typical examples of objects.</p>
		* 
		* <p>Objects can't be moved and can't be added/removed dynamically because this allows several rendering optimizations. 
		* If you want to move something or add/remove it on the fly use the "Character" class instead</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS OBJECT.<br>
		* Objects are created when the scene is processed</p>
		*
		* @see org.ffilmation.engine.elements.fCharacter
		*/
		public class fObject extends fRenderableElement {
			
			// Constants
			
			/**
			* Limits size of object shadow projection relative to X times the object's height (amount of stretching movieClips will suffer)
			*/
			public static const MAXSHADOW = 2

			// Private properties
	    private var baseObj:MovieClip
	    private var defObj:XML
			private var lights:Array
			private var glight:fGlobalLight
			private var allShadows:Array
			private var definitionXML:XML
			private var sprites:Array
			private var currentSprite:MovieClip
			private var currentSpriteIndex:Number
			
			// Protected properties
			/**
			* @private
			*/
			protected var projectionCache:fObjectProjectionCache
			
			// Public properties
			private var _orientation:Number
			
			/** 
			* The collision model for this object. A collision model is a matematical representation of an object's geometry
			* that is used to manage collisions. For example, a box is a good collision model for a car, and a cilinder is a
			* good collision model for people.<br>
		  * Collision models need to be simple geometry so the engine can solve collisions fast.
		  * @private
			*/
			public var collisionModel:fEngineCollisionModel
			
			/**
			* The definition ID for this fObject. It is useful for example when processing collision events, as it will allow
			* you to know what kind of thing did you collide against.
			*/
			public var definitionID:String
			
			/**
			* This property provides a bit of rendering optimization.
			* Non-Animated objects can be rendered faster if their cacheAsBitmap property is set to true.
			* For animated objects this would slowdown performance as the cache would be redrawn continuously.
			* Don't confuse "animated" ( a looping movieClip ) with "moveable".
			* fObjects default to non-animated and fCharacters default to animated. You can use the <b>animated</b> attribute in your XMLs to change this
			 */
			public var animated:Boolean
			
			/** @private */
	    public var shadowObj:Class
			/** @private */
			public var shadowRange:Number
			
			// Constructor
			/** @private */
			function fObject(container:MovieClip,defObj:XML,scene:fScene,level:fLevel):void {
				
				 // Make sure this object has a definition in the scene. If it doesn't, throw an error
				 try {

				 		this.definitionID = defObj.@definition
				 		this.definitionXML = scene.objectDefinitions[defObj.@definition].copy()
				
						// Retrieve all sprites for this object
						this.sprites = new Array
						var sprites:XMLList = this.definitionXML.displayModel.child("sprite")
						for(var i:Number=0;i<sprites.length();i++) {
							
								var spr:XML = sprites[i]
								
								// Check for library item
			          var clase:Class = getDefinitionByName(spr.@src) as Class
						
								// Check for shadow definition or use default
								try {
			      			var shadow:Class = getDefinitionByName(spr.@shadowsrc) as Class
			      		} catch(e:Error) {
			      			shadow = clase
			      		}
								this.sprites.push(new fSpriteDefinition(parseInt(spr.@angle),clase,shadow))
								
						}
						
						// Sort sprites and add first one to the end of the list
						this.sprites.sortOn("angle", Array.NUMERIC)
						this.sprites[this.sprites.length] = this.sprites[0]
						
						// Attach base clip
						this.baseObj = new MovieClip()
				 		container.addChild(this.baseObj)
				 		this.baseObj.mouseEnabled = false
		
					  // Shadows
				    this.allShadows = new Array

						// Initialize rotation for this object
						this._orientation = 0
						
						// Previous
						super(defObj,scene,this.baseObj,container)
						
	  				// Is it animated ?
	  			  if(defObj.@animated.length()!=1) this.animated = (defObj.@animated.toString()=="true")
	  				
	  				// Definition Lights enabled ?
	  				var temp:XMLList = this.definitionXML.@receiveLights
	  			  if(defObj.@receiveLights.length()!=1 && temp.length()==1) this.receiveLights = (temp.toString()=="true")
	  
	  				// Definition Shadows enabled ?
	  				temp = this.definitionXML.@receiveShadows
	  			  if(defObj.@receiveShadows.length()!=1 && temp.length()==1) this.receiveShadows = (temp.toString()=="true")
	  
	  				// Definition Projects shadow ?
	  				temp = this.definitionXML.@castShadows
	  			  if(defObj.@castShadows.length()!=1 && temp.length()==1) this.castShadows = (temp.toString()=="true")
	  
	  				// Definition Solid ?
	  				temp = this.definitionXML.@solid
	  			  if(defObj.@solid.length()!=1 && temp.length()==1) this.solid = (temp.toString()=="true")
				 
				 } catch (e:Error) {
				 		throw new Error("Filmation Engine Exception: The scene does not contain a valid object definition that matches definition id '"+defObj.@definition+"' in object "+defObj.@id+".")
				 }

				 this.defObj = defObj

				 // Retrieve collision model
				 if(this.definitionXML.collisionModel.cilinder.length()>0) {
				 		try {
				 			this.collisionModel = new fCilinderCollisionModel(this.definitionXML.collisionModel.cilinder[0])
				 		} catch (e:Error) {
				 			throw new Error("Filmation Engine Exception: Object definition '"+defObj.@definition+"' contains an invalid cilinder collision model. "+e)
				 		}
				 } else if(this.definitionXML.collisionModel.box.length()>0) {
				 		if(this is fCharacter) throw new Error("Filmation Engine Exception: Sorry as of this relase fCharacters are only allowed to have the cilinder collision model ('"+defObj.@definition+"').")
				 		else this.collisionModel = new fBoxCollisionModel(this.definitionXML.collisionModel.box[0])
				 } else {
				 		throw new Error("Filmation Engine Exception: Object definition '"+defObj.@definition+"' does not contain a valid collision model.")
				 }


		     // Define bounds
		     this.shadowRange = this.height*fObject.MAXSHADOW*fEngine.DEFORMATION
			   this.top = this.z+this.height
				 this.x0 = this.x-this.radius
				 this.x1 = this.x+this.radius
				 this.y0 = this.y-this.radius
				 this.y1 = this.y+this.radius

				 // Light control
				 this.lights = new Array()
			 
			 	 // Projection cache
			 	 this.projectionCache = new fObjectProjectionCache
			 	 
			 	 // Initial orientation
			 	 if(defObj.@orientation.length()>0) this.orientation = new Number(defObj.@orientation[0])
			 	 else this.orientation = 0
			 	 
			 	 // Cache as bitmap non-animated objects
			 	 this.container.cacheAsBitmap = this.animated!=true
			 	 
			 	 // Show and hide listeners, to redraw shadows
			 	 this.addEventListener(fRenderableElement.SHOW,this.showListener)
			 	 this.addEventListener(fRenderableElement.HIDE,this.hideListener)
			 	 
				 
			}

			// Methods
			/** @private */
			public override function place():void {
			   // Place in position
			   var coords:Point = this.scene.translateCoords(this.x,this.y,this.z)
			   this.container.x = coords.x
			   this.container.y = coords.y
			   
			}
			
			/** @private */
			public override function distanceTo(x:Number,y:Number,z:Number):Number {
			
				 return Math.min(mathUtils.distance3d(x,y,z,this.x,this.y,this.z),
				 								 mathUtils.distance3d(x,y,z,this.x,this.y,this.top))
			
			}

			/**
			* The orientation (in degrees) of the object along the Z axis. That is, if the object was a man standing anywhere on our scene, this
			* would be where was his nose pointing. The default value of 0 indicates it is "looking" towards the positive X axis.
			*
			* The Axis in the Filmation Engine go like this.
			*		 
			*	<listing version="3.0">	 
			*		 positive Z
			*		         |
			*		         |      / positive X
			*		         |    /
			*		         |  /
			*	   (0,0,0) X/
			*		          \
			*		            \
			*		              \
			*		                \ positive Y
		  * </listing>
		  *
			* @param angle The angle, in degrees, when want to set
			*/
			public function set orientation(angle:Number):void {
				
				var correctedAngle:Number = angle%360
				if(correctedAngle<0) correctedAngle+=360
				correctedAngle/=360
				
				this._orientation = correctedAngle
				
				var newSprite:Number = Math.floor(correctedAngle*this.sprites.length)
				
				if(this.currentSpriteIndex!=newSprite) {
					
					// Update display model
					try {
						var lastFrame:Number = this.currentSprite.currentFrame
						this.baseObj.removeChild(this.currentSprite)
					} catch(e:Error) {
						lastFrame = 1
					}
					
					var clase:Class = this.sprites[newSprite].sprite as Class
					this.currentSprite = new clase() as MovieClip
					this.baseObj.addChild(this.currentSprite)
					this.currentSprite.mouseEnabled = false
					this.currentSprite.gotoAndPlay(lastFrame)
					this.flashClip = this.currentSprite
					
					// Update collision model
					this.collisionModel.orientation = this.sprites[newSprite].angle
					
					// Update shadow model
					var l:int = this.allShadows.length
				  var shadowClase:Class = this.sprites[newSprite].shadow as Class
					for(var i:int=0;i<l;i++) {
						
					  var info:fObjectShadow = this.allShadows[i]
						var n:MovieClip = new shadowClase() as MovieClip
						info.shadow.removeChild(info.clip)
						info.shadow.addChild(n)
						info.clip = n
						n.gotoAndPlay(lastFrame)
						
					}
					
				}
				
				this.currentSpriteIndex = newSprite
				
			}

			public function get orientation():Number {
				return this._orientation
	  	}


			/**
			* The height in pixels of an imaginary cilinder enclosing the object. It is used only for colision detection. You can change it anytime
			* This is useful for example if a character has rolling or crawling movements and you want to change its collision height during those
			* movements.
			*/
			public function set height(h:Number):void {
				this.collisionModel.height = h
				this.top = this.z+h
			}
			public function get height():Number {
				return this.collisionModel.height
	  	}

			/**
			* The radius in pixels of an imaginary cilinder enclosing the object. It is used only for colision detection.
			*/
			public function get radius():Number {
				return this.collisionModel.getRadius()
	  	}

			/** This method will redraw this object's shadows
			    when it is shown */
			private function showListener(evt:Event):void {
				 var l:int = this.allShadows.length
				 for(var i:int=0;i<l;i++) this.allShadows[i].clip.visible = true
			}
			
			/** This method will erase this object's shadows
			    when it is hidden */
			private function hideListener(evt:Event):void {
				 var l:int = this.allShadows.length
				 for(var i:int=0;i<l;i++) this.allShadows[i].clip.visible = false
			}

			/**
			* Passes the stardard gotoAndPLay command to the base clip
			*
			* @param where A frame number or frame label
			*/
			public override function gotoAndPlay(where:*):void {
					this.flashClip.gotoAndPlay(where)
					var l:int = this.allShadows.length
					for(var i:int=0;i<l;i++) this.allShadows[i].clip.gotoAndPlay(where)
			}

			/**
			* Passes the stardard gotoAndStop command to the base clip
			*
			* @param where A frame number or frame label
			*/
			public override function gotoAndStop(where:*):void {
					this.flashClip.gotoAndStop(where)
					var l:int = this.allShadows.length
					for(var i:int=0;i<l;i++) this.allShadows[i].clip.gotoAndStop(where)
			}

			/**
			* Calls a function of the base clip
			*
			* @param what Name of the function to call
			*
			* @param param An optional extra parameter to pass to the function
			*/
			public override function call(what:String,param:*=null):void {
					
					this.flashClip[what](param)
					var l:int = this.allShadows.length
					for(var i:int=0;i<l;i++) this.allShadows[i].clip[what](param)
			}


			/*
			* Objects can't be moved
			*/
			/** @private */
			public override function moveTo(x:Number,y:Number,z:Number):void {
			  throw new Error("Filmation Engine Exception: You can't move a fObject. If you want to move "+this.id+" make it an fCharacter"); 
			}
			

			// Test primary collision between any object and this object
			/** @private */
			public override function testPrimaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {
				
				var obj:fObject = other as fObject
				
				// Simple case. This works now, but it wouldn't with sphere collision models, for example
				if(this.top<obj.z || this.z>obj.top) return null

				// The generic implementation of this test works with any collisionModel
				// But as cilinders allow a more efficient detection, I've programmed specific
				// algorythms for these cases
				if(obj.collisionModel is fCilinderCollisionModel) {
				
					if(this.collisionModel is fCilinderCollisionModel) {
					
						// Both elements use cilinder model
						var distance:Number = mathUtils.distance(obj.x,obj.y,this.x,this.y)
						var impulse:Number = (this.radius+obj.radius)
						if(distance<impulse) {
						
						  impulse*=1.01
						  var angle:Number = mathUtils.getAngle(this.x,this.y,obj.x,obj.y,distance)*Math.PI/180
							return new fCollision(this.x+impulse*Math.cos(angle),this.y-impulse*Math.sin(angle),-1)
							
						} else return null
				
			  	} else {
			  		
			  	  // Only the moving object uses cilinder model. Note that collisionModels use local coordinates. Therefore
			  	  // any point that is to be tested needs to be translated to the model's coordinate origin.
						angle = mathUtils.getAngle(this.x,this.y,obj.x,obj.y)*Math.PI/180
						var cos:Number = -obj.radius*Math.cos(angle)
						var sin:Number = obj.radius*Math.sin(angle)
						var nx:Number = obj.x+cos
						var ny:Number = obj.y+sin
						
						if(this.collisionModel.testPoint(nx-this.x,ny-this.y,0)) {
							
							var oppositex:Number = obj.x-cos-this.x
							var oppositey:Number = obj.y-sin-this.y
							var nx2:Number = nx-this.x
							var ny2:Number = ny-this.y
							
							// Find out collision point.
							var points:Array = this.collisionModel.getTopPolygon()
							var intersect:Point = null
							for(var i:Number=0;intersect==null && i<points.length;i++) {
								
								if(i==0) intersect = mathUtils.segmentsIntersect(nx2,ny2,oppositex,oppositey,points[0].x,points[0].y,points[points.length-1].x,points[points.length-1].y)
								else intersect = mathUtils.segmentsIntersect(nx2,ny2,oppositex,oppositey,points[i].x,points[i].y,points[i-1].x,points[i-1].y)
								
							}
							

							// This shouldn't happen
							if(intersect==null) return null
							
							// Bounce
							nx = obj.x-(nx2-intersect.x)*1.01
							ny = obj.y-(ny2-intersect.y)*1.01
							
							return new fCollision(nx,ny,-1)
							
						} else return null
			  		
			  		
			  	}
			  	
			  } else {
			  	
			  	// Use generic collision test. Pending implementation
			  	
			  	return null
			  	
			  }

			}


			// Test secondary collision between an object and this object
			/** @private */
			public override function testSecondaryCollision(other:fRenderableElement,dx:Number,dy:Number,dz:Number):fCollision {

				var obj:fObject = other as fObject

				if(obj.z>this.top || obj.top<this.z) return null
				
				// The generic implementation of this test works with any collisionModel
				// But as cilinders allow a more efficient detection, I've programmed specific
				// algorythms for these cases
				if(obj.collisionModel is fCilinderCollisionModel) {
				
					if(this.collisionModel is fCilinderCollisionModel) {
					
						// Both elements use cilinder model
						if(mathUtils.distance(obj.x,obj.y,this.x,this.y)>=(this.radius+obj.radius)) return null
						
			  	} else {
			  		
			  	  // Only the moving object uses cilinder model. Note that collisionModels use local coordinates. Therefore
			  	  // any point that is to be tested needs to be translated to the model's coordinate origin.
						var angle:Number = mathUtils.getAngle(this.x,this.y,obj.x,obj.y)*Math.PI/180
						var cos:Number = -obj.radius*Math.cos(angle)
						var sin:Number = obj.radius*Math.sin(angle)
						var nx:Number = obj.x+cos
						var ny:Number = obj.y+sin
						
						if(!this.collisionModel.testPoint(nx-this.x,ny-this.y,0)) return null
			  		
			  	}
			  	
			  } else {
			  	
			  	// Use generic collision test. Pending implementation
			  	
			  	return null
			  	
			  }

				if(obj.z<this.top && obj.top>this.z && (obj.z-dz)>this.top) return new fCollision(-1,-1,this.top+0.01)
				if(obj.top>this.z && obj.z<this.z && (obj.top-dz)<this.z) return new fCollision(-1,-1,this.z-0.01)

				return null

			}


			/*
			* Updates zIndex of this object so it displays with proper depth inside the scene
			*/
			/** @private */
			public function updateDepth():void {
				
				 var c:fCell = (this.cell==null)?(this.scene.translateToCell(this.x,this.y,this.z)):(this.cell)
				 var nz:Number = c.zIndex
				 this.setDepth(nz)
				 
			}

			/*
			* Returns a MovieClip of the shadow representation of this object, so
			* the other elements can draw this shadow on themselves 
			*
			* @param request The renderableElement requesting the shadow
			*
			* @return A movieClip instance ready to attach to the element that has to show the shadow of this object
			*/
			/** @private */
			public function getShadow(request:fRenderableElement):Sprite {
				

				 var clase:Class = this.sprites[this.currentSpriteIndex].shadow as Class
				 var clip:MovieClip = new clase() as MovieClip

				 var shadow:Sprite = new Sprite()
				 var par:Sprite = new Sprite()
				 shadow.addChild(clip)
				 par.addChild(shadow)
				 clip.gotoAndPlay(this.currentSprite.currentFrame)

				 this.allShadows.push(new fObjectShadow(shadow,clip,request))
				 
				 return shadow

			}
		
			/*
			* Calculates the projection of this object to a given floor Z
			*/
			/** @private */
			public function getProjection(floorz:Number,x:Number,y:Number,z:Number):fObjectProjection {
				
				 // Test cache
				 if(this.projectionCache.test(floorz,x,y,z)) {
				 		
				 		//trace("Read cache")
				 		
				 } else {

				 		//trace("Write cache")
				 		if(this.z>floorz && z<this.z) {
				 			
				 			// No projection
				 			this.projectionCache.update(floorz,x,y,z,null)
				 			return this.projectionCache.projection
				 			
				 		}
				 
				 		var zbase:Number = this.z
				 		var ztop:Number = this.top
				 		var r:Number = this.radius
				 		var height:Number = this.height
				 		
				 		// Correct if object is below projection Z
				 		if(zbase<floorz) {
				 		}

				 		// Get 2D vector from point to object
				 		var vec:Vector = new Vector(this.x-x,this.y-y)
				 		vec.normalize()
				 		
				 		var dist:Number = mathUtils.distance(x,y,this.x,this.y)
				 	
				 		// Calculate projection from coordinates to base of
				 		var dzI:Number = (zbase-floorz)/(z-zbase)
				 		var projSizeI:Number = dist*dzI

				 		// Calculate projection from coordinates to top of object
				 		if(ztop<z) {
				 			var dzF:Number = (ztop-floorz)/(z-ztop)
				 			var projSizeF:Number = dist*dzF
			
						  // Projection size
					 		var projSize:Number = projSizeF-projSizeI
					 		if(projSize>fObject.MAXSHADOW*height || projSize<=0) projSize=fObject.MAXSHADOW*height

				 		} else {
				 			projSize=fObject.MAXSHADOW*height
				 		}


				 		// Calculate origin point
				 		var origin:Point = new Point(this.x+vec.x*projSizeI,this.y+vec.y*projSizeI)
				 		
				 		// Get perpendicular vector
				 		var perp:Vector = vec.getPerpendicular() 
            
				 		// Get first 2 points
				 		var p1:Point = new Point(origin.x+r*perp.x,origin.y+r*perp.y)
				 		var p2:Point = new Point(origin.x-r*perp.x,origin.y-r*perp.y)
				 		
				 		// Use normalized direction vector and use to find the 2 other points				 
				 		var p3:Point = new Point(p2.x+vec.x*projSize,p2.y+vec.y*projSize)
				 		var p4:Point = new Point(p1.x+vec.x*projSize,p1.y+vec.y*projSize)
				 		
				 		// Calculate end point
				 		var end:Point = new Point(origin.x+vec.x*projSize,origin.y+vec.y*projSize)
				 		
				 		// Create new value 
				 		var ret = new fObjectProjection()
				 		ret.polygon = [p1,p2,p3,p4]
				 		ret.size = projSize
				 		ret.origin = origin
				 		ret.end = end
				 		this.projectionCache.update(floorz,x,y,z,ret)
	
				 }
				 
		 		 return this.projectionCache.projection
				
			}


			// Override light methods
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
		 		 res.redOffset = Math.min(1,res.redOffset)
		 		 res.blueOffset = Math.min(1,res.blueOffset)
	 		   res.greenOffset = Math.min(1,res.greenOffset)
				 
				 
				 this.baseObj.transform.colorTransform = res
			}

			/** @private */
			public override function setGlobalLight(light:fGlobalLight):void {
				 this.glight = light
				 light.addEventListener(fLight.INTENSITYCHANGE,this.processGlobalIntensityChange)
				 light.addEventListener(fLight.RENDER,this.processGlobalIntensityChange)
			}

			/** @private */
			public override function processGlobalIntensityChange(evt:Event):void {
				 this.paintLights()
			}
			
			// Makes light visible
			/** @private */
			public override function showLight(light:fLight):void {
					
				 // Already there ?	
			   if(!this.lights[light.uniqueId]) this.lights[light.uniqueId] = new fLightWeight(this,light)
				
			}
			
			// Makes light invisible
			/** @private */
			public override function hideLight(light:fLight):void {
			
				 delete this.lights[light.uniqueId]
				 this.paintLights()
			
			}
			
			// Render start
			/** @private */
			public override function renderStart(light:fLight):void {
			
				 // Already there ?	
			   if(!this.lights[light.uniqueId]) this.lights[light.uniqueId] = new fLightWeight(this,light)

			}
			
			// Render ( draw ) light
			/** @private */
			public override function renderLight(light:fLight):void {
			
		     this.lights[light.uniqueId].updateWeight()
			
			}
			
			// Tests shadows of other elements upon this element
			/** @private */
			public override function testShadow(other:fRenderableElement,x:Number,y:Number,z:Number):Number {
					return fCoverage.NOT_SHADOWED
			}


			// Renders shadows of other elements upon this element
			/** @private */
			public override function renderShadow(light:fLight,other:fRenderableElement):void {
			   
			
			}

			// Ends render
			/** @private */
			public override function renderFinish(light:fLight):void {
					this.paintLights()
			}
			

			// Confirm fCollision with a given point
			/** @private */
			public override function confirmImpact(x:Number,y:Number,z:Number,dx:Number,dy:Number,dz:Number):fPlaneBounds {
				
					if(!this.solid) return null
					
					// Above or below the object
					if(z<this.z || z>=this.top) return null
					
					// Must check radius
					if(mathUtils.distance(this.x,this.y,x,y)<this.radius) {
						
						var angle:Number = mathUtils.getAngle(x,y,this.x,this.y)*Math.PI/180
						var ret:fPlaneBounds = new fPlaneBounds()
						ret.x0 = ret.x1 = this.x-this.radius*Math.cos(angle)
						ret.y0 = ret.y1 = this.y+this.radius*Math.sin(angle)
						return ret
						
					} else return null
					
			}


		}
		
		
}