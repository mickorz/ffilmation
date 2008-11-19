// SCENE

package org.ffilmation.engine.core {

		// Imports
		import flash.xml.*
		import flash.net.*
		import flash.utils.*
		import flash.events.*
		import flash.system.*
		import flash.display.*
		import flash.geom.Point
		import flash.geom.Rectangle	

		import org.ffilmation.utils.*
		import org.ffilmation.engine.core.sceneInitialization.*
		import org.ffilmation.engine.core.sceneLogic.*
		import org.ffilmation.engine.elements.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.interfaces.*
		import org.ffilmation.engine.logicSolvers.coverageSolver.*
		import org.ffilmation.engine.logicSolvers.visibilitySolver.*
		import org.ffilmation.engine.renderEngines.flash9RenderEngine.*
		import org.ffilmation.profiler.*

		
		/**
		* <p>The fScene class provides control over a scene in your application. The API for this object is used to add and remove 
		* elements from the scene after it has been loaded, and managing cameras.</p>
		*
		* <p>Moreover, you can get information on topology, visibility from one point to another, search for paths and other useful
		* methods that will help, for example, in programming AIs that move inside the scene.</p>
		*
		* <p>The data structures contained within this object are populated during initialization by the fSceneInitializer class (which you don't need to understand).</p>
		*
		*/
		public class fScene extends EventDispatcher {
		
			// This counter is used to generate unique scene Ids
			private static var count:Number = 0
			
			// This flag is set by the editor so eery object is created as a character and can be moved
			/** @private */
			public static var allCharacters:Boolean = false

		  // Private properties
		  
		  // 1. References
		  
			private var _controller:fEngineSceneController = null
			private var currentCamera:fCamera										// The camera currently in use
		  /** @private */
			public var prof:fProfiler = null										// Profiler
			private var initializer:fSceneInitializer						// This scene's initializer
		  /** @private */
			public var renderEngine:fEngineRenderEngine					// The render engine
		  /** @private */
		  public var engine:fEngine
		 	/** @private */
			public var _orig_container:Sprite  		  						// Backup reference

			// 2. Geometry and sizes

			/** @private */
		  public var viewWidth:Number													// Viewport size
			/** @private */
		  public var viewHeight:Number												// Viewport size
		  /** @private */
			public var top:Number																// Highest Z in the scene
			/** @private */
			public var gridWidth:Number													// Grid size in cells
			/** @private */
			public var gridDepth:Number
			/** @private */
			public var gridHeight:Number
			/** @private */
		  public var gridSize:Number           								// Grid size ( in pixels )
			/** @private */
		  public var levelSize:Number          								// Vertical grid size ( along Z axis, in pixels )

			// 3. zSort

			/** @private */
		  public var grid:Array                 						  // The grid
		  /** @private */
			public var depthSortArr:Array									  		// Array of elements for depth sorting
			/** @private */
			public var sortAreas:Array													// zSorting generates this. This array points to contiguous spaces sharing the same zIndex
																													// It is used to find the proper zIndex for a cell
																													
			// 4. Resources
			
		 	/** @private */
			public var resourceManager:fSceneResourceManager		// The resource manager stores all definitions loaded for this scene
			
			// 5.Status			

			/** @private */
			public var IAmBeingRendered:Boolean = false					// If this scene is actually being rendered
			private var _enabled:Boolean												// Is the scene enabled ?


		  // Public properties
		  
		  /** 
		  * Every Scene is automatically assigned and ID
		  */
		  public var id:String																

		  /** 
		  * Were this scene is drawn
		  */
		  public var container:Sprite		          						
		  
		  /**
		  * An string indicating the scene's current status
		  */
		  public var stat:String         				 							

		  /**
		  * Indicates if the scene is loaded and ready
		  */
		  public var ready:Boolean
		  
		  /**
		  * Scene width in pixels.
		  */														
			public var width:Number
			
			/**
			* Scene depth in pixels
			*/				
			public var depth:Number
		  
			/**
			* Scene height in pixels
			*/				
			public var height:Number

		  /**
		  * An array of all floors for fast loop access. For "id" access use the .all array
		  */
		  public var floors:Array                 						

		  /**
		  * An array of all walls for fast loop access. For "id" access use the .all array
		  */
		  public var walls:Array                  						

		  /**
		  * An array of all objects for fast loop access. For "id" access use the .all array
		  */
		  public var objects:Array                						

		  /**
		  * An array of all characters for fast loop access. For "id" access use the .all array
		  */
		  public var characters:Array                					

		  /**
		  * An array of all lights for fast loop access. For "id" access use the .all array
		  */
		  public var lights:Array                 						

		  /**
		  * An array of all elements for fast loop access. For "id" access use the .all array. Bullets are not here
		  */
		  public var everything:Array                 						

		  /**
		  * The global light for this scene. Use this property to change light properties such as intensity and color
		  */
		  public var environmentLight:fGlobalLight  					

		  /**
		  * An array of all elements in this scene, use it with ID Strings. Bullets are not here
		  */
		  public var all:Array                    						
		  
		  /**
		  * The AI-related method are grouped inside this object, for easier access
		  */
		  public var AI:fAiContainer
		  
		  /**
		  * All the bullets currently active in the scene are here
		  */
		  public var bullets:Array

			// Bullets go here instead of being deleted, so they can be reused
			private var bulletPool:Array												


		  // Events

			/**
			* An string describing the process of loading and processing and scene XML definition file.
			* Events dispatched by the scene while loading containg this String as a description of what is happening
			*/
			public static const LOADINGDESCRIPTION:String = "Creating scene"

			/**
 			* The fScene.LOADPROGRESS constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>scenecloadprogress</code> event.
 			* The event is dispatched when the status of the scene changes during scene loading and processing.
 			* A listener to this event can then check the scene's status property to update a progress dialog
 			*
 			*/
		  public static const LOADPROGRESS:String = "scenecloadprogress"

			/**
 			* The fScene.LOADCOMPLETE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>sceneloadcomplete</code> event.
 			* The event is dispatched when the scene finishes loading and processing and is ready to be used
 			*
 			*/
		  public static const LOADCOMPLETE:String = "sceneloadcomplete"
		
			/**
			* Constructor. Don't call directly, use fEngine.createScene() instead
			* @private
			*/
			function fScene(engine:fEngine,container:Sprite,retriever:fEngineSceneRetriever,width:Number,height:Number,renderer:fEngineRenderEngine=null,p:fProfiler=null):void {
			
			   // Properties
			   this.id = "fScene_"+(fScene.count++)
			   this.engine = engine
			   this._orig_container = container           
			   this.container = container                 
			   this.environmentLight = null     
			   this.gridSize = 64
			   this.levelSize = 64
			   this.top = 0
			   this.stat = "Loading XML"  
 			   this.ready = false
 			   this.viewWidth = width
 			   this.viewHeight = height
			
			   // Internal arrays
			   this.depthSortArr = new Array          
			   this.floors = new Array          
			   this.walls = new Array           
			   this.objects = new Array         
			   this.characters = new Array         
			   this.lights = new Array         
			   this.everything = new Array          
			   this.all = new Array 
			   this.bullets = new Array          
			   this.bulletPool = new Array          
			   
			   // AI
			   this.AI = new fAiContainer(this)
			
			   // Render engine
			   this.renderEngine = renderer || (new fFlash9RenderEngine(this,container))
			   this.renderEngine.setViewportSize(width,height)
			   
			   // Start xml retrieve process
			   this.initializer = new fSceneInitializer(this,retriever)
			   
				 // Profiler ?
				 this.prof = p

			}
			
			/** Starts initialization process */
			public function initialize():void {
			   this.initializer.start()
			}


			// Public methods
			
			/**
			* This Method is called to enable the scene. It will enable all controllers associated to the scene and its
			* elements. The engine no longer calls this method when the scene is shown. Do it manually when needed.
			*
			* A typical use of manual enabling/disabling of scenes is pausing the game or showing a dialog box of any type.
			*
			* @see org.ffilmation.engine.core.fEngine#showScene
			*/
			public function enable():void {
				
				// Enable scene controller
				this._enabled = true
				if(this.controller) this.controller.enable()
				
				// Enable controllers for all elements in the scene
				for(var i:Number=0;i<this.everything.length;i++) if(this.everything[i].controller!=null) this.everything[i].controller.enable()
				for(i=0;i<this.bullets.length;i++) this.bullets[i].enable()
				
			}
			
			/**
			* This Method is called to disable the scene. It will disable all controllers associated to the scene and its
			* elements. The engine no longer calls this method when the scene is hidden. Do it manually when needed.
			*
			* A typical use of manual enabling/disabling of scenes is pausing the game or showing a dialog box of any type.
			*
			* @see org.ffilmation.engine.core.fEngine#hideScene
			*/
			public function disable():void {
				
				// Disable scene controller
				this._enabled = false
				if(this.controller) this.controller.disable()
				
				// Disable  controllers for all elements in the scene
				for(var i:Number=0;i<this.everything.length;i++) if(this.everything[i].controller!=null) this.everything[i].controller.disable()
				for(i=0;i<this.bullets.length;i++) this.bullets[i].disable()
				
			}

			/**
			* Assigns a controller to this scene
			* @param controller: any controller class that implements the fEngineSceneController interface
			*/
			public function set controller(controller:fEngineSceneController):void {
				
				if(this._controller!=null) this._controller.disable()
				this._controller = controller
				this._controller.assignScene(this)
				
			}
			
			/**
			* Retrieves controller from this scene
			* @return controller: the class that is currently controlling the fScene
			*/
			public function get controller():fEngineSceneController {
				return this._controller
			}

			/** 
			* This method sets the active camera for this scene. The camera position determines the viewable area of the scene
			*
			* @param camera The camera you want to be active
			*
			*/
			public function setCamera(camera:fCamera):void {
				
					// Stop following old camera
					if(this.currentCamera) {
						this.currentCamera.removeEventListener(fElement.MOVE,this.cameraMoveListener)
						this.currentCamera.removeEventListener(fElement.NEWCELL,this.cameraNewCellListener)
					}
					
					// Follow new camera
					this.currentCamera = camera
					this.currentCamera.addEventListener(fElement.MOVE,this.cameraMoveListener)
					this.currentCamera.addEventListener(fElement.NEWCELL,this.cameraNewCellListener)
					this.followCamera(this.currentCamera)
			}
			
			/**
			* Creates a new camera associated to the scene
			*
			* @return an fCamera object ready to move or make active using the setCamera() method
			*
			*/
			public function createCamera():fCamera {
				
					//Return
					return new fCamera(this)
			}

			/**
			* Creates a new light and adds it to the scene. You won't see the light until you call its
			* render() or moveTo() methods
			*
			* @param idlight: The unique id that will identify the light
			*
			* @param x: Initial x coordinate for the light
			*
			* @param y: Initial x coordinate for the light
			*
			* @param z: Initial x coordinate for the light
			*
			* @param size: Radius of the sphere that identifies the light
			*
			* @param color: An string specifying the color of the light in HTML format, example: #ffeedd
			*
			* @param intensity: Intensity of the light goes from 0 to 100
			*
			* @param decay: From 0 to 100 marks the distance along the lights's radius from where intensity starrts to fade fades. A 0 decay defines a solid light
			*
			* @param bumpMapped: Determines if this light will be rendered with bumpmapping. Please note that for the bumpMapping to work in a given surface,
			* the surface will need a bumpMap definition and bumpMapping must be enabled in the engine's global parameters
			*
			*/
			public function createOmniLight(idlight:String,x:Number,y:Number,z:Number,size:Number,color:String,intensity:Number,decay:Number,bumpMapped:Boolean=false):fOmniLight {
				
					// Create
					var definitionObject:XML = <light id={idlight} type="omni" size={size} x={x} y={y} z={z} color={color} intensity={intensity} decay={decay} bump={bumpMapped}/>
			   	var nfLight:fOmniLight = new fOmniLight(definitionObject,this)
			   	
			   	// Events
				 	nfLight.addEventListener(fElement.NEWCELL,this.processNewCell)			   
				 	nfLight.addEventListener(fElement.MOVE,this.renderElement)			   
				 	nfLight.addEventListener(fLight.RENDER,this.processNewCell)			   
				 	nfLight.addEventListener(fLight.RENDER,this.renderElement)			   
				 	nfLight.addEventListener(fLight.SIZECHANGE,this.processNewLightDimensions)			   
			   	
			   	// Add to lists
			   	this.lights.push(nfLight)
			   	this.everything.push(nfLight)
			   	this.all[nfLight.id] = nfLight
				
					//Return
					if(this.IAmBeingRendered) nfLight.render()
					return nfLight
			}

			/**
			* Removes an omni light from the scene. This is not the same as hiding the light, this removes the element completely from the scene
			*
			* @param light The light to be removed
			*/
			public function removeOmniLight(light:fOmniLight):void {
				
					// Remove from array
					this.lights.splice(this.lights.indexOf(light),1)
					this.everything.splice(this.everything.indexOf(light),1)
					
					// Hide light from elements
			    var cell:fCell = light.cell
		      var nEl:Number = light.nElements
		      for(var i2:Number=0;i2<nEl;i2++) this.renderEngine.lightOut(light.elementsV[i2].obj,light)
		      light.scene = null
		      
		      nEl = this.characters.length
		      for(i2=0;i2<nEl;i2++) this.renderEngine.lightOut(this.characters[i2],light)
		      this.all[light.id] = null
		      
			   	// Events
				 	light.removeEventListener(fElement.NEWCELL,this.processNewCell)			   
				 	light.removeEventListener(fElement.MOVE,this.renderElement)			   
				 	light.removeEventListener(fLight.RENDER,this.processNewCell)			   
				 	light.removeEventListener(fLight.RENDER,this.renderElement)			   
				 	light.removeEventListener(fLight.SIZECHANGE,this.processNewLightDimensions)			   

		      // This light may be in some character cache
		      light.removed = true
				
			}

			/** 
			*	Creates a new character an adds it to the scene
			*
			* @param idchar: The unique id that will identify the character
			*
			* @param def: Definition id. Must match a definition in some of the definition XMLs included in the scene
			*
			* @param x: Initial x coordinate for the character
			*
			* @param y: Initial x coordinate for the character
			*
			* @param z: Initial x coordinate for the character
			*
			* @returns The newly created character, or null if the coordinates not allowed (outside bounds)
			*
			**/
			public function createCharacter(idchar:String,def:String,x:Number,y:Number,z:Number):fCharacter {
				
					// Ensure coordinates are inside the scene
					var c:fCell = this.translateToCell(x,y,z)
					if(c==null) {
						return null
					}
					
					// Create
					var definitionObject:XML = <character id={idchar} definition={def} x={x} y={y} z={z} />
			   	var nCharacter:fCharacter = new fCharacter(definitionObject,this)
			   	
			   	// Events
				 	nCharacter.addEventListener(fElement.NEWCELL,this.processNewCell)			   
				 	nCharacter.addEventListener(fElement.MOVE,this.renderElement)			   
         	
			   	// Add to lists
			   	this.characters.push(nCharacter)
			   	this.everything.push(nCharacter)
			   	this.all[nCharacter.id] = nCharacter
					if(this.IAmBeingRendered) this.addElementToRenderEngine(nCharacter)
					nCharacter.updateDepth()

					//Return
					if(this.IAmBeingRendered) this.render()
					return nCharacter
			}

			/**
			* Removes a character from the scene. This is not the same as hiding the character, this removes the element completely from the scene
			*
			* @param char The character to be removed
			*/
			public function removeCharacter(char:fCharacter):void {

					// Remove from arraya
					this.characters.splice(this.characters.indexOf(char),1)
					this.everything.splice(this.everything.indexOf(char),1)
		      this.all[char.id] = null
		      
		      // Hide
		      char.hide()
			   	
			   	// Events
				 	char.removeEventListener(fElement.NEWCELL,this.processNewCell)			   
				 	char.removeEventListener(fElement.MOVE,this.renderElement)			   

		      // Remove from render engine
		      this.removeElementFromRenderEngine(char)
		      char.dispose()

			}

			/**
			* Creates a new bullet and adds it to the scene. Note that bullets use their own render system. The bulletRenderer interface allows
			* you to have complex things such as trails. If it was integrated with the standard renderer, your bullets would have to be standard
			* Sprites, and I dind't like that.
			*
			* <p><b>Note to developers:</b> bullets are reused. Creating new objects is slow, and depending on your game you could have a lot
			* being created and destroyed. The engine uses an object pool to reuse "dead" bullets and minimize the amount of new() calls. This
			* is transparent to you but I think this information can help tracking weird bugs</p>
			*
			* @param x Start position of the bullet
			* @param y Start position of the bullet
			* @param z Start position of the bullet
			* @param speedx Speed of bullet
			* @param speedy Speed of bullet
			* @param speedz Speed of bullet
			* @param renderer The renderer that will be drawing this bullet. In order to increase performace, you should't create a new
			* renderer instance for each bullet: pass the same renderer to all bullets that look the same.
			*
			*/
			public function createBullet(x:Number,y:Number,z:Number,speedx:Number,speedy:Number,speedz:Number,renderer:fEngineBulletRenderer):fBullet {
				
				// Is there an available bullet or a new one is needed ?
				var b:fBullet
				if(this.bulletPool.length>0) {
					b = this.bulletPool.pop()
					b.show()
				}
				else {
					b = new fBullet(this)
					if(this.IAmBeingRendered) this.addElementToRenderEngine(b)
				}
				
				// Events
				b.addEventListener(fElement.NEWCELL,this.processNewCell)			   
				b.addEventListener(fElement.MOVE,this.renderElement)			   
				b.addEventListener(fBullet.SHOT,fBulletSceneLogic.processShot)			   

				// Properties
				b.moveTo(x,y,z)
				b.speedx = speedx
				b.speedy = speedy
				b.speedz = speedz
				
				// Init renderer
				b.customData.bulletRenderer = renderer
				if(b.container) b.customData.bulletRenderer.init(b)
         	
			  // Add to lists
 			  this.bullets.push(b)
				
				// Enable
				if(this._enabled) b.enable()

				// Return
				return b
			}

			/**
			* Removes a bullet from the scene. Bullets are automatically removed when they hit something, 
			* but you If you can't wait for them to be delete, you can do it manually.
			* @param bullet The fBullet to be removed. 
			*/
			public function removeBullet(bullet:fBullet):void {

				// Events
				bullet.removeEventListener(fElement.NEWCELL,this.processNewCell)			   
				bullet.removeEventListener(fElement.MOVE,this.renderElement)			   
				bullet.removeEventListener(fBullet.SHOT,fBulletSceneLogic.processShot)
				
				// Hide
				bullet.disable()
				bullet.customData.bulletRenderer.clear(bullet)
				bullet.hide()
				
				// Back to pool
				this.bullets.splice(this.bullets.indexOf(bullet),1)
				this.bulletPool.push(bullet)
				
			}



			/**
			* This method translates scene 3D coordinates to 2D coordinates relative to the Sprite containing the scene
			* 
			* @param x x-axis coordinate
			* @param y y-axis coordinate
			* @param z z-axis coordinate
			*
			* @return A Point in this scene's container Sprite
			*/
			public function translate3DCoordsTo2DCoords(x:Number,y:Number,z:Number):Point {
				 return fScene.translateCoords(x,y,z)
			}

			/**
			* This method translates scene 3D coordinates to 2D coordinates relative to the Stage
			* 
			* @param x x-axis coordinate
			* @param y y-axis coordinate
			* @param z z-axis coordinate
			*
			* @return A Coordinate in the Stage
			*/
			public function translate3DCoordsToStageCoords(x:Number,y:Number,z:Number):Point {
				
				 //Get offset of camera
         var rect:Rectangle = this.container.scrollRect
         
         // Get point
				 var r:Point = fScene.translateCoords(x,y,z)
				 
				 // Translate
				 r.x-=rect.x
				 r.y-=rect.y
				 
				 return r
			}

			/**
			* This method translates Stage coordinates to scene coordinates. Useful to map mouse events into game events
			*
		  * @example You can call it like
		  *
		  * <listing version="3.0">
      *  function mouseClick(evt:MouseEvent) {
      *    var coords:Point = this.scene.translateStageCoordsTo3DCoords(evt.stageX, evt.stageY)
      *    this.hero.character.teleportTo(coords.x,coords.y, this.hero.character.z)
      *   }
			* </listing>
			*
			* @param x x-axis coordinate
			* @param y y-axis coordinate
			* 
			* @return A Point in the scene's coordinate system. Please note that a Z value is not returned as It can't be calculated from a 2D input.
			* The returned x and y correspond to z=0 in the game's coordinate system.
			*/
			public function translateStageCoordsTo3DCoords(x:Number,y:Number):Point {
         
         //get offset of camera
         var rect:Rectangle = this.container.scrollRect
         var xx:Number = x+rect.x
         var yy:Number = y+rect.y
         
         return fScene.translateCoordsInverse(xx,yy)
      }
      

			/**
			* This method returns the element under a Stage coordinate, and a 3D translation of the 2D coordinates passed as input.
			* To achieve this it finds which visible elements are under the input pixel, ignoring the engine's internal coordinates.
			* Now you can find out what did you click and which point of that element did you click.
			*
			* @param x Stage horizontal coordinate
			* @param y Stage vertical coordinate
			* 
			* @return An array of objects storing both the element under that point and a 3d coordinate corresponding to the 2d Point. This method returns null
			* if the coordinate is not occupied by any element.
			* Why an Array an not a single element ? Because you may want to search the Array for the element that better suits your intentions: for
			* example if you use it to walk around the scene, you will want to ignore trees to reach the floor behind. If you are shooting
			* people, you will want to ignore floors and look for objects and characters to target at.
			*
			* @see org.ffilmation.engine.datatypes.fCoordinateOccupant
			*/
			public function translateStageCoordsToElements(x:Number,y:Number):Array {
				
				// This must be passed to the renderer because we have no idea how things are drawn
				if(this.IAmBeingRendered) return this.renderEngine.translateStageCoordsToElements(x,y)
				else return null
		
			}

			/**
			* Use this method to completely rerender the scene. However, under normal circunstances there shouldn't be a need to call this manually
			*/
			public function render():void {

			   // Render global light
			   this.environmentLight.render()

			   // Render dynamic lights
			   for(var i:Number=0;i<this.lights.length;i++) this.lights[i].render()

			}
			
			/**
			* Normally you don't need to call this method manually. When an scene is shown, this method is called to initialize the render engine
			* for this scene ( this involves creating all the Sprites ). This may take a couple of seconds.<br>
			* Under special circunstances, however, you may want to call this method manually at some point before showing the scene. This is useful is you want
			* the graphic assets to exist before the scene is shown ( to attach Mouse Events for example ).
			*/
			public function startRendering():void {
				
				 if(this.IAmBeingRendered) return
		   	 
			   // Init render engine
			   this.renderEngine.initialize()
			   
			   // Init render for all elements
			   for(var j:Number=0;j<this.floors.length;j++) addElementToRenderEngine(this.floors[j])
			   for(j=0;j<this.walls.length;j++) addElementToRenderEngine(this.walls[j])
			   for(j=0;j<this.objects.length;j++) addElementToRenderEngine(this.objects[j])
			   for(j=0;j<this.characters.length;j++) addElementToRenderEngine(this.characters[j])
			   for(j=0;j<this.bullets.length;j++) {
			   	addElementToRenderEngine(this.bullets[j])
			   	this.bullets[j].customData.bulletRenderer.init()
			   }
		   	 
			   // Set flag
			   this.IAmBeingRendered = true

		   	 // Now sprites can be sorted
			   this.depthSort()

		   	 // Render scene
		   	 this.render()
			   
			}

			// PRIVATE AND INTERNAL METHODS FOLLOW
			
			// INTERNAL METHODS RELATED TO RENDER

			/**
			* This method adds an element to the renderEngine poll
			*/
			private function addElementToRenderEngine(element:fRenderableElement) {
			
				 // Init
				 element.container = this.renderEngine.initRenderFor(element)
				 
				 // This happens only if the render Engine returns a container for every element. 
				 if(element.container) {
				 	element.container.fElementId = element.id
				 	element.container.fElement = element
				 }
				 
				 // This can be null, depending on the render engine
				 element.flashClip = this.renderEngine.getAssetFor(element)
				 
				 // Listen to show and hide events
				 element.addEventListener(fRenderableElement.SHOW,this.showListener,false,0,true)
				 element.addEventListener(fRenderableElement.HIDE,this.hideListener,false,0,true)
				 element.addEventListener(fRenderableElement.ENABLE,this.enableListener,false,0,true)
				 element.addEventListener(fRenderableElement.DISABLE,this.disableListener,false,0,true)
				 
				 // Elements default to Mouse-disabled
				 element.disableMouseEvents()
				 
			}

			/**
			* This method removes an element from the renderEngine poll
			*/
			private function removeElementFromRenderEngine(element:fRenderableElement) {
			
				 this.renderEngine.stopRenderFor(element)
				 
				 // Stop listening to show and hide events
				 element.removeEventListener(fRenderableElement.SHOW,this.showListener)
				 element.removeEventListener(fRenderableElement.HIDE,this.hideListener)
				 element.removeEventListener(fRenderableElement.ENABLE,this.enableListener)
				 element.removeEventListener(fRenderableElement.DISABLE,this.disableListener)
				 
			}

			// Listens to elements made visible
			private function showListener(evt:Event):void {
			   if(this.IAmBeingRendered) this.renderEngine.showElement(evt.target as fRenderableElement)
			}
			
			// Listens to elements made invisible
			private function hideListener(evt:Event):void {
			   if(this.IAmBeingRendered) this.renderEngine.hideElement(evt.target as fRenderableElement)
			}

			// Listens to elements made enabled
			private function enableListener(evt:Event):void {
			   this.renderEngine.enableElement(evt.target as fRenderableElement)
			}
			
			// Listens to elements made disabled
			private function disableListener(evt:Event):void {
			   this.renderEngine.disableElement(evt.target as fRenderableElement)
			}

			/**
			* @private
			* This method is called when the scene is no longer displayed.
			*/
			public function stopRendering():void {
		   	 
			   // Stop render engine
			   this.renderEngine.dispose()
			   
			   // Set flag
			   this.IAmBeingRendered = false
			   
			}

	 	
			// A light changes its size
			/** @private */
			public function processNewLightDimensions(evt:Event):void {
				
				if(this.IAmBeingRendered) {
					
					var light:fOmniLight = evt.target as fOmniLight

					// Hide light from elements
			    var cell:fCell = light.cell
		      var nEl:Number = light.nElements
		      for(var i2:Number=0;i2<nEl;i2++) this.renderEngine.lightReset(light.elementsV[i2].obj,light)
		      
		      nEl = this.characters.length
		      for(i2=0;i2<nEl;i2++) this.renderEngine.lightReset(this.characters[i2],light)

					fLightSceneLogic.processNewLightDimensions(this,evt.target as fOmniLight)
				}
				
			}

			// Element enters new cell
			/** @private */
			public function processNewCell(evt:Event):void {

				if(this.IAmBeingRendered) {
					if(evt.target is fOmniLight) fLightSceneLogic.processNewCellOmniLight(this,evt.target as fOmniLight)
					if(evt.target is fCharacter) fCharacterSceneLogic.processNewCellCharacter(this,evt.target as fCharacter)
					if(evt.target is fBullet) fBulletSceneLogic.processNewCellBullet(this,evt.target as fBullet)
				}
				
			}

			// LIstens to render events
			/** @private */
			public function renderElement(evt:Event):void {
				
			   // If the scene is not being displayed, we don't update the render engine
			   // However, the element's properties are modified. When the scene is shown the result is consistent
			   // to what has changed while the render was not being updated
			   if(this.IAmBeingRendered) {
			   	if(evt.target is fOmniLight) fLightSceneLogic.renderOmniLight(this,evt.target as fOmniLight)
				 	if(evt.target is fCharacter) fCharacterSceneLogic.renderCharacter(this,evt.target as fCharacter)
				 	if(evt.target is fBullet) fBulletSceneLogic.renderBullet(this,evt.target as fBullet)
				 }
				
			}

			// This method is called when the shadowQuality option changes
			/** @private */
		  public function resetShadows():void {
		  	this.renderEngine.resetShadows()
		  	for(var i:Number=0;i<this.lights.length;i++) fLightSceneLogic.processNewCellOmniLight(this,this.lights[i])
		  }
			
			// INTERNAL METHODS RELATED TO CAMERA MANAGEMENT


			// Listens cameras moving
			private function cameraMoveListener(evt:fMoveEvent):void {
					this.followCamera(evt.target as fCamera)
			}

			// Listens cameras changing cells.
			private function cameraNewCellListener(evt:Event):void {
					var camera:fCamera = evt.target as fCamera
			}

			// Adjusts visualization to camera position
			private function followCamera(camera:fCamera):void {
					if(this.prof) {
						this.prof.begin( "Update camera")				
						this.renderEngine.setCameraPosition(camera)
						this.prof.end( "Update camera")				
					} else {
						this.renderEngine.setCameraPosition(camera)
					}
			}

			// INTERNAL METHODS RELATED TO DEPTHSORT

			// Depth sorting
			/** @private */
			public function addToDepthSort(item:fRenderableElement):void {				

				if(this.depthSortArr.indexOf(item)<0) {
				 	this.depthSortArr.push(item)
			   	item.addEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener,false,0,true)
			  }
			
			}

			// Returns a normalized zSort value for a cell in the grid. Bigger values display in front of lower values
			/** @private */
			public function computeZIndex(i:Number,j:Number,k:Number):Number {
				 var ow = this.gridWidth
				 var od = this.gridDepth
				 var oh = this.gridHeight
			   return ((((((ow-i+1)+(j*ow+2)))*oh)+k))/(ow*od*oh)
			}

			/** @private */
			public function removeFromDepthSort(item:fRenderableElement):void {				

				 this.depthSortArr.splice(this.depthSortArr.indexOf(item),1)
			   item.removeEventListener(fRenderableElement.DEPTHCHANGE,this.depthChangeListener)
			
			}

			// Listens to renderableitems changing its depth
			/** @private */
			public function depthChangeListener(evt:Event):void {
				
				//Element
				if(!this.IAmBeingRendered) return
				
				var el:fRenderableElement = evt.target as fRenderableElement
				var oldD:Number = el.depthOrder
				this.depthSortArr.sortOn("_depth", Array.NUMERIC);
				var newD:Number = this.depthSortArr.indexOf(el)
				if(newD!=oldD) {
					el.depthOrder = newD
					this.container.setChildIndex(el.container, newD)
				}
				
			}
			
		  // Initial depth sorting
			private function depthSort():void {
				
				var ar:Array = this.depthSortArr
				ar.sortOn("_depth", Array.NUMERIC);
    		var i:Number = ar.length;
    		var p:Sprite = this.container
    		
    		while(i--) {
        	p.setChildIndex(ar[i].container, i)
        	ar[i].depthOrder = i
        }
				
			}


			// INTERNAL METHODS RELATED TO GRID MANAGEMENT	


			// Reset cell. This is called if the engine's quality options change to a better quality
			// as all cell info will have to be recalculated
			/** @private */
			public function resetGrid():void {

				for(var i:int=0;i<this.gridWidth;i++) {  

					for(var j:int=0;j<=this.gridDepth;j++) {  

		      	 for(var k:int=0;k<=this.gridHeight;k++) {  
			
			         try {
			         		this.grid[i][j][k].characterShadowCache = new Array
			         		delete this.grid[i][j][k].visibleObjs
			         } catch (e:Error) {
			         	
			         }
			   
			       }
		
			    } 
			  }
				
			}


			// Returns the cell containing the given coordinates
			/** @private */
			public function translateToCell(x:Number,y:Number,z:Number):fCell {
				 return this.getCellAt(Math.floor(x/this.gridSize),Math.floor(y/this.gridSize),Math.floor(z/this.levelSize))
			}
			
			// Returns the cell at specific grid coordinates. If cell does not exist, it is created.
			/** @private */
			public function getCellAt(i:Number,j:Number,k:Number) {
				
				if(i<0 || j<0 || k<0) return null
				if(i>=this.gridWidth || j>=this.gridDepth || k>=this.gridHeight) return null
				
				// Create new if necessary
				if(!this.grid[i] || !this.grid[i][j]) return null
				if(!this.grid[i][j][k]) {
					
					var cell:fCell = new fCell()

			    // Z-Index
			    cell.zIndex = this.computeZIndex(i,j,k)
			    var s:Array = this.sortAreas[i]
			    var l:Number = s.length
			    
			    var found:Boolean = false
			    for(var n:Number=0;!found && n<l;n++) {
			    	if(s[n].isPointInside(i,j,k)) {
			    		found = true
			    		cell.zIndex+=s[n].zValue
			    	}
			  	}
			         
			    // Internal
			    cell.i = i
			    cell.j = j
			    cell.k = k
			    cell.x = (this.gridSize/2)+(this.gridSize*i)
			    cell.y = (this.gridSize/2)+(this.gridSize*j)
			    cell.z = (this.levelSize/2)+(this.levelSize*k)
					this.grid[i][j][k] = cell

				}
				
				// Return cell
				return this.grid[i][j][k]
				
			}


			/** @private */
			public static function translateCoords(x:Number,y:Number,z:Number):Point {
			
				 var xx:Number = x*fEngine.DEFORMATION
				 var yy:Number = y*fEngine.DEFORMATION
				 var zz:Number = z*fEngine.DEFORMATION
				 var xCart:Number = (xx+yy)*Math.cos(0.46365)
				 var yCart:Number = zz+(xx-yy)*Math.sin(0.46365)

				 return new Point(xCart,-yCart)

			}
			
      /** @private */   
      public static function translateCoordsInverse(x:Number,y:Number):Point {   
         
         //rotate the coordinates
         var yCart:Number = (x/Math.cos(0.46365)+(y)/Math.sin(0.46365))/2
         var xCart:Number = (-1*(y)/Math.sin(0.46365)+x/Math.cos(0.46365))/2         
         
         //scale the coordinates
         xCart = xCart/fEngine.DEFORMATION
         yCart = yCart/fEngine.DEFORMATION
         
         return new Point(xCart,yCart)
      }         


			// Get visible elements from given cell, sorted by distance
			/** @private */
			public function calcVisibles(cell:fCell,range:Number=Infinity):void {
			   var r:Array = fVisibilitySolver.calcVisiblesCoords(this,cell.x,cell.y,cell.z,range)
			   cell.visibleObjs = r
			   cell.visibleRange = range
			}
			
			/**
			* @private
			* This method frees all resources allocated by this scene. Always clean unused scene objects:
			* scenes generate lots of internal Arrays and BitmapDatas that will eat your RAM fast if they are not properly deleted
			*/
			public function dispose():void {
				
		  	// Free properties
		  	this.engine = null
				for(var i:Number=0;i<this.depthSortArr.length;i++) delete this.depthSortArr[i]
				this.depthSortArr = null
				for(i=0;i<this.sortAreas.length;i++) delete this.sortAreas[i]
				this.sortAreas = null
				if(this.currentCamera) this.currentCamera.dispose()
				this.currentCamera = null
				this._controller = null
				
				// Stop current initialization, if any
				if(this.initializer) this.initializer.dispose()
				this.resourceManager = null
				
				// Free render engine
				this.renderEngine.dispose()
				if(this._orig_container.parent) this._orig_container.parent.removeChild(this._orig_container)
				this._orig_container = null
				this.container = null

				// Free elements
		  	for(i=0;i<this.floors.length;i++) {
		  		this.floors[i].dispose()
		  		delete this.floors[i]
		  	}
		  	for(i=0;i<this.walls.length;i++) {
		  		this.walls[i].dispose()
		  		delete this.walls[i]
		  	}
		  	for(i=0;i<this.objects.length;i++) {
		  		this.objects[i].dispose()
		  		delete this.objects[i]
		  	}
		  	for(i=0;i<this.characters.length;i++) {
		  		this.characters[i].dispose()
		  		delete this.characters[i]
		  	}
		  	for(i=0;i<this.lights.length;i++) {
		  		this.lights[i].dispose()
		  		delete this.lights[i]
		  	}
		  	for(i=0;i<this.bullets.length;i++) {
		  		this.bullets[i].dispose()
		  		delete this.bullets[i]
		  	}
		  	for(i=0;i<this.bulletPool.length;i++) {
		  		this.bulletPool[i].dispose()
		  		delete this.bulletPool[i]
		  	}
				for(var n in this.all) delete this.all[n]
				
				// Free grid
				for(i=0;i<this.gridWidth;i++) {  
					for(var j:int=0;j<this.gridDepth;j++) {  
		      	 for(var k:int=0;k<this.gridHeight;k++) {  
			         try {
			         		this.grid[i][j][k].dispose()
			         		delete this.grid[i][j][k]
			         } catch (e:Error) {
			         	
			         }
			       }
			    } 
			  }
				this.grid = null
				
			}

		
		}


}

